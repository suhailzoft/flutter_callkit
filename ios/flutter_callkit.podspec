#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_callkit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_callkit'
  s.version          = '0.0.1'
  s.summary          = 'Flutter Callkit'
  s.description      = <<-DESC
Flutter Callkit
                       DESC
  s.homepage         = 'https://github.com/suhailzoft/flutter_callkit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Suhail P M' => 'suhail.pm@zoftsolutions.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
