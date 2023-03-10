# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  #登录组件
  pod 'YXLogin', '1.0.0'
  
  #可选UI库
#  pod 'NEContactUIKit', '9.4.0'
#  pod 'NEConversationUIKit', '9.4.0'
#  pod 'NEChatUIKit', '9.4.0'
#  pod 'NETeamUIKit', '9.4.0'
  
  
  #可选Kit库（和UIKit对应）
  pod 'NEContactKit', '9.4.0'
  pod 'NEConversationKit', '9.4.0'
  pod 'NEChatKit', '9.4.0'
  pod 'NETeamKit', '9.4.0'
  
  #基础kit库
  pod 'NECommonUIKit', '9.4.0'
  pod 'NECommonKit', '9.4.0'
  pod 'NECoreIMKit', '9.4.0'
  pod 'NECoreKit', '9.4.0'
  
  #扩展库
#  pod 'NEMapKit', '9.4.0'
  
  #呼叫组件，音视频通话能力，需要开通 音视频2.0，可选，聊天一面会根据依赖初始化自动显示音视频通话入口
#  pod 'NERtcCallUIKit', '1.8.2'
  pod 'NERtcCallKit', '1.8.2'
  pod 'NERtcSDK', '4.6.29'

  # 如果需要查看UI部分源码请注释掉以上在线依赖，打开下面的本地依赖
  pod 'NEContactUIKit', :path => 'NEContactUIKit/NEContactUIKit.podspec'
  pod 'NEConversationUIKit', :path => 'NEConversationUIKit/NEConversationUIKit.podspec'
  pod 'NETeamUIKit', :path => 'NETeamUIKit/NETeamUIKit.podspec'
  pod 'NEChatUIKit', :path => 'NEChatUIKit/NEChatUIKit.podspec'
  pod 'NEMapKit', :path => 'NEMapKit/NEMapKit.podspec'
  pod 'NERtcCallUIKit', :path => 'NERtcCallUIKit/NERtcCallUIKit.podspec'


end

#fix bug in Xcode 14
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'RSKPlaceholderTextView'
      target.build_configurations.each do |config|
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
  end
end

#⚠️如果pod依赖报错，可打开以下注释
#post_install do |installer|
#  installer.pods_project.targets.each do |target|
#    target.build_configurations.each do |config|
#      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
#    end
#  end
#end
