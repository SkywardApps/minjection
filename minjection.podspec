#
# Be sure to run `pod lib lint minjection.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'minjection'
  s.version          = '0.5.0'
  s.summary          = 'A minimal dependency injection library for Objective-C.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This project was born out of necessity.  There are a small handful
of existing DI libraries for objective-c, but none quite matched our needs.

We wrote this to fill the gaps because we've been spoiled by good options in other
languages, and hope this will likewise prove useful to others.
                       DESC

  s.homepage         = 'https://github.com/SkywardApps/minjection'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nicholas Elliott' => 'nelliott@skywardapps.com' }
  s.source           = { :git => 'https://github.com/SkywardApps/minjection.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'minjection/Classes/**/*'
  
  # s.resource_bundles = {
  #   'minjection' => ['minjection/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
