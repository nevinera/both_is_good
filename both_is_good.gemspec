require_relative "lib/both_is_good/version"

Gem::Specification.new do |spec|
  spec.name = "both_is_good"
  spec.version = BothIsGood::VERSION
  spec.authors = ["Eric Mueller"]
  spec.email = ["nevinera@gmail.com"]

  spec.summary = "A convenient way to give a method multiple implementations"
  spec.description =  <<~DESC
    BothIsGood adds a clean way to run multiple implementations of a method,
    switching between them using a feature-flagging system or other static or
    runtime method, and potentially run multiple implementations to confirm
    accuracy.
  DESC

  spec.homepage = "https://github.com/nevinera/both_is_good"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    "git ls-files -z"
      .split("\x0")
      .reject { |f| f.start_with?("spec") }
      .reject { |f| f.start_with?("Gemfile") }
  end

  spec.bindir = "bin"
  spec.executables = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "pry", "~> 0.15"
  spec.add_development_dependency "standard", "= 1.37.0"
  spec.add_development_dependency "rubocop", "~> 1.63"
  spec.add_development_dependency "quiet_quality", "~> 1.5"
  spec.add_development_dependency "mdl", "~> 0.13"
end
