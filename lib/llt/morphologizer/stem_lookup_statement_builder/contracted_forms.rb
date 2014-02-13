module LLT::Morphologizer::StemLookupStatementBuilder::ContractedForms

  CONTRACTED_FORMS = {
    "v"  => /(?<=[^v]i)(er[aiu]nt|er[ia][mst]|er[ia]mus|er[ia]tis|ero)$/,
    "vi" => /(?<=[^v][aeio])(stis?|sse[mst]|ssemus|ssetis|ssent|sse)$/,
    "ve" => /(?<=[^v][aeo])(r[aiu]nt|r[ia][mst]|r[ia]mus|r[ia]tis|ro)$/
  }


  def search_for_contracted_form(method)
    CONTRACTED_FORMS.each do |missing_piece, regexp|
      index = @word =~ regexp
      unless index.nil?
        @word.insert(index, missing_piece)
        @components[:contraction] = Contraction.new(index, missing_piece)

        send(method)
        @word.slice!(index, 2)
      end
    end
  end

  class Contraction
    def initialize(position, contraction)
      @position    = position
      @contraction = contraction
    end

    def empty?
      # duck type, fulfilling the contract of the other component strings
      false
    end

    def to_s
      "#{@contraction} contracted at #{@position}"
    end
  end
end
