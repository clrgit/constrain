require "constrain/version"
module Foo

  module InstanceMethods
    def bar1
      'bar1'
    end
  end

  module ClassMethods
    def bar2
      'bar2'
    end
  end
end

module Constrain
  # Raised on any error
  class Error < StandardError; end

  # Raised if types doesn't match a class expression
  class TypeError < Error
    def initialize(value, exprs, msg = nil, unwind: 0)
      super msg || "Expected #{value.inspect} to match #{Constrain.fmt_exprs(exprs)}"
    end
  end

  def self.included base
    base.extend ClassMethods
  end

  # See Constrain.constrain
  def constrain(value, *exprs)
    Constrain.do_constrain(value, *exprs)
  end

  def constrain?(value, expr)
    Constrain.do_constrain?(value, expr)
  end

  # :call-seq:
  #   constrain(value, *class-expressions, unwind: 0)
  #
  # Check that value matches one of the class expressions. Raises a
  # Constrain::Error if the expression is invalid and a Constrain::TypeError if
  # the value doesn't match. The exception's backtrace skips :unwind number of
  # entries
  def self.constrain(value, *exprs)
    do_constrain(value, *exprs)
  end

  # Return true if the value matches the class expression. Raises a
  # Constrain::Error if the expression is invalid
  #
  # TODO: Allow *exprs
  def self.constrain?(value, expr)
    do_constrain?(value, expr)
  end

  module ClassMethods
    # See Constrain.constrain
    def constrain(*args) Constrain.do_constrain(*args) end

    # See Constrain.constrain?
    def constrain?(*args) Constrain.do_constrain?(*args) end
  end

  # unwind is automatically incremented by one because ::do_constrain is always
  # called from one of the other constrain methods
  #
  def self.do_constrain(value, *exprs)
    if exprs.last.is_a?(Hash)
      unwind = (exprs.last.delete(:unwind) || 0) + 1
      !exprs.last.empty? or exprs.pop
    else
      unwind = 1
    end
    msg = exprs.pop if exprs.last.is_a?(String)
    begin
      !exprs.empty? or raise Error, "Empty class expression"
      exprs.any? { |expr| Constrain.do_constrain?(value, expr) } or 
          raise TypeError.new(value, exprs, msg, unwind: unwind)
    rescue Error => ex
      ex.set_backtrace(caller[1 + unwind..-1])
      raise
    end
    value
  end

  def self.do_constrain?(value, expr)
    case expr
      when Class, Module
        value.is_a?(expr)
      when Array
        !expr.empty? or raise Error, "Empty array"
        value.is_a?(Array) && value.all? { |elem| expr.any? { |e| Constrain.constrain?(elem, e) } }
      when Hash
        value.is_a?(Hash) && value.all? { |key, value|
          expr.any? { |key_expr, value_expr|
            [[key, key_expr], [value, value_expr]].all? { |value, expr|
              if expr.is_a?(Array) && (expr.size > 1 || expr.first.is_a?(Array))
                expr.any? { |e| Constrain.do_constrain?(value, e) }
              else
                Constrain.constrain?(value, expr)
              end
            }
          }
        }
      when Proc
        expr.call(value)
    else
      raise Error, "Illegal expression #{expr.inspect}"
    end
  end

  # Render a class expression as a String. Same as
  # <tt>exprs.map(&:inspect).join(", ")</tt> except that Proc objects are rendered as
  # "Proc@<sourcefile>:<linenumber>"
  def self.fmt_exprs(exprs)
    exprs.map { |expr| fmt_expr(expr) }.join(", ")
  end

  # Render a class expression as a String. Same as +expr.inspect+ except that
  # Proc objects are rendered as "Proc@<sourcefile>>:<linenumber>"
  #
  def self.fmt_expr(expr)
    case expr
      when Class, Module; expr.to_s
      when Array; "[" + expr.map { |expr| fmt_expr(expr) }.join(", ") + "]"
      when Hash; "{" + expr.map { |k,v| "#{fmt_expr(k)} => #{fmt_expr(v)}" }.join(", ") + "}"
      when Proc; "Proc@#{expr.source_location.first}:#{expr.source_location.last}"
    else
      raise Error, "Illegal expression"
    end
  end
end

