# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  #登录组件
  pod 'YXLogin', '1.0.0'
  
  #可选UI库
  pod 'NEContactUIKit', '9.2.11'
  pod 'NEQChatUIKit', '9.2.11'
  pod 'NEConversationUIKit', '9.2.11'
  pod 'NEChatUIKit', '9.2.11'
  pod 'NETeamUIKit', '9.2.11'
  
  
  #可选Kit库（和UIKit对应）
  pod 'NEContactKit', '9.2.11'
  pod 'NEQChatKit', '9.2.11'
  pod 'NEConversationKit', '9.2.11'
  pod 'NEChatKit', '9.2.11'
  pod 'NETeamKit', '9.2.11'
  
  #基础kit库
  pod 'NECommonUIKit', '9.2.11'
  pod 'NECommonKit', '9.2.11'
  pod 'NECoreIMKit', '9.2.11'
  pod 'NECoreKit', '9.2.11'


  # 如果需要查看UI部分源码请注释掉以上在线依赖，打开下面的本地依赖
#  pod 'NEQChatUIKit', :path => 'NEQChatUIKit/NEQChatUIKit.podspec'
#  pod 'NEContactUIKit', :path => 'NEContactUIKit/NEContactUIKit.podspec'
#  pod 'NEConversationUIKit', :path => 'NEConversationUIKit/NEConversationUIKit.podspec'
#  pod 'NETeamUIKit', :path => 'NETeamUIKit/NETeamUIKit.podspec'
#  pod 'NEChatUIKit', :path => 'NEChatUIKit/NEChatUIKit.podspec'
#
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
