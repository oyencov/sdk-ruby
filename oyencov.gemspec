require_relative "lib/oyencov/version"

Gem::Specification.new do |s|
  s.name = "oyencov"
  s.version = OyenCov::VERSION
  s.licenses = ["MIT"]
  s.summary = "Usage-weighted test coverage for Rails"
  s.description = "Runtime and test reporters."
  s.executables = ["oyencov"]
  s.authors = ["Anonoz Chong"]
  s.email = "anonoz@oyencov.com"
  s.files = Dir["{lib}/**/*.*", "bin/*"]
  s.homepage = "https://www.oyencov.com"
  s.metadata = {
    "source_code_uri" => "https://github.com/oyencov/sdk-ruby"
  }

  s.required_ruby_version = ">= 3.1.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "minitest"
  s.add_development_dependency "mocha"
  s.add_development_dependency "standard"

  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "parser", ">= 2", "< 4.0"
  s.add_runtime_dependency "thor"
end
