Gem::Specification.new do |s|
  s.name = "oyencov"
  s.version = "0.0.1.pre"
  s.licenses = ["MIT"]
  s.summary = "Client-side telemetry"
  s.description = "Runtime and test reporters."
  s.executables = ["oyencov"]
  s.authors = ["Anonoz Chong"]
  s.email = "anonoz@oyencov.com"
  s.files = Dir["{lib}/**/*.*", "bin/*"]
  s.homepage = "https://www.oyencov.com"

  s.required_ruby_version = ">= 3.1.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "minitest"
  s.add_development_dependency "mocha"
  s.add_development_dependency "standard"

  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "parser", ">= 2", "< 4.0"
  s.add_runtime_dependency "thor"
end
