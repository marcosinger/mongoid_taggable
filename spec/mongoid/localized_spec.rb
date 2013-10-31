require 'spec_helper'

class LocalizedModel
  include Mongoid::Document
  include Mongoid::Taggable::Localized
end

describe Mongoid::Taggable::Localized do
  describe "default tags hash value" do
    subject {LocalizedModel.new}

    its(:localized_tags) {should be_empty}
  end

  context "saving tags" do
    context 'from tags to localized_tags' do
      subject do
        LocalizedModel.new.tap {|model| model.tags = tags}
      end

      context "set tags array from string" do
        let(:tags) {{"pt-BR" => "some,new,tag"}}
        its(:localized_tags) {should == {"pt-BR" => ["some", "new", "tag"]}}
      end

      context "strip tags" do
        let(:tags) {{"pt-BR" => "now ,  with, some spaces  , in places "}}
        its(:localized_tags) {should == {"pt-BR" => ["now", "with", "some spaces", "in places"]}}
      end

      context "clear empty tags" do
        let(:tags) {{"pt-BR" => "repetitive,, commas, shouldn't cause,,, empty tags"}}
        its(:localized_tags) {should == {"pt-BR" => ["repetitive", "commas", "shouldn't cause", "empty tags"]}}
      end
    end
  end

  context 'show tags' do
    subject do
      localized_tags = {
        'pt-BR' => "portuguese,tags",
        'en' => "some,new,tags"
      }
      LocalizedModel.new.tap {|model| model.tags = localized_tags}
    end

    context 'en locale' do
      its(:tags) {should == ["some", "new", "tags"]}
    end

    context 'pt-BR locale' do
      before {I18n.locale = 'pt-BR'}
      its(:tags) {should == ["portuguese", "tags"]}
    end

    context 'locale without a tags list' do
      before {I18n.locale = 'fr'}
      its(:tags) {should be_empty}
    end
  end

  context 'clear tags' do
    subject {LocalizedModel.create!(tags: {"pt-BR" => "hey,there"})}

    context "when tags set to nil" do
      before {subject.tags = nil}
      its(:localized_tags) {should be_empty}
    end

    context "when tags set to empty string" do
      before {subject.tags = ""}
      its(:localized_tags) {should be_empty}
    end
  end

  context "finding" do
    let(:model) do
      localized_tags = {
        'pt-BR' => "samba,spfc,rio",
        'en' => "interesting,stuff,good,bad"
      }

      LocalizedModel.create!(tags: localized_tags)
    end

    context ".tagged_with" do
      context 'en locale' do
        subject {LocalizedModel.tagged_with('interesting')}
        it {should be_include(model)}
      end

      context 'pt-BR locale' do
        before {I18n.locale = 'pt-BR'}

        subject {LocalizedModel.tagged_with('spfc')}
        it {should be_include(model)}
      end
    end

    context ".tagged_with_all" do
      context 'using array' do
        context 'en locale' do
          subject {LocalizedModel.tagged_with_all(['interesting', 'good'])}
          it {should be_include(model)}
        end

        context 'pt-BR locale' do
          before {I18n.locale = 'pt-BR'}

          subject {LocalizedModel.tagged_with_all(['spfc', 'rio'])}
          it {should be_include(model)}
        end
      end

      context "using strings" do
        context 'en locale' do
          subject {LocalizedModel.tagged_with_all('interesting', 'good')}
          it {should be_include(model)}
        end

        context 'pt-BR locale' do
          before {I18n.locale = 'pt-BR'}

          subject {LocalizedModel.tagged_with_all('spfc', 'rio')}
          it {should be_include(model)}
        end
      end

      context "when tag not included" do
        context 'en locale' do
          subject {LocalizedModel.tagged_with_all('interesting', 'good', 'wrong')}
          it {should_not be_include(model)}
        end

        context 'pt-BR locale' do
          before {I18n.locale = 'pt-BR'}

          subject {LocalizedModel.tagged_with_all('spfc', 'rio', 'wrong')}
          it {should_not be_include(model)}
        end
      end
    end

    context ".tagged_with_any" do
      context 'using an array' do
        context 'en locale' do
          subject {LocalizedModel.tagged_with_any(['interesting', 'wrong'])}
          it {should be_include(model)}
        end

        context 'pt-BR locale' do
          before {I18n.locale = 'pt-BR'}

          subject {LocalizedModel.tagged_with_any(['spfc', 'wrong'])}
          it {should be_include(model)}
        end
      end

      context "using strings" do
        context 'en locale' do
          subject {LocalizedModel.tagged_with_any('interesting', 'wrong')}
          it {should be_include(model)}
        end

        context 'pt-BR locale' do
          before {I18n.locale = 'pt-BR'}

          subject {LocalizedModel.tagged_with_any('spfc', 'wrong')}
          it {should be_include(model)}
        end
      end

      context "when tag not included" do
        context 'en locale' do
          subject {LocalizedModel.tagged_with_any('hardees', 'wendys', 'wrong')}
          it {should_not be_include(model)}
        end

        context 'pt-BR locale' do
          before {I18n.locale = 'pt-BR'}

          subject {LocalizedModel.tagged_with_any('hardees', 'wendys', 'wrong')}
          it {should_not be_include(model)}
        end
      end
    end
  end

  context "indexing tags" do
    context 'legacy' do
      context 'persisted model without localized_tags' do
        let(:localized) {LocalizedModel.new(tags: {"en" => "food,ant,bee,hangar"})}
        before {LocalizedModel.create(localized_tags: nil)}

        it {expect {localized.save}.to_not raise_error}

        context 'tags list' do
          before {localized.save}
          it {LocalizedModel.tags.should == %w[ant bee food hangar]}
        end
      end
    end

    context "retrieving index" do
      context 'en locale' do
        before do
          LocalizedModel.create!(:tags => {"en" => "food,ant,bee,hangar"})
          LocalizedModel.create!(:tags => {"en" => "juice,food,bee,zip"})
          LocalizedModel.create!(:tags => {"en" => "honey,strip,food"})
        end

        it "should retrieve the list of all saved tags distinct and ordered" do
          LocalizedModel.tags.should == %w[ant bee food hangar honey juice strip zip]
        end

        it "should retrieve a list of tags with weight" do
          LocalizedModel.tags_with_weight.should == [
            ['ant', 1],
            ['bee', 2],
            ['food', 3],
            ['hangar', 1],
            ['honey', 1],
            ['juice', 1],
            ['strip', 1],
            ['zip', 1]
          ]
        end
      end

      context 'pt-BR locale' do
        before {I18n.locale = 'pt-BR'}

        before do
          LocalizedModel.create!(:tags => {"pt-BR" => "samba,rio,spfc,soccer"})
          LocalizedModel.create!(:tags => {"pt-BR" => "carnaval,spfc"})
          LocalizedModel.create!(:tags => {"pt-BR" => "spfc,rio,paulista"})
        end

        it "should retrieve the list of all saved tags distinct and ordered" do
          LocalizedModel.tags.should == %w[carnaval paulista rio samba soccer spfc]
        end

        it "should retrieve a list of tags with weight" do
          LocalizedModel.tags_with_weight.should == [
            ['carnaval', 1],
            ['paulista', 1],
            ['rio', 2],
            ['samba', 1],
            ['soccer', 1],
            ['spfc', 3]
          ]
        end
      end
    end
  end
end