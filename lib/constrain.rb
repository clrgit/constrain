require "constrain/version"

module Constrain
  # Raised on any error
  class Error < StandardError; end

  # Raised if types doesn't match a class expression
  class TypeError < Error
    def initialize(value, exprs, msg = nil)
      super msg || "Expected #{value.inspect} to match #{Constrain.fmt_exprs(exprs)}"
    end
  end

  # Check that value matches one of the class expressions. Raises a
  # Constrain::Error if the expression is invalid and a Constrain::TypeError if
  # the value doesn't match
  def constrain(value, *exprs)
    msg = exprs.pop if exprs.last.is_a?(String)
    begin
      !exprs.empty? or raise Error, "Empty class expression"
      exprs.any? { |expr| Constrain.check(value, expr) } or raise TypeError.new(value, exprs, msg)
    rescue Error => ex
      ex.set_backtrace(caller[1..-1])
      raise
    end
  end

  # Return true if the value matches the class expression. Raises a
  # Constrain::Error if the expression is invalid
  def self.check(value, expr)
    case expr
      when Class, Module
        value.is_a?(expr)
      when Array
        !expr.empty? or raise Error, "Empty array"
        value.is_a?(Array) && value.all? { |elem| expr.any? { |e| check(elem, e) } }
      when Hash
        value.is_a?(Hash) && value.all? { |key, value|
          expr.any? { |key_expr, value_expr|
            [[key, key_expr], [value, value_expr]].all? { |value, expr|
              if expr.is_a?(Array) && (expr.size > 1 || expr.first.is_a?(Array))
                expr.any? { |e| check(value, e) }
              else
                check(value, expr)
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

