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
    extend ActiveSupport::Concern

    included do
      include Base

      # create fields for tags and index it
      field :tags_array, :type => Array, :default => []
      index({ tags_array: 1 })
    end

    module ClassMethods

      # returns an array of distinct ordered list of tags defined in all documents
      def tagged_with(tag)
        self.any_in(:tags_array => [tag])
      end

      def tagged_with_all(*tags)
        self.all_in(:tags_array => tags.flatten)
      end

      def tagged_with_any(*tags)
        self.any_in(:tags_array => tags.flatten)
      end

      def tags
        tags_on_index { |r| r['_id'] }
      end

      # retrieve the list of tags with weight (i.e. count).
      # this is useful for creating tag clouds
      def tags_with_weight
        sorted_by_rank(tags_on_index { |r| [r['_id'], r['value']] })
      end

      def map
        <<-map
          function() {
            if (!this.tags_array) {
              return;
            }

            for (index in this.tags_array) {
              emit(this.tags_array[index], 1);
            }
          }
        map
      end

      private

      def tags_on_index(&block)
        tags_index_collection.find.to_a.map &block
      end
    end

    module InstanceMethods
      def tags
        (tags_array || []).join(self.class.separator)
      end

      def tags=(tags)
        self.tags_array = tag_list_to_array(tags)
      end

      private

      def taggable_field_changed?
        tags_array_changed?
      end
    end
  end
end