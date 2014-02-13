require 'spec_helper'

describe LLT::Morphologizer::LookupStatement do
  let(:ls) { LLT::Morphologizer::LookupStatement }
  let(:rosam) { ls.new("ros", :noun, :stem, [1], { ending: "am" }) }

  describe "#stem_type" do
    it "returns the stem type" do
      rosam.stem_type.should == :stem
    end
  end

  describe "#type" do
    it "returns the type" do
      rosam.type.should == :noun
    end
  end

  describe "#to_query" do
    it "builds a query in a hash format, that corresponds with the db handler interface" do
      rosam.to_query.should == { type: :noun, stem_type: :stem, stem: "ros", restrictions: { type: :inflection_class, values: [1] } }
    end

    it "build a query for laudavit" do
      ros = ls.new("laudav", :verb, :pf, ["v"], { ending: "it" })
      ros.to_query.should == { type: :verb, stem_type: :pf, stem: "laudav", restrictions: { type: :pf_composition, values: ["v"] } }
    end
  end
end
