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

require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class MyModel
  include Mongoid::Document
  include Mongoid::Taggable

  field :name
end

describe Mongoid::Taggable do
  describe "default tags array value" do
    subject {MyModel.new}

    its(:tags_array) {should be_empty}
  end

  context "finding" do
    let(:model) {MyModel.create!(:tags => "interesting,stuff,good,bad")}

    context ".tagged_with" do
      subject {MyModel.tagged_with('interesting')}
      it {should be_include(model)}
    end

    context ".tagged_with_all" do
      context 'using array' do
        subject {MyModel.tagged_with_all(['interesting', 'good'])}
        it {should be_include(model)}
      end

      context "using strings" do
        subject {MyModel.tagged_with_all('interesting', 'good')}
        it {should be_include(model)}
      end

      context "by tagged_with_all when tag not included" do
        subject {MyModel.tagged_with_all('interesting', 'good', 'mcdonalds')}
        it {should_not be_include(model)}
      end
    end

    context ".tagged_with_any" do
      context 'using an array' do
        subject {MyModel.tagged_with_any(['interesting', 'mcdonalds'])}
        it {should be_include(model)}
      end

      context "using strings" do
        subject {MyModel.tagged_with_any('interesting', 'mcdonalds')}
        it {should be_include(model)}
      end

      context "when tag not included" do
        subject {MyModel.tagged_with_any('hardees', 'wendys', 'mcdonalds')}
        it {should_not be_include(model)}
      end
    end
  end

  context "saving tags" do
    context 'from tags to tags_array' do
      subject do
        MyModel.new.tap {|model| model.tags = tags}
      end

      context "set tags array from string" do
        let(:tags) {"some,new,tag"}
        its(:tags_array) {should == ["some", "new", "tag"]}
      end

      context "strip tags" do
        let(:tags) {"now ,  with, some spaces  , in places "}
        its(:tags_array) {should == ["now", "with", "some spaces", "in places"]}
      end

      context "clear empty tags" do
        let(:tags) {"repetitive,, commas, shouldn't cause,,, empty tags"}
        its(:tags_array) {should == ["repetitive", "commas", "shouldn't cause", "empty tags"]}
      end
    end

    context 'from tag_arrays to tags' do
      subject do
        MyModel.new.tap {|model| model.tags_array = array}
      end

      context "tags string from array" do
        let(:array) {["some", "new", "tags"]}
        its(:tags) {should == "some,new,tags"}
      end
    end
  end

  context 'clear tags' do
    subject {MyModel.create!(tags: "hey,there")}

    context "when tags set to nil" do
      before {subject.tags = nil}
      its(:tags_array) {should be_empty}
    end

    context "when tags set to empty string" do
      before {subject.tags = ""}
      its(:tags_array) {should be_empty}
    end
  end

  context ".tags_separator" do
    class ModelSeparator
      include Mongoid::Document
      include Mongoid::Taggable

      taggable separator: ';'
    end

    context "split" do
      subject {ModelSeparator.new.tap {|model| model.tags = "some;other;separator"}}
      its(:tags_array) {should == %w[some other separator]}
    end

    context "join" do
      subject {ModelSeparator.new.tap {|model| model.tags_array = ["some", "other", "sep"]}}
      its(:tags) {should == "some;other;sep"}
    end
  end

  context "indexing tags" do
    it "should generate the index collection name based on model" do
      MyModel.tags_index_collection_name.should == "my_models_tags_index"
    end

    context "retrieving index" do
      before :each do
        MyModel.create!(:tags => "food,ant,bee")
        MyModel.create!(:tags => "juice,food,bee,zip")
        MyModel.create!(:tags => "honey,strip,food")
      end

      it "should retrieve the list of all saved tags distinct and ordered" do
        MyModel.tags.should == %w[ant bee food honey juice strip zip]
      end

      it "should retrieve a list of tags with weight" do
        MyModel.tags_with_weight.should == [
          ['ant', 1],
          ['bee', 2],
          ['food', 3],
          ['honey', 1],
          ['juice', 1],
          ['strip', 1],
          ['zip', 1]
        ]
      end
    end

    context "avoiding index generation" do
      class ModelWithoutIndex
        include Mongoid::Document
        include Mongoid::Taggable

        taggable enable_index: false
      end

      before {ModelWithoutIndex.create!(:tags => "sample,tags")}

      it "should not generate index" do
        ModelWithoutIndex.tags.should == []
      end
    end

    it 'should launch the map/reduce if index activate and tag_arrays change' do
      m = MyModel.create!(:tags_array => "food,ant,bee")
      m.tags = 'juice,food'
      MyModel.should_receive(:save_tags_index!) {double("scope").as_null_object}
      m.save
    end

    it 'should not launch the map/reduce if index activate and tag_arrays not change' do
      m = MyModel.create!(:tags => "food,ant,bee")
      MyModel.should_not_receive(:save_tags_index!)
      m.save
      m.name = 'hello'
      m.save
    end
  end
end
