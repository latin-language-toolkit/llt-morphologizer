module LLT
  class Morphologizer
    class StemLookupStatementBuilder

      require 'llt/morphologizer/stem_lookup_statement_builder/contracted_forms'
      require 'llt/morphologizer/stem_lookup_statement_builder/declinable'
      require 'llt/morphologizer/stem_lookup_statement_builder/conjugable'
      require 'llt/morphologizer/lookup_statement'

      include Declinable
      include Conjugable

      def initialize(word, log)
        @word = word.clone # clone! because this will get sliced and reset continuously in this class
        @log  = log

        @components = Hash.new { |h, k| h[k] = "" }
        @lookup     = {}
      end

      def stem
        # a semantic help
        @word
      end

      GETTER_METHODS = { components: %w{ thematic extension comparison_sign ending contraction },
                         lookup:     %w{ table column itype } }

      GETTER_METHODS.each do |inst_var, methods|
        methods.each do |method|
          class_eval <<-STR
            def #{method}
              @#{inst_var}[:#{method}]
            end
          STR
        end
      end

      def statements
        @statements = []
        create_declinables
        create_conjugables

        @statements
      end

      def setup(operator)
        @components.clear
        @lookup     = { table: "", column: "", itype: [] }
        @operator   = operator
      end

      def reset(*args)
        args.flatten.each do |comp|
          @word << @components.delete(comp).to_s
        end
      end

      def all
        @all_memo ||= %i{ thematic extension comparison_sign ending }
      end

      def has(arr)
        type, components = arr
        if result = scan(components, type)
          slice_and_stash(type, result)
        end
      end

      def scan(components, type)
        # look what that's doing, it's a bit weird
        components.flat_map {|x| @word.scan(x) }.first   # that's brutally ugly
      end

      def slice_and_stash(type, result)
        @components[type].prepend(@word.slice!(/#{result}$/))
      end

      def look_for the_table = :same, the_column = :same
        unless the_table == :same
          @lookup[:table]  = the_table
          @lookup[:column] = the_column
        end

        send("valid_itypes_for_#{@operator}")
        add_statement!
        add_additional_persona_place_or_ethnic_statement!
        itype.clear
      end

      def add_statement!
        if itype.empty?
          @log.warning("#{stem} with #{@components[:ending]} has no searchable infl classes.")
        else
          # 2013-09-27 19:23 @components.clone substituted with rejection of empty strings - observe if this leads to trouble.
          st = LookupStatement.new(cloned_stem, table, column, itype.clone, unemptied_components)
          @statements << st
        end
      end

      def unemptied_components
        # leave ending always in - otherwise some words trigger build all forms (cf ita)
        @components.reject { |k, v| v.empty? unless k == :ending }
      end


      def cloned_stem
        s = stem.clone
        s.downcase! unless persona_place_or_ethnic?
        s
      end

      def persona_place_or_ethnic?
        table == :persona || table == :place || table == :ethnic
      end

      def add_additional_persona_place_or_ethnic_statement!
        if stem.match(/^[A-Z].*/)
          case table
          when :noun
            @lookup[:table] = :persona and add_statement!
            @lookup[:table] = :place   and add_statement!
          when :adjective
            @lookup[:table] = :ethnic  and add_statement! if column == :stem
          end
        end
      end
    end
  end
end
