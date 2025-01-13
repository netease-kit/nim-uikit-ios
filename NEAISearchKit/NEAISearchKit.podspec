#
# Be sure to run `pod lib lint NEAISearchKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

# 配置内容详见：../PodConfigs/config_podspec.rb
require_relative "../PodConfigs/config_podspec.rb"

Pod::Spec.new do |spec|
  spec.name         = 'NEAISearchKit'
  spec.version      = YXConfig.imuikit_version
  spec.summary      = 'Netease XKit'
  spec.homepage         = YXConfig.homepage
  spec.license          = YXConfig.license
  spec.author           = YXConfig.author
  spec.ios.deployment_target = YXConfig.deployment_target
  spec.swift_version = YXConfig.swift_version
  spec.source           = { :git => '', :tag => spec.version.to_s }
  spec.source_files = 'NEAISearchKit/Classes/**/*'
  spec.resource = 'NEAISearchKit/Assets/**/*'
  YXConfig.pod_target_xcconfig(spec)

  spec.dependency 'NEChatKit'
  spec.dependency 'NECommonUIKit'

end
