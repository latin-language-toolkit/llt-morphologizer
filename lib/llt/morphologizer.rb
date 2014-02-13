require 'llt/constants'
require 'llt/core'
require 'llt/core_extensions/match_data'
require 'llt/db_handler/prometheus'
require 'llt/form_builder'
require 'llt/helpers/constantize'
require 'llt/helpers/normalizer'
require 'llt/helpers/pluralize'
require 'llt/helpers/primitive_cache'
require 'llt/logger'
require "llt/morphologizer/version"

module LLT
  # Analyzes a token string morphologically.
  #
  # Looks up stems in a given db-dictionary and builds LLT::Form objects with the
  # help of the LLT::FormBuilder.
  class Morphologizer
    require 'llt/morphologizer/stem_lookup_statement_builder'

    include Core::Serviceable
    include Helpers::Constantize
    include Helpers::Normalizer
    include Helpers::Pluralize
    include Helpers::PrimitiveCache

    uses_db     { DbHandler::Prometheus.new }
    uses_logger { Logger.new("Morphologizer", 2, default: :morph) }

    # @option options [true] :cache enables caching
    # @option options [DbHandler] :db db-handling object used to obtain stem information
    # @option options [Logger] :logger object used for logging
    def initialize(options = {})
      super
      enable_cache if options[:cache]
    end

    # Takes a string and analyzes it morphologically
    #
    # @param [String] word token to be analyzed
    # @param add_to [#<<] Keyword Argument: can optionally defer the returned
    #   forms to an object
    #
    # @return [Array<LLT::Form>] all valid Latin forms of the given string
    def morphologize(word, add_to: nil)
      forms = cached(word) { compute(word) }
      add_to << forms if add_to.respond_to?(:<<)
      forms
    end

    private

    def setup(word)
      @word  = word
      @forms = []
      @uniq = false
      @statements = nil
    end

    def compute(word)
      # the order is important, illustrated with the word cum.
      # the preposition knows that it can have another form (the subjunction),
      # while the subjunction says it's uniq.

      setup(word)

      return @forms if numerals
      return @forms if prepositions                 &&  unique_present?
      return @forms if look_up(:conjunctions)       &&  unique_present?
      return @forms if look_up(:subjunctions)       &&  unique_present?
      return @forms if clook_up(:personal_pronouns) &&  unique_pers_pron?
      return @forms if other_pronouns               &&  unique_pronoun?
      return @forms if irregular_verbs              &&  unique_present?
      return @forms if clook_up(:cardinals)         &&  unique_cardinal?

      direct_lookup
      indirect_lookup

      @logger.error("Missing Word: #{@word}".red) if @forms.empty?
      @forms
    end


######### Numerals #########

    def numerals
      if Helpers::RomanNumerals.roman?(@word)
        add_form(Form::Cardinal.new(roman: @word))
      end
    end


######### Personal Pronouns && Cardinals #########

    # Complex Lookup
    def clook_up(type)
      if forms = LLT::Constants.const_get(type.upcase)[@word.downcase]
        new_forms = forms.map do |form|
          sg_type = type.to_s.chop # cardinals to cardinal
          args = send("#{sg_type}_args", form)
          constant_by_type(sg_type, namespace: LLT::Form).new(args)
        end
        add_forms(new_forms)
      end
    end

    def personal_pronoun_args(pp)
      # pp is an array of iclass, casus, numerus
      ic, c, n = pp
      stem, suffix = pers_pron_suffix_detection
      { stem: stem, suffix: suffix, inflection_class: ic, casus: c, numerus: n }
    end

    HOMOPHONIC_PRONOUNS = Set.new(%w{ mei tui sui nostri nostrum vestri vestrum sese })
    def unique_pers_pron?
      ! HOMOPHONIC_PRONOUNS.include?(@word)
    end

    def pers_pron_suffix_detection
      stem = @word.clone
      stem.chomp!($1) if stem.match(/.*(cum|met|te)$/)
      [stem, ($1 || "")]
    end

    def cardinal_args(cardinal)
      # cardinal is an array
      dec, c, n, s = cardinal
      { decimal: dec, casus: c, numerus: n, sexus: s }
    end

    def unique_cardinal?
      true # not sure if there is more needed.
    end



