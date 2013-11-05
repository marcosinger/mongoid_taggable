module Mongoid
  module Taggable
    module Localized
      extend ActiveSupport::Concern

      included do
        include Base

        field :localized_tags, type: Hash, default: {}
      end

      module ClassMethods
        def tagged_with(tag)
          self.any_in("localized_tags.#{I18n.locale}" => [tag])
        end

        def tagged_with_all(*tags)
          self.all_in("localized_tags.#{I18n.locale}" => tags.flatten)
        end

        def tagged_with_any(*tags)
          self.any_in("localized_tags.#{I18n.locale}" => tags.flatten)
        end

        def tags
          tags_on_index { |r| r['_id']['tag'] }
        end

        # retrieve a ranked list of tags with weight by locale (i.e. count).
        # this is useful for creating tag clouds
        def tags_with_weight(locale=nil)
          sorted_by_rank(tags_on_index(locale) { |r| [r['_id']['tag'], r['value']] })
        end

        # creating a map by tag and locale
        def map
          <<-map
            function() {
              if (this.localized_tags === undefined || this.localized_tags === null || !this.localized_tags["#{I18n.locale}"]) {
                return;
              }

              for (locale in this.localized_tags) {
                for (index in this.localized_tags[locale]) {
                  var key = {
                    tag: this.localized_tags[locale][index],
                    locale: locale
                  }

                  emit(key, 1);
                }
              }
            }
          map
        end

        private

        def tags_on_index(locale=nil, &block)
          locale ||= I18n.locale
          tags_index_collection.find({'_id.locale' => locale}).to_a.map &block
        end
      end

      module InstanceMethods
        def taggable_field_changed?
          localized_tags_changed?
        end

        def tags
          (self.localized_tags.fetch("#{I18n.locale}", [])).join(self.class.separator)
        end

        def tags=(localized)
          if localized.present?
            localized.each do |locale, tags|
              self.localized_tags = self.localized_tags.merge(tag_list_to_hash(locale, tags))
            end
          else
            self.localized_tags = []
          end
        end

        private

        def tag_list_to_hash(locale, tags)
          {locale => tag_list_to_array(tags)}
        end
      end
    end
  end
end