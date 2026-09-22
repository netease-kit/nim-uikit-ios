#
#  Be sure to run `pod spec lint NEAISearchKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#
require_relative "../PodConfigs/config_podspec.rb"
require_relative "../PodConfigs/config_third.rb"
require_relative "../PodConfigs/config_local_common.rb"
require_relative "../PodConfigs/config_local_im.rb"

Pod::Spec.new do |spec|
  spec.name         = NEAISearchKit.name
  spec.version      = YXConfig.imuikit_version
  spec.summary      = 'Netease XKit'
  spec.homepage         = YXConfig.homepage
  spec.license          = YXConfig.license
  spec.author           = YXConfig.author
  spec.ios.deployment_target = YXConfig.deployment_target
  spec.swift_version = YXConfig.swift_version

  YXConfig.pod_target_xcconfig(spec)

  spec.source = { :git => "https://github.com/netease-kit/" }
  spec.source_files = 'NEAISearchKit/Classes/**/*'
  spec.resource = 'NEAISearchKit/Assets/**/*'

  spec.dependency NEBaseUIKit.name
  spec.dependency NEChatKit.name

end
