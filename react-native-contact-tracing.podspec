require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'react-native-contact-tracing'
  s.version      = package['version']
  s.summary      = package['description']
  s.description  = <<-DESC
                  react-native-contact-tracing
                   DESC
  s.homepage     = 'https://github.com/tzachari/react-native-contact-tracing'
  s.license      = 'MIT'
  # s.license    = { :type => 'MIT', :file => 'FILE_LICENSE' }
  s.authors      = { 'Thomas Zachariah' => 'tzachari@berkeley.edu' }
  s.platforms    = { :ios => '9.0' }
  s.source       = { :git => 'https://github.com/tzachari/react-native-contact-tracing.git', :tag => '#{s.version}' }

  s.source_files = 'ios/**/*.{h,m,swift}'
  s.requires_arc = true

  s.dependency 'React'
  # ...
  # s.dependency '...'
end

