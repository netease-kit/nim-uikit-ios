#
# Be sure to run `pod lib lint NEMapKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
require_relative "../PodConfigs/config_podspec.rb"
require_relative "../PodConfigs/config_third.rb"
require_relative "../PodConfigs/config_local_common.rb"
require_relative "../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = NEMapKit.name
  s.version          = YXConfig.imuikit_version
  s.summary          = 'Netease XKit'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target
  s.swift_version = YXConfig.swift_version
  s.static_framework = true

  YXConfig.pod_target_xcconfig(s)

  s.source = { :git => "https://github.com/netease-kit/" }
  s.source_files = 'NEMapKit/Classes/**/*'
#  s.resource = 'NEMapKit/Assets/**/*'
  s.resource_bundles = {
    'NEMapKit' => ['NEMapKit/Assets/*.xcassets','NEMapKit/Assets/*.lproj']
  }

  s.dependency 'AMap3DMap'
  s.dependency 'AMapSearch'
  s.dependency 'AMapLocation'
  s.dependency NEChatUIKit.name
  s.dependency NEChatKit.name

end
