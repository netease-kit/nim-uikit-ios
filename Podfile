# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  #可选UI库
  pod 'NEContactUIKit', '9.7.3'
  pod 'NEConversationUIKit', '9.7.3'
  pod 'NEChatUIKit', '9.7.3'
  pod 'NETeamUIKit', '9.7.3'

  #可选Kit库（和UIKit对应）
  pod 'NEChatKit', '9.7.3'

  #基础kit库
  pod 'NECommonUIKit', '9.7.1'
  pod 'NECommonKit', '9.6.6'
  pod 'NECoreIMKit', '9.6.7'
  pod 'NECoreKit', '9.6.6'

  #扩展库
  pod 'NEMapKit', '9.7.3'
  
  #呼叫组件，音视频通话能力，需要开通 音视频2.0，可选，聊天一面会根据依赖初始化自动显示音视频通话入口
  pod 'NIMSDK_LITE','9.14.2'
  pod 'NERtcCallKit/NOS_Special', '2.2.0'
  pod 'NERtcCallUIKit/NOS_Special', '2.2.0'
  pod 'NERtcSDK', '5.5.2'


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
