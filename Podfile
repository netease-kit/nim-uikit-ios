# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  #登录组件
  pod 'YXLogin', '1.0.0'
  
  #可选UI库
  pod 'NEContactUIKit', '10.0.0-beta'
  pod 'NEConversationUIKit', '10.0.0-beta'
  pod 'NEChatUIKit', '10.0.0-beta'
  pod 'NETeamUIKit', '10.0.0-beta'

  #可选Kit库（和UIKit对应）
  pod 'NEChatKit', '10.0.0-beta'

  #基础kit库
  pod 'NECommonUIKit', '9.6.7'
  pod 'NECommonKit', '9.6.7'
  pod 'NECoreIM2Kit', '1.0.0-beta'
  pod 'NECoreKit', '9.6.8'

  #扩展库
  pod 'NEMapKit', '10.0.0-beta'
  
  #呼叫组件，音视频通话能力，需要开通 音视频2.0，可选，聊天一面会根据依赖初始化自动显示音视频通话入口
  pod 'NIMSDK_LITE','10.2.5-beta'
  pod 'NERtcCallKit/NOS_Special', '2.4.0'
  pod 'NERtcCallUIKit/NOS_Special', '2.4.0'
  pod 'NERtcSDK', '5.5.33'


  # # 如果需要查看UI部分源码请注释掉以上在线依赖，打开下面的本地依赖
#   pod 'NEContactUIKit', :path => 'NEContactUIKit/NEContactUIKit.podspec'
#   pod 'NEConversationUIKit', :path => 'NEConversationUIKit/NEConversationUIKit.podspec'
#   pod 'NETeamUIKit', :path => 'NETeamUIKit/NETeamUIKit.podspec'
#   pod 'NEChatUIKit', :path => 'NEChatUIKit/NEChatUIKit.podspec'
#   pod 'NEMapKit', :path => 'NEMapKit/NEMapKit.podspec'
#   pod 'NERtcCallUIKit', :path => 'NERtcCallUIKit/NERtcCallUIKit.podspec'


end

#⚠️如果pod依赖报错，可打开以下注释
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
