require "constrain/version"

module Constrain
  # Raised if types doesn't match a class expression
  class MatchError < StandardError
    def initialize(value, exprs, message: nil, unwind: 0, not_argument: false, not_value: nil)
      if not_argument
        super message || "Expected #{value.inspect} to not equal #{not_value.inspect}"
      else
        super message || "Expected #{value.inspect} to match #{Constrain.fmt_exprs(exprs)}"
      end
    end
  end

  def self.included base
    base.extend ClassMethods
  end

  # :call-seq:
  #   constrain(value, *class-expressions, unwind: 0)
  #   constrain(value, *values, unwind: 0)
  #
  # Check that value matches one of the class expressions. Raises a
  # ArgumentError if the expression is invalid and a Constrain::MatchError if
  # the value doesn't match. The exception's backtrace skips :unwind number of
  # entries
  def self.constrain(value, *exprs, **opts)
    do_constrain(value, *exprs, **opts)
  end

  # See Constrain.constrain
  def constrain(...) = Constrain.do_constrain(...)

  # Like #constrain but returns true/false to indicate the result instead of
  # raising an exception
  def self.constrain?(value, *exprs, **opts)
    do_constrain?(value, *exprs, **opts)
  end

  # See Constrain.constrain?
  def constrain?(...) = Constrain.do_constrain?(...)

  module ClassMethods
    # See Constrain.constrain
    def constrain(...) Constrain.do_constrain(...) end

    # See Constrain.constrain?
    def constrain?(...) Constrain.do_constrain?(...) end
  end

  # :call-seq:
  #   do_constrain(value, *exprs, unwind: 0, message: nil, not: nil)
  #
  # unwind is automatically incremented by one because ::do_constrain is always
  # called from one of the other constrain methods
  #
  def self.do_constrain(value, *exprs, unwind: 0, message: nil, **opts)
    opts.keys.empty? || opts.keys == [:not] or raise ArgumentError
    unwind += 1
    not_argument = opts.key?(:not)
    not_value = opts[:not]
    
    begin
      if exprs.empty?
        value or raise MatchError.new(value, [], message: message, unwind: unwind)
      else
        exprs.any? { |expr| Constrain.do_constrain_value?(value, expr) } or 
            raise MatchError.new(value, exprs, message: message, unwind: unwind)
      end
      !not_argument || value != not_value or 
          raise MatchError.new(
              value, exprs, message: message, unwind: unwind, not_argument: true, not_value: not_value)
        
    rescue ArgumentError, Constrain::MatchError => ex
      ex.set_backtrace(caller[1 + unwind..-1])
      raise
    end
    value
  end

  def self.do_constrain?(...)
    begin
      do_constrain(...)
    rescue MatchError
      return false
    end
    true
  end

  def self.do_constrain_value?(value, expr)
    case expr
      when Class, Module
        expr === value
      when Array
        !expr.empty? or raise ArgumentError, "Empty array in constraint"
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
      expr === value
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
  def self.fmt_expr(expr)
    case expr
      when Class, Module; expr.to_s
      when Regexp; expr.to_s
      when Array; "[" + expr.map { |expr| fmt_expr(expr) }.join(", ") + "]"
      when Hash; "{" + expr.map { |k,v| "#{fmt_expr(k)} => #{fmt_expr(v)}" }.join(", ") + "}"
      when Proc; "Proc@#{expr.source_location.first}:#{expr.source_location.last}"
    else
      expr.inspect
    end
  end
end

