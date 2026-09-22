#
# Be sure to run `pod lib lint NEConversationUIKit.podspec' to ensure this is a
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
  s.name             = NEConversationUIKit.name
  s.version          = YXConfig.imuikit_version
  s.summary          = 'Netease XKit'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target
  s.swift_version = YXConfig.swift_version

  YXConfig.pod_target_xcconfig(s)

  s.source = { :git => "https://github.com/netease-kit/" }
  s.source_files = 'NEConversationUIKit/Classes/**/*'
  s.resource = 'NEConversationUIKit/Assets/**/*'

  s.dependency NEBaseUIKit.name
  s.dependency NEChatKit.name
  s.dependency MJRefresh.name

end
