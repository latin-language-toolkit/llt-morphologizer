require 'spec_helper'

describe LLT::Morphologizer do
  it 'should have a version number' do
    LLT::Morphologizer::VERSION.should_not be_nil
  end

  let(:morphologizer) { LLT::Morphologizer.new }

  def morph_stub(word)
    m = LLT::Morphologizer.new
    m.send(:setup, word)
    m
  end

  describe "#personal_pronons" do
    # this tests some private methods just to be safe
    context "morphologizes pronouns" do
      it "with se" do
        se = morph_stub("se")
        se.send(:clook_up, :personal_pronouns).should have(4).items
        se.send(:unique_pers_pron?).should be_true
      end

      it "with Se" do
        se = morph_stub("Se")
        se.send(:clook_up, :personal_pronouns).should have(4).items
        se.send(:unique_pers_pron?).should be_true
      end

      it "with secum" do
        secum = morph_stub("secum")
        forms = secum.send(:clook_up, :personal_pronouns)
        secum.send(:unique_pers_pron?).should be_true
        forms.should have(2).items
        forms.first.to_s(:segmentized).should == "se-cum"
      end

      it "with nosmet" do
        nosmet = morph_stub("nosmet")
        forms = nosmet.send(:clook_up, :personal_pronouns)
        nosmet.send(:unique_pers_pron?).should be_true
        forms.should have(2).items
        forms.first.to_s(:segmentized).should == "nos-met"
      end
    end
  end

  describe "#other_pronouns" do
     context "morphologizes pronouns" do
       it "with hic" do
         morph_stub("hic").send(:other_pronouns).should have(1).item
         morph_stub("hunc").send(:other_pronouns).should have(1).item
         morph_stub("huic").send(:other_pronouns).should have(3).item
       end

       it "with aliqui" do
         morph_stub("alicuius").send(:other_pronouns).should have(3).items
       end

       it "with quicumque" do
         morph_stub("quibuscumque").send(:other_pronouns).should have(6).items
       end

       it "with quilibet" do
         morph_stub("quaelibet").send(:other_pronouns).should have(4).items
       end

       it "with quivis" do
         morph_stub("quodvis").send(:other_pronouns).should have(2).items
       end

       it "with quidam" do
         morph_stub("quibusdam").send(:other_pronouns).should have(6).items
       end

       it "with is" do
         morph_stub("eas").send(:other_pronouns).should have(1).item
         morph_stub("is").send(:other_pronouns).should have(7).item # sadly - eis...
         morph_stub("ii").send(:other_pronouns).should have(1).item
       end

       it "with idem" do
         morph_stub("eorundem").send(:other_pronouns).should have(2).items
         morph_stub("eisdem").send(:other_pronouns).should have(6).items
         morph_stub("iisdem").send(:other_pronouns).should have(6).items
       end

       it "with uter" do
         morph_stub("utrum").send(:other_pronouns).should have(3).items
       end

       it "with uterque" do
         morph_stub("utrumque").send(:other_pronouns).should have(3).items
         morph_stub("utriusque").send(:other_pronouns).should have(3).items
       end

       it "with quisque" do
         morph_stub("cuiusque").send(:other_pronouns).should have(3).items
       end

       it "with quisquam"do
         morph_stub("quisquam").send(:other_pronouns).should have(2).items
       end

       it "with quisquam"do
         morph_stub("quemquam").send(:other_pronouns).should have(2).items
       end

       it "with quispiam" do
         morph_stub("quempiam").send(:other_pronouns).should have(2).items
       end

       it "with quispiam" do
         morph_stub("quispiam").send(:other_pronouns).should have(2).items
       end

       it "with quibuscum" do
         morph_stub("quibuscum").send(:other_pronouns).should have(3).items
       end

       it "with quonam" do
         morph_stub("quonam").send(:other_pronouns).should have(2).items
       end

      # Might be solved through an exceptional form
      #m = morph("i")
      #m.pronouns.should have(1).item
    end

    it "returns when a unique pronoun like huius is found" do
      morphologizer.should_not receive(:direct_lookup)
      morphologizer.morphologize("huius")
    end

    it "continues when a homographic pronoun like his is found" do
      morphologizer.should receive(:direct_lookup)
      morphologizer.morphologize("hic")
    end
  end

  describe "#prepositions" do
    it "returns when a unique preposition like in is found" do
      morphologizer.should_not receive(:direct_lookup)
      morphologizer.morphologize("in")
    end

    it "goes on when a not uniq prep like cum is found - another entry should be present and then returned" do
      morphologizer.should_not receive(:direct_lookup)
      morphologizer.morphologize("cum").should have(2).items
    end
  end

  describe "#numerals" do
    it "returns when a roman numeral is found" do
      morphologizer.should_not receive(:direct_lookup)
      morphologizer.morphologize("MD").should have(1).item
    end
  end

  describe "#look_up" do
    context "with conjunctions" do
      it "returns when a unique conjunction like et is found" do
        morphologizer.should_not receive(:direct_lookup)
        morphologizer.morphologize("et")
      end
    end

    #context "with subjunctions" do
    #  it "returns when a unique conjunction like et is found" do
    #  end
    #end
  end

  describe "#morphologize" do
    LLT::DbHandler::Stub.setup

    describe "returns morphologized forms" do
      context "with nouns" do
        it "ratio" do
          f = morphologizer.morphologize("ratio")
          f.should have(2).item
          f1, f2 = f
          f1.casus.should == 1
          f2.casus.should == 5
        end

        it "homine" do
          f = morphologizer.morphologize("homine")
          f.should have(1).item
          f.first.casus.should == 6
          f.first.to_s(:segmentized).should == "homin-e"
        end

        it "nox" do
          f = morphologizer.morphologize("nox")
          f.should have(2).items
        end

        it "serve" do
          f = morphologizer.morphologize("serve")
          f.should have(1).item
        end

        it "fili - contracted vocative" do
          f = morphologizer.morphologize("fili")
          f.should have(1).item
        end

        it "filius - ius o declension" do
          f = morphologizer.morphologize("filius")
          f.should have(1).item
        end
      end

      context "with verbs" do
        it "miserunt" do
          f = morphologizer.morphologize("miserunt")
          f.should have(1).item
        end

        it "hortant" do
          f = morphologizer.morphologize("hortant")
          f.should have(0).items # no active forms
        end

        it "hortatur" do
          f = morphologizer.morphologize("hortatur")
          f.should have(1).item
        end

        context "and infinitives" do
          # the active one all bring the stupid pass inf...
          it "audire" do
            f = morphologizer.morphologize("audire")
            f.should have(2).items
          end

          it "audiri" do
            f = morphologizer.morphologize("audiri")
            f.should have(1).item
          end

          it "canare" do
            f = morphologizer.morphologize("canare")
            f.should have(2).items
          end

          it "canari" do
            f = morphologizer.morphologize("canari")
            f.should have(1).items
          end

          it "monere" do
            f = morphologizer.morphologize("monere")
            f.should have(2).items
          end

          it "hortari" do
            f = morphologizer.morphologize("hortari")
            f.should have(1).items
          end
        end
      end

      context "with plain adverbs" do
        it "iam" do
          f = morphologizer.morphologize("iam")
          f.should have(1).item
        end
      end

      context "with adverbs from adjectives" do
        it "diligenter" do
          f = morphologizer.morphologize("diligenter")
          f.should have(1).item
        end

        it "laete" do
          # the real world has a noun as well, will never be
          # in the stub db I guess.
          f = morphologizer.morphologize("laete")
          f.should have(2).item # there's actually a vocative as well...
          f.first.casus.should == 5
          f.map(&:to_s).should == %w{ laete laete }
        end
      end

      context "with adjectives" do
        it "feri" do
          f = morphologizer.morphologize("feri")
          f.should have(4).items # all from ferus3
        end
      end

      context "with cardinals" do
        it "duo" do
          f = morphologizer.morphologize("duo")
          f.should have(4).items
        end

        it "sex" do
          f = morphologizer.morphologize("sex")
          f.should have(1).item
        end
      end

      context "with ethnics" do
        it "Haeduorum" do
          f = morphologizer.morphologize("Haeduorum")
          f.should have(2).items
          f.first.to_s.should == "Haeduorum"
        end
      end

      context "with pronouns" do
        it "quis" do
          f = morphologizer.morphologize("quis")
          f.should have(2).items # m && f?
        end

        it "quid" do
          f = morphologizer.morphologize("quid")
          f.should have(2).items # nom and acc
        end

        it "aliquis" do
          f = morphologizer.morphologize("aliquis")
          f.should have(2).items
        end

        it "quidque" do
          f = morphologizer.morphologize("quidque")
          f.should have(2).items
        end

        it "quodque" do
          f = morphologizer.morphologize("quodque")
          f.should have(2).items
        end

        it "quisque" do
          f = morphologizer.morphologize("quisque")
          f.should have(3).items
        end

        it "quicquam" do
          f = morphologizer.morphologize("quicquam")
          f.should have(2).items
        end

        it "quisquis" do
          f = morphologizer.morphologize("quisquis")
          f.should have(2).items
        end

        it "quidquid" do
          f = morphologizer.morphologize("quidquid")
          f.should have(2).items
        end

        it "quoquo" do
          f = morphologizer.morphologize("quoquo")
          f.should have(3).item # m f n, it's substantivic!
        end

        it "quicquid" do
          f = morphologizer.morphologize("quicquid")
          f.should have(2).items
        end

        it "unusquisque" do
          f = morphologizer.morphologize("unusquisque")
          f.map(&:to_s).should == %w{ unusquisque } * 3
        end

        it "uniuscuiusque" do
          f = morphologizer.morphologize("uniuscuiusque")
          f.map(&:to_s).should == %w{ uniuscuiusque } * 3
        end

      end

      context "with mixed forms" do
        it "ita - adverb and ppp of ire" do
          f = morphologizer.morphologize("ita")
          f.should have(2).item
        end

        it "fero - ferre and ferus3" do
          f = morphologizer.morphologize("fero")
          f.should have(5).items # 1 from ferre, 4 from ferus3
        end

        it "subito - adverb and ppp of ire" do
          f = morphologizer.morphologize("subito")
          f.should have(5).items # 1 adv, 4 ppp
        end
      end
    end

    describe "handles irregular verbs" do
      it "fiebat" do
        f = morphologizer.morphologize("fiebat")
        f.should have(1).item
      end

      it "fio" do
        f = morphologizer.morphologize("fio")
        f.should have(1).item
      end

      it "posse" do
        f = morphologizer.morphologize("posse")
        f.should have(1).item
      end

      it "ferri" do
        f = morphologizer.morphologize("ferri")
        f.should have(1).item
      end
    end

    describe "handles prefixed irregular verbs" do
      it "desum" do
        f = morphologizer.morphologize("desum")
        f.should have(1).item
        f.first.to_s(:segmentized).should == "de-s-u-m"
      end

      it "maluit" do
        f = morphologizer.morphologize("maluit")
        f.should have(1).item
        f.first.to_s(:segmentized).should == "malu-it"
        f.first.tempus.should == :pf
      end

      it "mavult" do
        f = morphologizer.morphologize("mavult")
        f.should have(1).item
        f.first.to_s(:segmentized).should == "mavul-t"
      end

      it "it" do
        f = morphologizer.morphologize("it")
        f.should have(1).item
        f.first.to_s(:segmentized).should == "i-t"
      end

      it "vult" do
        f = morphologizer.morphologize("vult")
        f.should have(1).item
        f.first.to_s(:segmentized).should == "vul-t"
      end

      it "nolumus" do
        f = morphologizer.morphologize("nolumus")
        f.should have(1).item
        f.first.to_s(:segmentized).should == "nol-u-mus"
      end

      it "contulissent" do
        f = morphologizer.morphologize("contulissent")
        f.should have(1).item
        f.first.to_s(:segmentized).should == "con-tul-isse-nt"
      end

      it "intulisset" do
        f = morphologizer.morphologize("intulisset")
        f.should have(1).item
        f.first.to_s(:segmentized).should == "in-tul-isse-t"
      end

      it "inito" do
        f = morphologizer.morphologize("inito")
        f.should have(4).item
      end
    end

    describe "takes an optional keyword argument add_to" do
      let(:token_dummy) do
        Class.new do
          attr_reader :forms
          def initialize; @forms = []; end
          def <<(forms); @forms += forms; end
        end
      end

      it "adds the result to the given object if #<< is implemented" do
        forms = morphologizer.morphologize("est", add_to: token_dummy)
        token_dummy.forms.should == forms
      end

      it "does nothing to the given object when #<< it does not respond to" do
        token = double(respond_to?: false)
        token.should_not receive(:<<)
        morphologizer.morphologize("est", add_to: token)
      end
    end

    it "writes stem pack objects to morphologized forms" do
      forms = morphologizer.morphologize('homo')
      homo = forms.first
      homo.stems.should_not be_nil

      forms = morphologizer.morphologize('est')
      est = forms.first
      est.stems.should_not be_nil
    end

    it "one instance handles multiple requests" do
      tokens = %w{ homo ratio }
      forms = tokens.map { |t| morphologizer.morphologize(t) }
      forms.should have(2).items
      h = forms[0]
      r = forms[1]
      (h.any? && h.all? { |f| f.to_s == "homo"}) .should be_true
      (r.any? && r.all? { |f| f.to_s == "ratio"}).should be_true
    end
  end
end
