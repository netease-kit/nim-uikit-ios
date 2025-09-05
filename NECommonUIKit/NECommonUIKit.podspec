#
# Be sure to run `pod lib lint NETeamUIKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

# 配置内容详见：../PodConfigs/config_podspec.rb
require_relative "../PodConfigs/config_podspec.rb"

Pod::Spec.new do |s|
  s.name             = 'NECommonUIKit'
  s.version          = YXConfig.commonuikit_version
  s.summary          = 'Netease XKit'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target
  s.swift_version = YXConfig.swift_version
  s.source           = { :git => '', :tag => s.version.to_s }
  s.source_files = 'NECommonUIKit/Classes/**/*'
  s.resource = 'NECommonUIKit/Assets/**/*'
  YXConfig.pod_target_xcconfig(s)

  s.dependency 'NECommonKit'
  s.dependency 'SDWebImage'
  
  
  
end
