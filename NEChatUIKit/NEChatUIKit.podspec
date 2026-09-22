#
#  Be sure to run `pod spec lint NEChatUIKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the s.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/pods.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#
require_relative "../PodConfigs/config_podspec.rb"
require_relative "../PodConfigs/config_third.rb"
require_relative "../PodConfigs/config_local_common.rb"
require_relative "../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name         = NEChatUIKit.name
  s.version      = YXConfig.imuikit_version
  s.summary      = 'Chat Module of IM.'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target
  s.swift_version = YXConfig.swift_version

  YXConfig.pod_target_xcconfig(s)

  s.source = { :git => "https://github.com/netease-kit/" }
  s.source_files = [
    'NEChatUIKit/Classes/**/*.swift',
    'NEChatUIKit/Classes/Base/NEChatLoader.h',
    'NEChatUIKit/Classes/Base/NEChatLoader.m'
  ]
  s.resource = 'NEChatUIKit/Assets/**/*'

  s.dependency NEChatKit.name
  s.dependency NEBaseUIKit.name
  s.dependency MJRefresh.name
  s.dependency 'SDWebImageWebPCoder'
  s.dependency 'SDWebImageSVGKitPlugin'

end
