# Copyright (c) 2010 Wilker Lúcio <wilkerlucio@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongoid
  module Taggable
    module Base
      extend ActiveSupport::Concern

      included do
        cattr_accessor :enable_index, :separator, :tags_index_collection_name

        # add callback to save tags index
        after_save do |document|
          document.class.save_tags_index! if taggable_field_changed?
        end

        # call the taggable method for enable the default options
        taggable
      end

      module ClassMethods
        # enable indexing as default
        # separator is comma as default
        # collection_name is the class name as default
        def taggable(options={})
          self.enable_index               = options.fetch(:enable_index, true)
          self.separator                  = options.fetch(:separator, ',')
          self.tags_index_collection_name = options.fetch(:tags_index_collection_name, "#{collection_name}_tags_index")
        end

        def save_tags_index!
          return if !self.enable_index

          # Since map_reduce is normally lazy-executed, call 'raw'
          # Should not be influenced by scoping. Let consumers worry about
          # removing tags they wish not to appear in index.
          self.unscoped.map_reduce(map, reduce).out(replace: self.tags_index_collection_name).raw
        end

        def reduce
          <<-reduce
            function(_, current) {
              var count = 0;

              for (index in current) {
                count += current[index]
              }

              return count;
            }
          reduce
        end

        private

        def tags_index_collection
          @tags_index_collection ||= Moped::Collection.new(self.collection.database, self.tags_index_collection_name)
        end
      end

      private

      def tag_list_to_array(tags)
        return [] if !tags.present?
        tags.split(self.class.separator).map(&:strip).reject(&:blank?)
      end
    end
  end
end