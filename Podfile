# 配置内容详见：PodConfigs/config_podspec.rb
require_relative "PodConfigs/config_podspec.rb"

# Uncomment the next line to define a global platform for your project
platform :ios, YXConfig.deployment_target
source 'https://github.com/CocoaPods/Specs.git'
# 云信 IM UIKit 10.9.70+ 的 spec 源（GitHub / Gitee 同一份内容，任选其一即可，这里同时列出作演示）
source 'https://github.com/netease-im/Specs.git'
source 'https://gitee.com/netease-im/Specs.git'

target 'app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # UI 组件
#  pod 'NEChatUIKit', YXConfig.imuikit_version               # 会话（聊天）组件
#  pod 'NEContactUIKit', YXConfig.imuikit_version            # 通讯录组件
#  pod 'NEConversationUIKit', YXConfig.imuikit_version       # (云端)会话列表组件
#  pod 'NELocalConversationUIKit', YXConfig.imuikit_version  # (本地)会话列表组件
#  pod 'NETeamUIKit', YXConfig.imuikit_version               # 群相关设置组件
#  pod 'NEAdaptiveUIKit', YXConfig.imuikit_version           # 自适应呈现组件（折叠屏双栏）
#
#  # 扩展库 - AI 划词搜索
#  pod 'NEAISearchKit', YXConfig.imuikit_version

  # 扩展库 - 呼叫组件
  pod 'NERtcSDK/RtcBasic'           #  RTC 音视频基础组件
  pod 'NERtcSDK/Nenn'               #  RTC 音视频神经网络组件（使用背景虚化功能需要集成）
  pod 'NERtcSDK/Segment'            #  RTC 音视频背景分割组件（使用背景虚化功能需要集成）
  pod 'NERtcCallKit/NOS_Special'
  pod 'NERtcCallUIKit/NOS_Special'	# (源码地址：https://github.com/netease-kit/NEVideoCall-1to1/tree/main/NLiteAVDemo-iOS-ObjC/CallKit)
  
  # 可选 - 图片选择库（6.0.0 起改为 Swift 6 隔离实现，与 Demo 的 CustomConfig 不兼容）
  pod 'ZLPhotoBrowser', '4.7.4'

  # 如果需要查看UI部分源码请注释掉以上在线依赖(不包含呼叫组件)，打开下面的本地依赖
  pod 'NEBaseUIKit', :path => 'NEBaseUIKit/NEBaseUIKit.podspec'
  pod 'NEAdaptiveUIKit', :path => 'NEAdaptiveUIKit/NEAdaptiveUIKit.podspec'
  pod 'NEChatUIKit', :path => 'NEChatUIKit/NEChatUIKit.podspec'
  pod 'NEContactUIKit', :path => 'NEContactUIKit/NEContactUIKit.podspec'
  pod 'NEConversationUIKit', :path => 'NEConversationUIKit/NEConversationUIKit.podspec'
  pod 'NELocalConversationUIKit', :path => 'NELocalConversationUIKit/NELocalConversationUIKit.podspec'
  pod 'NETeamUIKit', :path => 'NETeamUIKit/NETeamUIKit.podspec'
  pod 'NEAISearchKit', :path => 'NEAISearchKit/NEAISearchKit.podspec'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = YXConfig.deployment_target
    end
  end
end
