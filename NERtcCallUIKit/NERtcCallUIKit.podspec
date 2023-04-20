#
# Be sure to run `pod lib lint NERtcCallUIKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NERtcCallUIKit'
  s.version          = '1.8.2'
  s.summary          = 'Netease XKit'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'http://netease.im'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :'type' => 'Copyright', :'text' => ' Copyright 2022 Netease ' }
  s.author           = "yunxin engineering department"
  s.source           = { :git => 'ssh://git@g.hz.netease.com:22222/yunxin-app/xkit-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'NERtcCallUIKit/Classes/**/*'
  s.resource = 'NERtcCallUIKit/Assets/**/*'
  
  s.dependency 'NERtcCallKit'
  s.dependency 'AFNetworking'
  s.dependency 'SDWebImage'
  s.dependency 'Toast'
  s.dependency 'NECoreKit'
  s.dependency 'NECommonKit'
  # s.resource_bundles = {
  #   'NERtcCallUIKit' => ['NERtcCallUIKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
