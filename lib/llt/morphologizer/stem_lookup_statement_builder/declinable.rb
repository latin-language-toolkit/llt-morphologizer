module LLT::Morphologizer::StemLookupStatementBuilder::Declinable

  DECL_COMPONENTS = %w{ issim errim illim ior} # nd, nt, s, bindevokale
  NOMINATIVE_ENDING = [:ending, [ /(?<=us|er|es|u|e|al|ar|is|or|os|o|(?<=[^aeio])s|x|as|ur|men)$/]] # no a, um anymore                           # because of comparison (?<!i)
  OTHER_CASE_ENDING = [:ending, [ /(?<=ior|ius|nter|iter)$|ae$|am$|arum$|as$|is$|(?<!aeo)i$|o$|orum$|os$|(?<!aeiou)e$|ei$|erum$|ebus$|es$|em$|(?<!i)us$|u$|uum$|ua$|ibus$|im$|ia$|ium$|(?<=n)s$|(?<=nt)er$|iter$/]] # ubus
  UM_ENDING         = [:ending, [ /um$/, /ui$/ ]]   # i erased - filium, u erased - suum
  IUS_ENDING        = [:ending, [ /(?<=i)us$/ ]] # 2013-10-08 solely for filius, Gaius...
  A_ENDING          = [:ending, [ /(?<=[^ao])a$/ ]]  # removed u => sua
  PRONOMINAL_ENDING = [:ending, [ /(?<=ali)u[sd]$/, /ius$/ ]]   # alius aliud
  COMPARISON        = [:comparison_sign, [/ior$|ius$|issim$|lim$|rim$/]]    # ior, ius... ne ending at all...
  PPA_OR_GERUND     = [:extension, [/n$|nt$|nd$/]]
  THEMATIC_VOWEL    = [:thematic, [/[ue]$/]]
  THEMATIC_I_OF_M   = [:thematic, [/i$/]]
  FUTURE_PARTICIPLE = [:extension, [/ur$/]]


  def create_declinables
    setup(:declinable)

    nominative
    other_case
    um_ending
    ius_ending
    a_ending
    pronominal
    contracted_vocative
  end

  private

  def nominative
    if has NOMINATIVE_ENDING
      look_for :noun, :nom
      look_for :adjective, :nom
      reset :ending # ending would be overwritten by prepend otherwise!
    end
  end

  def other_case
    if has OTHER_CASE_ENDING
      look_for :noun, :stem
      look_for :adjective, :stem
      look_for :verb, :ppp
      comparison_or_verbal_extension
      reset all
    end
  end

  def um_ending
    if has UM_ENDING
      look_for :noun, :stem
      look_for :adjective, :stem
      look_for :verb, :ppp
      comparison_or_verbal_extension
      reset all
    end
  end

  def ius_ending
    # only filius is looked up here
    if has IUS_ENDING
      look_for :noun, :stem
      reset all
    end
  end

  def a_ending
    if has A_ENDING
      look_for :noun, :stem
      look_for :adjective, :stem
      look_for :verb, :ppp
      comparison_or_verbal_extension
      reset all
    end
  end

  def pronominal
    if has PRONOMINAL_ENDING
      look_for :adjective, :stem
      reset all
    end

  end

  def contracted_vocative
    if stem =~ /i$/
      look_for :noun, :stem
    end
  end

  def comparison_or_verbal_extension
    if has COMPARISON then look_for :adjective, :stem; end
    if has PPA_OR_GERUND  then look_for :verb, :pr
      if has THEMATIC_VOWEL then look_for :same
        if has THEMATIC_I_OF_M then look_for :same; end
      end
    end
    if has FUTURE_PARTICIPLE then look_for :verb, :ppp; end
  end

  def valid_itypes_for_declinable
    case table
    when :noun      then valid_noun_classes
    when :adjective then valid_adjective_classes
    when :verb      then valid_verb_classes
    end
  end

  def valid_noun_classes
    if column == :nom
      case stem              # 3 is consonantic stem, 31 vocalic stem - group 1 and so forth
      #when /(?<=a)$/         then itype << 1 # disabled in new morphologizer
      #when /(?<=um)$/        then itype << 2 # disabled in new morphologizer
      when /(?<=us)$/        then itype << 3 << 4 # 2 disabled in new morphologizer     # [^i] for comparison. cf ior here and both in Adjective nom ### erased. filius. gaius
      when /(?<=er)$/        then itype << 2 << 3
      when /(?<=es)$/        then itype << 3 # 5 disabled in new morphologizer
      when /(?<=u)$/         then itype << 4
      when /(?<=ar)$/        then itype << 3 << 31 # added for Caesar, who is 3. could be done better, but performance won't count here.
      when /(?<=e|al|ar)$/   then itype << 31
      when /(?<=is)$/        then itype << 3 << 32 << 33
      when /(?<=[^aeiou]s)$/ then itype << 3 << 33          # ns was excluded before. we don't know why.
      when /(?<=x)$/         then itype << 3 << 33 # nox! 2013-10-07 20:51
      when /(?<=[^i]or|os|o||as|ur|men)$/ then itype << 3
      end
    end

    if column == :stem && ending.empty? && stem =~ /i$/ then itype << 2; end      # fili vocative

    if column == :stem && !ending.empty?    #  nouns that end like a comparison?!
      case stem + ending   # watch out: regexps musst be redefined... stem+ending doesn't work. check corporum.
      when /[^aeou]a$/            then itype << 1 << 2 << 3 << 31 # a decl word whos stem ends with a vowel?
      when /ae$|am$|arum$|as$/    then itype << 1
      when /is$/                  then itype << 1 << 2 << 3 << 31 << 32 << 33
      when /ui$/                  then itype << 2 << 4
      when /[^aeou]i$/            then itype << 2 << 3 << 31 << 32 << 33
      when /um$/                  then itype << 2 << 3 << 4 << 31 << 32 << 33       # [^i] erased. filius
      when /o$|orum$|os$/         then itype << 2
      when /ei$|erum$|ebus$/      then itype << 5
      when /[^aeou]e$/            then itype << 2 << 3 << 33 << 5 # i allowed, acie
      when /es$/                  then itype << 3 << 32 << 33 << 5
      when /em$/                  then itype << 3 << 33 << 5
      when /ibus$/                then itype << 3 << 31 << 32 << 33 << 4
      when /us$|u$|ua$/           then itype << 2 << 4 # adds 2 in new morphologizer - evaluated through stem now
      when /im$/                  then itype << 32
      when /ia$/                  then itype << 31  # ineffective here, searched together with a now
      #when /ium$/                 then itype << 31 << 32 << 33
      end

      itype << 5 if ending == "erum"   # rerum is missed
    end
  end

  def valid_adjective_classes
    if column == :nom
      case stem
      when "maior"                     then itype << 3
      when /(?<=us|er|is|[^i]or)$/     then itype << 1 << 3 << 5
      when /(?<=ar|s|x)$/              then itype << 3
      end
    end

    if column == :stem && ! ending.empty?
      # vacui - 2013-10-07 23:42 - well this is weird.
      # Might account for vacui - but certainly not for exercitui,
      # which will arrive here, even if it's not needed in any event.
      # So do it only for vacu - and god knows what else...
      stem << ending.slice!("u") if stem == "vacu" && ending == "ui"

      case stem + ending
      when /ius$/   then itype << 5
      when /ter$/   then itype << 3 << 5 # 5? not sure. 2013-10-07 20:35
      when /[a-z]$/ then itype << 1 << 3 << 5
      end
    end

    if column == :stem && ! comparison_sign.empty? && ending.empty?
      case stem
      when /$/ then itype << 1 << 3
      end
    end
  end

  def valid_verb_classes
    if column == :ppp && !ending.empty? && (extension.empty? || extension == "ur")
      case stem
      when /(?<=t|s|x)$/ then itype << 1 << 2 << 3 << 4 << 5
      end
    end

    if column == :pr || column == :ppp && !extension.empty?
      unless extension == "n" && ending != "s"
        case stem
        when /a$/      then itype << 1
        when /i$/      then itype << 4
        when /e$/      then itype << 2
        when /[^aie]$/
          itype << 3 if thematic == "e"
          itype << 5 if thematic == "ie" || ending == "re"
        end
      end
    end

    if column == :pr && ending == "i" && extension.empty?
      case stem
      when /[^aie]$/ then itype << 3 << 5
      end
    end

    if column == :pf
      # perfect composition
      itype << 1 << 2 << 3 << 4 << 5
    end
  end
end
