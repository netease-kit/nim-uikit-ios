#
# Be sure to run `pod lib lint NEMapKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NEMapKit'
  s.version          = '9.7.0'
  s.summary          = 'Netease XKit'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/xushandong/NEMapKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :'type' => 'Copyright', :'text' => ' Copyright 2022 Netease '}
  s.author           = 'yunxin engineering department'
  s.source           = { :git => 'ssh://git@g.hz.netease.com:22222/yunxin-app/xkit-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'NEMapKit/Classes/**/*'
#  s.resource = 'NEMapKit/Assets/**/*'
  
  s.dependency 'AMap2DMap'
  s.dependency 'AMapSearch'
  s.dependency 'AMapLocation'
  s.static_framework = true
  s.dependency 'NEChatUIKit'
  s.dependency 'NEChatKit'
end
