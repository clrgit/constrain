# Constrain

`Constrain` allows you to check if an object match a class expression. It is
typically used to check the type of method parameters and is an alternative to
using Ruby-3 .rbs files but with a different syntax and only dynamic checks

Constrain works with ruby-2 (and maybe ruby-3)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'constrain'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install constrain

## Usage

You'll typically include the Constrain module and use the #constrain method to chech values:

    include Constrain

    # f takes a String and an array of Integer objects
    def f(a, b)
      constrain a, String
      constrain b, [Integer]
    end

The constrain instance method raises a Constrain::TypeError if the value
doesn't match the class expression. Constrain also defines the Constrain::check
class method that returns true/false depending on if the value match the
expression. Both methods raise a Constrain::Error if the expression is invalid

### Class Expressions

Constrain#constrain and Constrain::check use class expressions composed of
Class objects, Proc objects, or arrays and hashes of class objects. Class
objects match if the value is an instance of the class:

    constrain 42, Integer   # Success
    constrain 42, String    # Failure

Note that NilClass and TrueClass and FalseClass are valid arguments and allows
you to do value comparison for those types:

    constrain nil, Integer             # Failure
    constrain nil, Integer, NilClass   # Success

Proc objects are called with the value as argument and should return truish or falsy:

    proc = lambda { |value| value > 1 }
    constrain 42, proc   # Success
    constrain 0, proc    # Failure

Proc objects can check every aspect of an object and but you should not overuse
them as `Constrain` is throught of as a poor-man's type checker. More elaborate
constraints should be checked explicitly

Arrays match if the value is an Array and all its element match the given class expression:

    constrain [42], [Integer]   # Success
    constrain [42], [String]    # Failure

Arrays can be nested

    constrain [[42]], [[Integer]]

Note that arrays are treated specially in hashes

Hashes match if value is a hash and every key/value pair match one of the given
key-class/value-class expressions:

    constrain({"str" => 42}, String => Integer)   # Success
    constrain({"str" => 42}, String => String)    # Failure

Note that the parenthesis are needed because otherwise the Ruby parser would
interpret the hash as block argument to #constrain

Hash keys or values can also be lists of class expressions that match if any
expression match. List are annotated as an array but contains more than one
element so that `[String, Symbol]` matches either a String or a Symbol value
while `[String]` matches an array of String objects:

    constrain({ sym: 42 }, [Symbol, String] => Integer)       # Success
    constrain({ [sym] => 42 }, [Symbol, String] => Integer)   # Failure

To specify an array of Symbol or String objects in hash keys or values, make
sure the list expression is enclosed in an array:

    constrain({ [sym] => 42 }, [[Symbol, String]] => Integer)   # Success

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/clrgit/constrain.

