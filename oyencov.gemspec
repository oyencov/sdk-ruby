require_relative "lib/oyencov/version"

Gem::Specification.new do |s|
  s.name = "oyencov"
  s.version = OyenCov::VERSION
  s.license = "Nonstandard"
  s.summary = "Usage-weighted test coverage for Rails"
  s.description = <<-EOF
    OyenCov is a service that measures usage-weighted test coverage by
    profiling the codebase line executions in production runtime.
  EOF
  s.executables = ["oyencov"]
  s.authors = ["Anonoz Chong"]
  s.email = "anonoz@oyencov.com"
  s.files = Dir["{lib}/**/*.*", "bin/*"]
  s.homepage = "https://www.oyencov.com"
  s.metadata = {
    "homepage_uri" => "https://www.oyencov.com",
    "source_code_uri" => "https://github.com/oyencov/sdk-ruby",
    "documentation_uri" => "https://docs.oyencov.com/category/ruby-on-rails",
    "changelog_uri" => "https://github.com/oyencov/sdk-ruby/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/oyencov/sdk-ruby/issues"
  }

  s.required_ruby_version = ">= 2.7.0"

  s.add_runtime_dependency "faraday", ">= 1.0", "< 3.0"
  s.add_runtime_dependency "parser", ">= 2", "< 4.0"
  s.add_runtime_dependency "thor", ">= 1.0", "< 2.0"
end
