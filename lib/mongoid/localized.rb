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

        def map
          <<-map
            function() {
              if (this.localized_tags === undefined || this.localized_tags === null || !this.localized_tags["#{I18n.locale}"]) {
                return;
              }

              for (index in this.localized_tags["#{I18n.locale}"]) {
                emit(this.localized_tags["#{I18n.locale}"][index], 1);
              }
            }
          map
        end
      end

      module InstanceMethods
        def taggable_field_changed?
          localized_tags_changed?
        end

        def tags
          self.localized_tags.fetch("#{I18n.locale}", [])
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