include Constrain

def accept(value, *expr)
  begin
    constrain(value, *expr)
    expect(true).to eq true
    # :nocov:
  rescue TypeError => ex
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

    context "when given an illegal expr" do
      it "raises a Constrain::Error exception" do
        expect { constrain(true, true) }.to raise_error Constrain::Error
      end
    end

    context "when given a non-matching type" do
      it "raises a Constrain::TypeError exception" do
        expect { constrain(true, Integer) }.to raise_error Constrain::TypeError
      end
    end

    context "when given the optional msg argument" do
      it "uses that as the error message for TypeError exceptions" do
        expect { constrain(true, Integer, msg) }.to raise_error Constrain::TypeError, msg
      end
      it "ignores it for Error exceptions" do
        expect { constrain(true, msg) }.to raise_error(Constrain::Error) { |args|
          args.message != msg
        }
      end
    end
  end

  describe "::check" do
    it "expects a non-empty expr" do
      reject(str)
      reject(str, [])
    end

    it "returns true if the value match the class expression" do
      expect(Constrain.check int, Integer).to eq true
      expect(Constrain.check str, Integer).to eq false
    end

    context "when parsing" do
      describe "a list" do
        it "accepts a sequence of at least two class-exprs" do
          accept(int, Integer, String)
          accept(str, Integer, String)
          reject(str, [Integer, String])
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

    end

    context "when given an illegal expression" do
      it "raises a Constrain::Error" do
        expect { Constrain.check int, int }.to raise_error Constrain::Error
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

