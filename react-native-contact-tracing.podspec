require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']
  s.description  = package['description']
  s.homepage     = package['homepage']
  s.license      = package['license']
  s.authors      = { 'Thomas Zachariah' => 'tzachari@berkeley.edu' }
  s.platforms    = { :ios => '13.0' }
  s.source       = { :git => 'https://github.com/tzachari/react-native-contact-tracing.git', :tag => '#{s.version}' }
  s.source_files = 'ios/**/*.{h,m,swift}'
  s.requires_arc = true

  s.dependency 'React'
  s.dependency 'TCNClient'
end

