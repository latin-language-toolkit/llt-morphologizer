module LLT::Morphologizer::StemLookupStatementBuilder::Conjugable
  include LLT::Morphologizer::StemLookupStatementBuilder::ContractedForms

  class << self
    def sg_1_active
      [/(?<!tud|[^nu][st]i|ment|[bc]ul|[ao]ri|\Apr)o$/, /(?<![^s]u)m$/]
    end

    def sg_2_active
      /(?<=[aer]|[^tr]i|[^aeirsl]ti|[^ai]ri|[^t][sft]eri|quiri|quaeri|\A[a-z]peri|[^a-z]geri|[^a-z]pari|[^a-z]meti)s$/
    end

    def sg_3_active
      /(?<=\S[ae]|[is])t$/
    end

    def pl_1_active
       /(?<!illi|erri|ssi|[^aeiu])mus$/
    end

    def pl_2_active
      /(?<=[aei])tis$/
    end

    def pl_3_active
      /(?<=[aeiu])nt$/
    end

    def sg_1_passive
      [/(?<!u)or$/, /(?<!u)r$/]
    end

    def sg_2_passive
      /(?<=[^p]a|[^afgtpsx]e|[^(qu)]i|[cr][uia]pe|[a-z][tg]e)ris$/
    end

    def sg_3_passive
      /(?<=[aei])tur$/
    end

    def pl_1_passive
      /mur$/
    end

    def pl_2_passive
      /(?<=[aei])mini$/
    end

    def pl_3_passive
      /(?<=[aeiu])ntur$/
    end
  end

  PRIMARY_ENDING    = [:ending, [ *sg_1_active, sg_2_active, sg_3_active, pl_1_active, pl_2_active, pl_3_active,
                                  *sg_1_passive, sg_3_passive, pl_1_passive, pl_2_passive, pl_3_passive]]
  PRIMARY_ENDING_SG_2_PASSIVE = [:ending, [sg_2_passive]]

  SECONDARY_ENDING  = [:ending, [ /isti$/, /(?<=[^rnt])i$/, /it$/, /imus$/, /istis$/, /erunt$/, /ere$/ ]]
  IMPERATIVE_ENDING = [:ending, [ /(?<=[aei])te$/, /tote$/, /(?<=[^ieu]a$|e$|[^min][^uv]i$)/, /(?<=[^n])to$/, /nto$/,
                                 /(?<=[^n])tor$/, /ntor$/]]
  DEP_IMP_ENDING    = [:ending, [ /(?<=[aei])re$/ ]]

  PERFECT_EXTENSIONS           = [:extension, [/er$|er[ai]$|isse$/]]
  IMPERFECT_BA                 = [:extension, [/ba$/]]
  FUTURE_B                     = [:extension, [/[b]$/]]
  FUTURE_OR_SUBJUNCTIVE_A_OR_E = [:extension, [/[ae]$/]]
  SUBJUNCTIVE_IMPERFECT        = [:extension, [/re$/]]

  THEMATIC_VOWEL                      = [:thematic, [/[eiu]$/]]
  THEMATIC_I_OF_M                     = [:thematic, [/[i]$/]]
  THEMATIC_E_OF_SUBJUNCTIVE_IMPERFECT = [:thematic, [/e$/]]

  # (?<=[aei])re not needed here as inf pr, - the dep_imp_ending finds it
  # anyway, the FormBuilder cares for the rest.
  INFINITIVE_PR     = [:ending, [/(?<=[aei])ri$|(?<=[^aeior])i$|r?ier$/]]
  INFINITIVE_PF     = [:ending, [/isse$/]]

  def create_conjugables
    setup(:conjugable)
    search_for_contracted_form(:conjugable_search)

    setup(:conjugable)
    conjugable_search
  end


  def conjugable_search
    secondary_ending
    primary_ending(PRIMARY_ENDING)
    primary_ending(PRIMARY_ENDING_SG_2_PASSIVE)
    imperative
    infinitive
  end

  private

  def secondary_ending
    if has SECONDARY_ENDING
      look_for :verb, :pf
      reset all
    end
  end

  def primary_ending(const)
    if has const then look_for :verb, :pr

      if has IMPERFECT_BA       then look_for :verb, :pr
        if has THEMATIC_VOWEL   then look_for :same; end
        if has THEMATIC_I_OF_M  then look_for :same; end
        reset :thematic, :extension
      end

      if has THEMATIC_VOWEL then look_for :same
        if has THEMATIC_I_OF_M then look_for :same; end
        if has FUTURE_B
          look_for :same
          reset :extension, :thematic
        else reset :thematic, :extension
        end
      end

      if has FUTURE_B then look_for :same
        reset :thematic, :extension
      end

      if has FUTURE_OR_SUBJUNCTIVE_A_OR_E then look_for :same
        subjunctive_present_of_A_conjugation
        if has THEMATIC_I_OF_M then look_for :same; end
        reset :thematic, :extension
      end

      if has SUBJUNCTIVE_IMPERFECT then look_for :same
        if  has THEMATIC_E_OF_SUBJUNCTIVE_IMPERFECT then look_for :same; end
      end

      first_person_present_of_A_conjugation

      reset :thematic, :extension

      if has PERFECT_EXTENSIONS
        look_for :verb, :pf
      end

      reset all
    end
  end

  def imperative
    unless short_imperative
      if has IMPERATIVE_ENDING then look_for :verb, :pr
        if has THEMATIC_VOWEL  then look_for :same
          if has THEMATIC_I_OF_M  then look_for :same; end
        end
        reset all
      end

      if has DEP_IMP_ENDING then look_for :verb, :pr
        if has THEMATIC_VOWEL  then look_for :same
          if has THEMATIC_I_OF_M  then look_for :same; end
        end
        reset all
      end
    end
  end

  def infinitive
    if has INFINITIVE_PR
      look_for :verb, :pr
      if has THEMATIC_VOWEL
        look_for :same
      end
      reset all
    end

    if has INFINITIVE_PF
      look_for :verb, :pf
      reset all
    end
  end

  def subjunctive_present_of_A_conjugation
    append_a_search_and_chop_it if extension == "e" && stem !~ /i$/
  end

  def first_person_present_of_A_conjugation
    append_a_search_and_chop_it if ending =~ /(o|or)$/ && extension.empty? # laudavero
  end

  def append_a_search_and_chop_it
    stem << "a"
    look_for :same
    stem.chop!
  end

  def short_imperative
    if stem =~ /dic$|duc$|fac$|fer$/
      look_for :verb, :pr # had return true before, but look_for should return true anyway
    end
  end

  def valid_itypes_for_conjugable
    if column == :pr
      itype << 1 if stem =~ /a$/
      itype << 2 if stem =~ /e$/
      itype << 3 if stem =~ /[^aeio]$/ && thematic != "iu"
      itype << 4 if stem =~ /i$/
      itype << 5 if stem =~ /[^aeio]$/ && thematic != "u"
    end

    if column == :pf
      itype << "v"      if stem =~ /v$/
      itype << "u"      if stem =~ /u$/
      itype << "s"      if stem =~ /s$|x$/
      itype << "else"   if stem !~ /v$|u$|s$|x$/
      itype << "ablaut" if stem !~ /v$|u$|s$|x$/
      # regexps needed
      itype << "reduplication" if stem
    end
  end
end

