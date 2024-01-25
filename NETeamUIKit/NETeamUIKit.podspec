#
# Be sure to run `pod lib lint NETeamUIKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NETeamUIKit'
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

  s.homepage         = 'http://netease.im'
  s.license          = { :'type' => 'Copyright', :'text' => ' Copyright 2022 Netease '}
  s.author           = 'yunxin engineering department'
  s.source           = { :git => 'https://github.com/netease/NEKitGroupUI.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
      'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
    }
  
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'NETeamUIKit/Classes/**/*'
  s.resource = 'NETeamUIKit/Assets/**/*'
  s.dependency 'NECommonUIKit'
  s.dependency 'NEChatKit'

end
