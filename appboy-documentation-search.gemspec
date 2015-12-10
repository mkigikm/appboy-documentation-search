Gem::Specification.new do |s|
  s.name = 'appboy-documentation-search'
  s.license = 'MIT'
  s.version = '0.0.4'
  s.date = '2015-12-10'
  s.summary = 'Search for Appboy documentation'
  s.description = 'Search Jekyll collections down to the sub-heading level in Appboy documentation'
  s.authors = ['Matt Hicks']
  s.email = 'matt.hicks@appboy.com'
  s.files = Dir.glob('lib/**/*')
  s.homepage = 'https://github.com/mkigikm/appboy-documentation-search'
  s.require_paths = ['lib']

  s.add_runtime_dependency 'json', '~> 1.8'
end
