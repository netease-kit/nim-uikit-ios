#
# Be sure to run `pod lib lint NEAdaptiveUIKit.podspec' to ensure this is a
# valid spec before submitting.
#
require_relative "../PodConfigs/config_podspec.rb"

Pod::Spec.new do |s|
  s.name             = 'NEAdaptiveUIKit'
  s.version          = YXConfig.imuikit_version
  s.summary          = 'Adaptive UIKit presentation containers for IMUIKit.'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target
  s.swift_version = '5.9'

  YXConfig.pod_target_xcconfig(s)

  s.source = { :git => "https://github.com/netease-kit/" }
  s.source_files = 'Sources/NEAdaptiveUIKit/**/*.swift'

end
