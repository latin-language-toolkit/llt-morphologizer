module LLT
  class Morphologizer
    class LookupStatement
      attr_reader :components
      alias :options :components

      def initialize(*args)
        @stem, @table, @column, @itypes, @components = args
        safety_clones
      end

      def stem_type
        @column
      end

      def type
        @table
      end

      def to_query
        {
          type: @table,
          stem: @stem,
          stem_type: @column,
          restrictions: build_restrictions
        }
      end

      def to_s
        "Looking up #{@stem.light_green} as #{@table}, #{@column} #{"with #{components_to_s}" if @components.any? } (classes: #{@itypes * ", "})"
      end

      private

      # The methods that help in the creation of such instances are
      # prepending and appending strings - especially the thematic.
      # Just to be safe, clones this value.
      def safety_clones
        if thematic = @components[:thematic]
          @components[:thematic] = thematic.clone
        end
      end

      def components_to_s
        @components.map do |k, v|
          val = (v.empty? ? '""' : v)
          "#{k} #{val.to_s.cyan}"
        end.compact * ", "
      end


      def build_restrictions
        kw = if @itypes.all? { |x| x.kind_of? Fixnum }
               :inflection_class
             else
               :pf_composition
             end

        {
          type: kw,
          values: @itypes
        }
      end
    end
  end
end
