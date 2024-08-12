#
#  Be sure to run `pod spec lint NEChatUIKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the s.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/pods.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = 'NEChatUIKit'
  s.version      = '10.3.0'
  s.summary      = 'Chat Module of IM.'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
    s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'http://netease.im'
  s.license          = { :'type' => 'Copyright', :'text' => ' Copyright 2022 Netease '}
  s.author           = 'yunxin engineering department'
  s.source           = { :git => 'ssh://git@g.hz.netease.com:22222/yunxin-app/xkit-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'

  s.source_files = 'NEChatUIKit/Classes/**/*'
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
      'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
    }
  
  s.resource = 'NEChatUIKit/Assets/**/*'
  s.dependency 'NEChatKit'
  s.dependency 'NECommonUIKit', '9.7.0'
  s.dependency 'MJRefresh'
  s.dependency 'SDWebImageWebPCoder'
  s.dependency 'SDWebImageSVGKitPlugin'
  s.dependency 'lottie-ios','4.4.0'

end
