#
# Be sure to run `pod lib lint NEMapKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

# 配置内容详见：../PodConfigs/config_podspec.rb
require_relative "../PodConfigs/config_podspec.rb"

Pod::Spec.new do |spec|
  spec.name         = 'NEMapKit'
  spec.version      = YXConfig.imuikit_version
  spec.summary      = 'Netease XKit'
  spec.homepage         = YXConfig.homepage
  spec.license          = YXConfig.license
  spec.author           = YXConfig.author
  spec.ios.deployment_target = YXConfig.deployment_target
  spec.swift_version = YXConfig.swift_version
  spec.source           = { :git => '', :tag => spec.version.to_s }
  spec.static_framework = true
  spec.source_files = 'NEMapKit/Classes/**/*'
  YXConfig.pod_target_xcconfig(spec)

  spec.dependency 'AMap3DMap'
  spec.dependency 'AMapSearch'
  spec.dependency 'AMapLocation'
  spec.dependency 'NEChatUIKit'
end