require_relative 'lib/constrain/version'

Gem::Specification.new do |spec|
  spec.name          = "constrain"
  spec.version       = Constrain::VERSION
  spec.authors       = ["Claus Rasmussen"]
  spec.email         = ["claus.l.rasmussen@gmail.com"]

  spec.summary       = %q{Dynamic in-file type checking}
  spec.description   = %q{
    Allows you check if an object match a class expression. It is typically
    used to check the type of method paraameters. It is an alternative to using
    Ruby-3 .rbs files but with a different syntax and only dynamic checks
    
    Typically you'll include the Constrain module and use #constrain to check
    the type of method parameters:

      include Constrain

      # f takes a String and an array of Integer objects. Raise a Constrain::Error
      # if parameters doesn't have the expected types
      def f(a, b)
        constrain a, String
        constrain b, [Integer]
      end

    Constrain works with ruby-2 (and maybe ruby-3)
  }
  spec.homepage      = "http://https://github.com/clrgit/constrain/"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # spec.add_dependency GEM [, VERSION]

  # spec.add_development_dependency GEM [, VERSION]
  spec.add_development_dependency "simplecov"
end
