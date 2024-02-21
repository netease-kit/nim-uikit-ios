# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  #登录组件
  pod 'YXLogin', '1.0.0'
  
  #可选UI库
  pod 'NEContactUIKit', '8.9.0'
  pod 'NEConversationUIKit', '8.9.0'
  pod 'NEChatUIKit', '8.9.0'
  pod 'NETeamUIKit', '8.9.0'

  #可选Kit库（和UIKit对应）
  pod 'NEChatKit', '8.9.0'

  #基础kit库
  pod 'NECommonUIKit', '9.6.6'
  pod 'NECommonKit', '9.6.6'
  pod 'NECoreIMKit', '8.9.0'
  pod 'NECoreKit', '8.9.0'

  #扩展库
  pod 'NEMapKit', '8.9.0'

  # # 如果需要查看UI部分源码请注释掉以上在线依赖，打开下面的本地依赖
#   pod 'NEContactUIKit', :path => 'NEContactUIKit/NEContactUIKit.podspec'
#   pod 'NEConversationUIKit', :path => 'NEConversationUIKit/NEConversationUIKit.podspec'
#   pod 'NETeamUIKit', :path => 'NETeamUIKit/NETeamUIKit.podspec'
#   pod 'NEChatUIKit', :path => 'NEChatUIKit/NEChatUIKit.podspec'
#   pod 'NEMapKit', :path => 'NEMapKit/NEMapKit.podspec'


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