######### Other Pronouns #########

    def other_pronouns
      if m = pronouns_regexp.match(downcased)
        pronoun_type = extract_pronoun_type(m)

        stem = { type: :pronoun, inflection_class: pronoun_type }
        new_forms = FormBuilder.build(stem.merge(options: opts_with_val(m.to_hash)))

        add_forms(new_forms)
      end
    end

    # quis and quid and all derivates (like aliquid) take a different
    # path and use the substantivic endings
    def extract_pronoun_type(m)
      subst = (m[:ending] =~ /i[ds]$/ && m[:stem] == "qu") ? "_s" : ""
      key = if m[:particle] == m[:stem] + m[:ending]
              "quisquis"
            else
              # take only 2 chars of prefixed particle to match al(i)
              # and all forms of un(us|ius...) - to_s for nils
              "#{m[:prefixed_particle].to_s[0..1]}#{m[:stem]}#{m[:particle]}#{subst}"
            end
      PRONOUN_MAP[key.downcase]
    end

    PRONOUN_MAP = {
       #stem + particle => :type
                    "hc" => :hic,                "alcu" => :aliqui,
                    "h"  => :hic,                "alqu" => :aliqui,
                    "hu" => :hic,                "alqu_s" => :aliquis,
                    "huc" => :hic,               "culibet" => :quilibet,#subst?
                    "cu" => :qui,                "qulibet" => :quilibet,
                    "qu" => :qui,                "cuvis" => :quivis,
                    "qudam" => :quidam,          "quvis" => :quivis,
                    "cudam" => :quidam,          "qu_s" => :quis,
                    "qunam" => :quinam,          "uterque" => :uterque,
                    "cunam" => :quinam,          "utrque" => :uterque,
                    "i" => :is,                  "uter" => :uter,
                    "e" => :is,                  "utr" => :uter,
                    "ips" => :ipse,              "quque" => :quisque,
                    "ill" => :ille,              "cuque" => :quisque,
                    "ist" => :iste,              "quque_s" => :quisque_s,
                    "idem" => :idem,             "ququam" => :quisquam,
                    "edem" => :idem,             "ququam_s" => :quisquam,
                    "qucumque" => :quicumque,    "cuquam" => :quisquam,
                    "cucumque" => :quicumque,    "quisquis" => :quisquis,
                    "alcu" => :aliqui,           "ququid" => :quisquis,
                    "alqu" => :aliqui,           "unquque_s" => :unusquisque_s,
                    "alqu_s" => :aliquis,        "uncuque" => :unusquisque,
                    "qupiam_s" => :quispiam,     "unquque" => :unusquisque,
                    "qupiam" => :quispiam,       "cupiam" => :quispiam,
    }

    UNIQUE_PRONOUNS = Set.new(%w{ hic is eam eas eo i quam quod quo qua })
    def unique_pronoun?
      ! UNIQUE_PRONOUNS.include?(@word)
    end

    def pronouns_regexp
      LLT::Constants::RegExps::PRONOUNS
    end


