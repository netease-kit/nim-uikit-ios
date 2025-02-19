# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # 基础库
  pod 'NEChatKit', '10.6.0'
  
  #  # UI 组件
  pod 'NEChatUIKit', '10.6.0'               # 会话（聊天）组件
  pod 'NEContactUIKit', '10.6.0'            # 通讯录组件
  pod 'NEConversationUIKit', '10.6.0'       # (云端)会话列表组件, 与本地会话组件二者选其一
  pod 'NELocalConversationUIKit', '10.6.0'  # (本地)会话列表组件, 与云端会话组件二者选其一
  pod 'NETeamUIKit', '10.6.0'               # 群相关设置组件
  
  # 扩展库 - 地理位置组件
  pod 'NEMapKit', '10.6.0'
  
  # 扩展库 - AI 划词搜索
  pod 'NEAISearchKit', '10.6.0'
  
  # 扩展库 - 呼叫组件
  pod 'NERtcSDK/RtcBasic'                   #  RTC 音视频基础组件
  pod 'NERtcSDK/Nenn'                       #  RTC 音视频神经网络组件（使用背景虚化功能需要集成）
  pod 'NERtcSDK/Segment'                    #  RTC 音视频背景分割组件（使用背景虚化功能需要集成）
  pod 'NERtcCallKit', '3.5.0'
  pod 'NERtcCallUIKit', '3.5.0' # (源码地址：https://github.com/netease-kit/NEVideoCall-1to1/tree/main/NLiteAVDemo-iOS-ObjC/CallKit)
  
  # 如果需要查看UI部分源码请注释掉以上在线依赖，打开下面的本地依赖，云端会话组件与本地会话组件二者选其一
#  pod 'NEContactUIKit', :path => 'NEContactUIKit/NEContactUIKit.podspec'
#  pod 'NEConversationUIKit', :path => 'NEConversationUIKit/NEConversationUIKit.podspec'
#  pod 'NELocalConversationUIKit', :path => 'NELocalConversationUIKit/NELocalConversationUIKit.podspec'
#  pod 'NETeamUIKit', :path => 'NETeamUIKit/NETeamUIKit.podspec'
#  pod 'NEChatUIKit', :path => 'NEChatUIKit/NEChatUIKit.podspec'
#  pod 'NEMapKit', :path => 'NEMapKit/NEMapKit.podspec'
#  pod 'NEAISearchKit', :path => 'NEAISearchKit/NEAISearchKit.podspec'
  
end

# ⚠️如果pod依赖报错，可打开以下注释
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
