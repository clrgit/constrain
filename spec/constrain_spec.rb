
def accept(value, *expr)
  begin
    constrain(value, *expr)
    expect(true).to eq true
    # :nocov:
  rescue Constrain::MatchError => ex
    expect(false).to(eq(true), ex.message)
    # :nocov:
  end
end

def reject(value, *expr)
  begin
    constrain(value, *expr)
    # :nocov:
    expect(false).to(eq(true), "Expected #{value.inspect} to not match #{expr.map(&:inspect)}.join(', ')")
    # :nocov:
  rescue Constrain::Error
    expect(true).to eq true
    true
  end
end

describe "Constrain" do
  include Constrain

  let(:str) { "str" }
  let(:sym) { :sym }
  let(:float) { 1.2 }
  let(:int) { 42 }
  let(:another_int) { 43 }
  let(:msg) { "Message" }

  it 'has a version number' do
    expect(Constrain::VERSION).not_to be_nil
  end


  describe "#constrain" do
    it "accepts a sequence of class expressions" do
      accept(int, Integer)
      accept(int, Integer, String)
    end

    it "accepts a sequence of simple values" do
      accept(:yellow, :red, :yellow, :green)
      reject(:blue, :red, :yellow, :green)
    end

    it "accepts regular expressions as simple values" do
      # https://stackoverflow.com/a/719543
      email_regexp = /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+$/
      accept("noone@nowhere.com", email_regexp)
      reject("noone@@nowhere.com", email_regexp)
    end

    it "accepts a sequence of class expressions or simple values" do
      accept(42, :red, :yellow, :green, Integer)
      reject(42.0, :red, :yellow, :green, Integer)
    end

    it "accepts a :unwind option" do
      accept int, Integer, unwind: 2
      accept({int => str}, Integer => String, unwind: 2)
      accept int, Integer, Integer => String, unwind: 2
    end

    context "when sucessful" do
      it "returns the value" do
        expect(constrain(42, Integer)).to eq 42
      end
    end

    context "when unsuccessful" do
      it "raises a Constrain::Error exception" do
        expect { constrain(42, "42") }.to raise_error Constrain::Error
      end
    end

    context "when given a non-matching type" do
      it "raises a Constrain::MatchError exception" do
        expect { constrain(true, Integer) }.to raise_error Constrain::MatchError
      end
    end

    context "when given the optional msg argument" do
      it "uses that as the error message for MatchError exceptions" do
        expect { constrain(true, Integer, msg) }.to raise_error Constrain::MatchError, msg
      end
      it "ignores it for Error exceptions" do
        expect { constrain(true, msg) }.to raise_error(Constrain::Error) { |args|
          args.message != msg
        }
      end
    end

    context "when raising a MatchError" do
      it "the stack trace refers to the location of the call to #constrain" do
        lineno = nil
        expect { 
          lineno = __LINE__; constrain str, Integer # On one line!
        }.to raise_error { |e|
          expect(e.backtrace[0]).to match /^#{__FILE__}:#{lineno}:/
        }
      end
      it "skips :unwind levels of stack trace" do
        backtrace = nil
        expect { 
          backtrace = caller; constrain str, Integer, unwind: 1 # On one line!
        }.to raise_error { |e|
          expect(e.backtrace[0]).to eq backtrace[0]
        }
      end
    end
  end

  describe "#constrain?" do
    it "returns true if the constraint matches the given value" do
      expect(constrain? 3, Integer, String).to eq true
      expect(constrain? 3, String).to eq false
    end
    
    context "when given an illegal expr" do
      it "raises a Constrain::Error exception" do
        expect { constrain?(true, []) }.to raise_error Constrain::Error
      end
    end
  end

  describe "::do_constrain_value?" do
    it "expects a non-empty expr" do
      reject(str)
      reject(str, [])
    end

    it "returns true if the value match the class expression" do
      expect(Constrain.do_constrain_value? int, Integer).to eq true
      expect(Constrain.do_constrain_value? str, Integer).to eq false
    end

    it "returns false if the value doesn't match the expression" do
      expect(Constrain.constrain? 42, "42").to eq false
    end

    context "when unsuccessful" do
      it "raises a Constrain::Error exception" do
        expect { constrain(42, "42") }.to raise_error Constrain::Error
      end
    end


    context "when parsing" do
      describe "a list" do
        it "accepts a sequence of at least two exprs" do
          accept(int, Integer, String)
          accept(str, Integer, String)
          reject(str, [Integer, String])
        end
        it "accepts a list of values" do
          accept(:yellow, :red, :yellow, :green)
          reject(:blue, :red, :yellow, :green)
        end
      end

      describe "an expr" do
        it "accepts a Class object" do
          accept(int, Integer)
          reject(str, Integer)
        end
        it "accepts a Module object" do
          accept(int, Comparable)
          reject(nil, Comparable)
        end
        it "accepts an array" do
          accept [int, another_int], [Integer]
          reject int, [Integer]
          reject [int, str], [Integer]
          reject [[int]], [Integer]
        end
        it "accepts a hash" do
          accept({ sym => str }, { Symbol => String })
          reject({ sym => sym }, { Symbol => String })
          reject({ str => str }, { Symbol => String })
        end
        it "accepts a Proc object" do
          accept(sym, lambda { |val| val.is_a?(Symbol) })
          reject(str, lambda { |val| val.is_a?(Symbol) })
        end
      end

      describe "an array" do
        it "accepts an expr" do
          reject int, [Integer]
          accept [int], [Integer]
          accept [[int]], [[Integer]]
        end
        it "accepts cases" do
          reject int, [Integer, String]
          accept [int], [Integer, String]
          accept [str], [Integer, String]
          reject [float], [Integer, String]
        end
        it "accepts an empty array" do
          accept [], [Integer]
          accept [], [[Integer]]
          accept [[]], [[Integer]]
        end
      end

      describe "a hash" do
        it "accepts an expr for the key" do
          accept({ sym => int }, Symbol => Integer)
          reject({ sym => str }, Symbol => Integer)
          reject({ str => int }, Symbol => Integer)
          reject({ [sym] => int }, Symbol => Integer)

          accept({ [sym] => int }, [Symbol] => Integer)
          reject({ sym => int }, [Symbol] => Integer)
          reject({ [str] => int }, [Symbol] => Integer)
        end

        it "accepts a list of exprs for the key" do
          accept({ sym => int }, [Symbol, String] => Integer)
          accept({ str => int }, [Symbol, String] => Integer)
          reject({ int => int }, [Symbol, String] => Integer)
          reject({ [str] => int }, [Symbol, String] => Integer)

          accept({ [sym] => int }, [[Symbol, String]] => Integer)
          accept({ [str] => int }, [[Symbol, String]] => Integer)
          reject({ [[str]] => int }, [[Symbol, String]] => Integer)
        end

        it "accepts an expr for the value" do
          accept({ sym => int }, Symbol => Integer)
          reject({ sym => str }, Symbol => Integer)

          accept({ sym => [int] }, Symbol => [Integer])
          reject({ sym => int }, Symbol => [Integer])
          reject({ sym => [str] }, Symbol => [Integer])
        end

        it "accepts cases for the value" do
          accept({ sym => int }, Symbol => [String, Integer])
          accept({ sym => str }, Symbol => [String, Integer])
          reject({ sym => [int] }, Symbol => [String, Integer])
          reject({ sym => [str] }, Symbol => [String, Integer])

          accept({ sym => [int] }, Symbol => [[String, Integer]])
          reject({ sym => [[int]] }, Symbol => [[String, Integer]])
        end
      end

      describe "a proc" do
        it "accepts a Proc object" do
          accept sym, lambda { |val| val.is_a?(Symbol) }
          reject str, lambda { |val| val.is_a?(Symbol) }

          accept [sym], [lambda { |val| val.is_a?(Symbol) }]
          reject [str], lambda { |val| val.is_a?(Symbol) }
        end
      end

      context "an illegal expression" do
        it "raises a Constrain::Error" do
          expect { Constrain.do_constrain_value? int, [] }.to raise_error Constrain::Error
        end
      end
    end
  end

  describe "::fmt_exprs" do
    it "formats the expr like #{inspect} but without array markers" do
      expect(Constrain.fmt_exprs([Integer, String])).to eq "Integer, String"
    end
    context "when given an illegal expression" do
      it "raises a Constrain::Error exception" do
        expect { Constrain.fmt_exprs([int]) }.to raise_error Constrain::Error
      end
    end
  end

  describe "::fmt_expr" do
    it "formats the expr like #inspect" do
      expect(Constrain.fmt_expr([Integer, String])).to eq "[Integer, String]"
    end
    it "except Proc objects are rendered using shortened notation" do
      l = lambda { |value| true }
      expect(Constrain.fmt_expr(l)).to match /^Proc@#{__FILE__}:\d+$/
    end
    context "when given an illegal expression" do
      it "raises a Constrain::Error exception" do
        expect { Constrain.fmt_expr(int) }.to raise_error Constrain::Error
      end
    end
  end
end

describe "including Constrain" do
  it "defines constrain as a instance method" do
    klass = Class.new {
      include Constrain
      def f(int)
        constrain int, Integer
      end
    }
    expect { klass.new.f(42) }.not_to raise_error
    expect { klass.new.f("str") }.to raise_error Constrain::MatchError
  end
  it "defines constrain as a class method" do
    klass = Class.new {
      include Constrain
      def self.f(int)
        constrain int, Integer
      end
    }
    expect { klass.f(42) }.not_to raise_error
    expect { klass.f("str") }.to raise_error Constrain::MatchError
  end

  it "defines constrain? as a class method" do
    klass = Class.new {
      include Constrain
      def self.f(int)
        constrain? int, Integer
      end
    }
    expect(klass.f(42)).to eq true
    expect(klass.f("str")).to eq false
  end
end

