require 'spec_helper'

describe LLT::Morphologizer::StemLookupStatementBuilder do

  def slsb(word)
    LLT::Morphologizer::StemLookupStatementBuilder.new(word, LLT::Logger.new)
  end

  describe "#statements" do
    it "creates no separate nominative lookup request for a, um, es and us endings - different from old implementation" do
      slsb("rosa").statements.map(&:to_query).count { |h| h[:stem_type] == :nom }.should == 0
      slsb("templum").statements.map(&:to_query).count { |h| h[:stem_type] == :nom }.should == 0
      slsb("res").statements.map(&:to_query).count { |h| h[:stem_type] == :nom && h[:restrictions][:values].include?(5) }.should == 0
      slsb("hortus").statements.map(&:to_query).count { |h| h[:stem_type] == :nom && h[:restrictions][:values].include?(2)}.should == 0
    end

    it "searches in persona, place and ethnic table when a word is capitalized" do
      plato_queries = slsb("Plato").statements.map(&:to_query)
      plato_queries.select { |h| h[:type] == :persona }.should_not be_empty
      plato_queries.select { |h| h[:type] == :place }.should_not be_empty
      plato_queries.select { |h| h[:type] == :ethnic }.should_not be_empty
    end

    it "only stems are searched in the ethnic table" do
      queries = slsb("Haeduus").statements.map(&:to_query)
      queries.none? { |h| h[:type] == :ethnic && h[:stem_type] == :nom }.should be_true
      queries.any?  { |h| h[:type] == :ethnic && h[:stem_type] == :stem }.should be_true
    end

    it "searches for capitalized words in downcase, expect for names, places and ethnics" do
      plato_queries = slsb("Plato").statements.map(&:to_query)
      plato_queries.any? { |h| h[:type] == :noun && h[:stem] =~ /^[a-z].*/ }.should be_true
      plato_queries.none? { |h| h[:type] == :noun && h[:stem] =~ /^[A-Z].*/ }.should be_true

      plato_queries.any? { |h| h[:type] == :persona && h[:stem] =~ /^[A-Z].*/ }.should be_true
      plato_queries.none? { |h| h[:type] == :persona && h[:stem] =~ /^[a-z].*/ }.should be_true
    end
  end
end
