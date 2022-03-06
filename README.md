# Constrain

`Constrain` allows you to check if an object match a class expression. It is
typically used to check the type of method parameters and is an alternative to
using Ruby-3 .rbs files

```ruby
require 'constrain'
include Constrain

# f takes a String and an array of Integer objects and raises otherwise
def f(a, b)
  constrain a, String
  constrain b, [Integer]
  ...
end

f("Hello", [1, 2])    # Doesn't raise
f("Hello", "world")   # Boom
```

It is intended to be an aid in development only and to be deactivated in
production (TODO: Make it possible to deactivate)

Constrain works with ruby-2 (and maybe ruby-3)

## Usage

You will typically include Constrain globally to have #constrain available everywhere

```ruby
require 'constrain'

# Include globally to make #constrain available everywhere
include Constrain

def f(a, b, c)
  constrain a, Integer                      # An integer
  constrain b, [Symbol, String] => Integer  # Hash with String or Symbol keys
  constrain c, [String], NilClass           # Array of strings or nil
  ...
end
```

The alternative is to include the constrain Module in a common root class to
have it available in all child classes

## Methods

#### constrain(value, \*expressions, message: nil, unwind: 0)

Return the given value if it matches at least one of the expressions and raise a
Constrain::TypeError if not. The value is matched against the expressions using
the #=== operator so anything you can put into the 'when' clause of a 'case'
statement can be used. #constrain raise a Constrain::MatchError if the value
doesn't match any expression and an ArgumentError if there is a syntax error in
the expression 

The error message can be customized by adding the message option and a number
of backtrace leves can be skipped using the :unwind option. By default the
backtrace will refer to the point of the call of \#constrain. \#constrain
raises a Constrain::Error exception if there is an error in the syntax of the
class expression

\#constrain is typically used to type-check parameters in methods where you
want an exception if the parameters doesn't match the expected, but because it
returns the value if successful it can be used to check the validity of
variables in expressions too, eg. `return constrain(result_of_complex_computation, Integer)` 

#### Constrain.constrain(value, \*expressions, message: nil, unwind: 0)

Class method version of #constrain. It is automatically added to classes that
include Constrain


#### Constrain.constrain?(value, \*expressions) -> true or false

It matches value against the class expressions like #constrain but returns true
or false as result. It is automatically added to classes that include
Constrain. Constrain.constrain? raises a ArgumentError exception if there
is an error in the syntax of the expression


## Expressions

Expressions can be simple values, class expressions, or lambdas. You can mix
simple values and class expressions but not lambdas


### Simple expressions

Simple values is an easy way to check arguments with a limited set of allowed
values like

```ruby
def print_color(color)
  constrain color, :red, :yellow, :green
  ...
end
```

Simple values are compared to the expected result using the #=== operator. This
means you can use regular expressions too:

```ruby
# Simple email regular expression (https://stackoverflow.com/a/719543)
EMAIL_RE = /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+$/

def email(address)
  constrain address, EMAIL_RE
  ...
end
```

### Class Expressions

Constrain#constrain and Constrain::constrain? use class expressions composed of
class or module objects, Proc objects, or arrays and hashes of class expressions. Class or module
objects match if `value.is_a?(class_or_module)` returns true:

```ruby
constrain 42, Integer         # Success
constrain 42, Comparable      # Success
constrain nil, Comparable     # Failure
```

More than one class expression is allowed. It matches if at least one of the expressions match:

```ruby
constrain "str", Symbol, String   # Success
constrain :sym, Symbol, String    # Success
constrain 42, Symbol, String      # Failure
```

#### Arrays

Arrays match if the value is an Array and all its element match the given class expression:

```ruby
constrain [42], [Integer]   # Success
constrain [42], [String]    # Failure
```

Arrays can be nested

```ruby
constrain [[42]], [[Integer]]   # Success
constrain [42], [[Integer]]     # Failure
```

More than one element class is allowed

```ruby
constrain ["str"], [String, Symbol]   # Success
constrain [:sym], [String, Symbol]    # Success
constrain [42], [String, Symbol]      # Failure
```

Note that `[` ... `]` is treated specially in hashes

#### Hashes

Hashes match if value is a hash and every key/value pair match one of the given
key-class/value-class expressions:

```ruby
constrain({"str" => 42}, String => Integer)   # Success
constrain({"str" => 42}, String => String)    # Failure
```

Note that the parenthesis are needed because otherwise the Ruby parser would
interpret the hash as block argument to #constrain

Hash keys or values can also be lists of class expressions that match if any
expression match. List are annotated as an array but contains more than one
element so that `[String, Symbol]` matches either a String or a Symbol value
while `[String]` matches an array of String objects:

```ruby
constrain({ sym: 42 }, [Symbol, String] => Integer)       # Success
constrain({ [sym] => 42 }, [Symbol, String] => Integer)   # Failure
```

To specify an array of Symbol or String objects in hash keys or values, make
sure the list expression is enclosed in an array:

```ruby
constrain({ [sym] => 42 }, [[Symbol, String]] => Integer)   # Success
```

#### nil, true and false

NilClass is a valid argument and can be used to allow nil values:

```ruby
constrain nil, Integer             # Failure
constrain nil, Integer, NilClass   # Success
```

Boolean values are a special case since ruby doesn't have a boolean type use a
list to match for a boolean argument:

```ruby
constrain true, TrueClass, FalseClass   # Success
constrain false, TrueClass, FalseClass  # Success
constrain nil, TrueClass, FalseClass    # Failure
```

But note that it is often easier to use value expressions:

```ruby
constrain true, true, false     # Success
constrain false, true, false    # Success
constrain nil, true, false      # Failure
constrain nil, true, false, nil # Success
```

### Lambda expressions

Proc objects are called with the value as argument and should return truish or falsy:

```ruby
constrain 42, lambda { |value| value > 1 }    # Success
constrain 0, lambda { |value| value > 1 }     # Failure
```

Note that it is not possible to first match against a class expression and then
use the proc object. You will either have to check for the type too in the proc
object or make two calls to #constrain:

```ruby
constrain 0, Integer                          # Success
constrain 0, lambda { |value| value > 1 }     # Failure
```

Alternatively, you can use Constrain::constrain? to mix classes or value with lambdas:

```ruby
constrain 0, lambda { |value| Constrain::constrain?(Integer) && value > 1 }   # Failure
```

Note that even though Proc objects can check every aspect of an object, you
should not overuse it because as checks becomes more complex they tend to
include business logic that should be kept in the production code. Constrain is
only thouhgt of as a tool to catch developer errors - not errors that stem from
corrupted data

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'constrain'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install constrain

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/clrgit/constrain.