######### Irregular Verbs #########

    def irregular_verbs
      irregular_verbs_regexps.each do |verb, stems|
        break if @uniq
        stems.each do |stem_type, regexps|
          regexps.each do |regexp|
            if m = regexp.match(@word)
              @logger.log("Matched irregular verb #{@word.yellow} with #{verb.to_s.yellow}")
              stem_pack = irregular_stems(verb)
              next unless stem_pack # temporary nexting, delete when all ISPs are written down


              new_forms = create_forms(stem_type, stem_pack, m.to_hash)
              add_forms(new_forms)

              # We cannot immediately return as quite often another match
              # will definitely made with the same lemma. Therefore only
              # break at the top - that a match of esse cannot go to ire
              # or anything else.
              @uniq = true unless HOMOGRAPHIC_IRREGS[verb].match(@word)
            end
          end
        end
      end
    end

    HOMOGRAPHIC_IRREGS = {
      ferre: /fero/,
      ire:   /subito/,
    }
    HOMOGRAPHIC_IRREGS.default = (/in_doubt_better_don't_match/)

    def irregular_stems(key)
      LLT::StemBuilder::IRREGULAR_STEMS[key]
    end

    def irregular_verbs_regexps
      LLT::Constants::RegExps::IRREGULAR_VERBS
    end


######### Subjunctions & Conjunctions#########

    def look_up(arg)
      # A bit messy, the constants are saved in a format of
      #  key = string
      #   value = homophonous_forms?
      # That's why we need to access the hash twice, as const[@word]
      # could return false and thus fail # the conditional test
      # with an inline assigment 'if (something = const[@word])'

      const = Constants.const_get(arg.upcase)
      w = downcased
      if const.has_key?(w)
        @uniq = true unless const[w]
        add_form(Form.const_get(arg.to_s.chop.capitalize).new(string: @word))
      end
    end


######### Prepositions #########

    def prepositions
      if prep = Constants::PREPOSITIONS[downcased]
        # preps are { word => 4 6 not_uniq }
        @uniq = true unless prep.last
        takes_4th, takes_6th = prep[0..1]
        args = { string: @word, takes_4th: takes_4th, takes_6th: takes_6th }
        add_form(Form::Preposition.new(args))
      end
    end

######### Direct Lookup like Adverbs #########

    def direct_lookup
      create_adverbs
    end

    def create_adverbs
      entries = @db.direct_lookup(:adverb, downcased)
      entries.each do |entry|
        add_form(Form::Adverb.new(string: entry.word))
      end
    end


######### Creation through DB #########

    def indirect_lookup
      statements
      look_up_and_build_forms
    end

    def statements
      @statements ||= StemLookupStatementBuilder.new(@word, @logger).statements
    end

    def look_up_and_build_forms
      @statements.each do |statement|
        @logger.log(statement.to_s)

        stems = @db.look_up_stem(statement.to_query)

        if stems.any?
          @logger.bare("#{stems.size} #{pluralize(stems.size, 'entry')} found: #{stems.map(&:to_s) * ", "}", 8)

          stems.each do |stem_pack|
            type = t.send(statement.stem_type, :full)
            new_forms = create_forms(type, stem_pack, statement.options)

            add_forms(new_forms)
          end
        else
          @logger.bare("0 entries found".yellow, 8)
        end
      end
    end


######### Helpers #########

    def create_forms(selector, stem_pack, options)
      forms = FormBuilder.build(stem_pack.to_hash(selector, opts_with_val(options)))
      forms.each { |form| form.stems = stem_pack }
    end

    def log_form_creation(new_forms)
      m = if new_forms.empty?
            "No forms created".red
          else
            "#{new_forms.size} #{pluralize(new_forms.size, "form")} created: #{new_forms.map(&:to_s) * ", "}".green
          end
      @logger.bare(m, 8)
    end

    def opts_with_val(opts)
      adapted_components(opts).merge(validate: true)
    end

    def add_form(form)
      log_form_creation([form])
      @forms << form
    end

    def add_forms(forms)
      log_form_creation(forms)
      @forms += forms
    end

    def unique_present?
      @uniq
    end

    def downcased
      @word.downcase
    end

    def adapted_components(comps)
      # TODO 30.09.13 12:13 by LFDM
      # Look fors nils in comps, probably due to regexps
      #
      # This method looks useless at first sight, as this is already done in LookupStatement to some extent,
      # it's main use seems for some nil cases that need to be found, afterwards we can delete this.
      comps.reject do |k, v|
        if v
          v.empty? unless k == :ending
        else
          true
        end
      end
    end

    private_constant :HOMOPHONIC_PRONOUNS, :PRONOUN_MAP, :UNIQUE_PRONOUNS,
      :HOMOPHONIC_PRONOUNS, :HOMOGRAPHIC_IRREGS
  end
end
