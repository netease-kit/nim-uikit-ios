#
#  Be sure to run `pod spec lint NEChatUIKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = 'NEChatUIKit'
  spec.version      = '9.2.10'
  spec.summary      = 'Chat Module of IM.'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
    spec.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  spec.homepage         = 'http://netease.im'
  spec.license          = { :'type' => 'Copyright', :'text' => ' Copyright 2022 Netease '}
  spec.author           = 'yunxin engineering department'
  spec.source           = { :git => 'ssh://git@g.hz.netease.com:22222/yunxin-app/xkit-ios.git', :tag => spec.version.to_s }

  spec.ios.deployment_target = '9.0'
  spec.swift_version = '5.0'

  spec.source_files = 'NEChatUIKit/Classes/**/*'
  spec.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
      'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
    }
#  spec.resource_bundles = {
#    'NEChatUIKit' => ['NEChatUIKit/Assets/*.png']
#  }
#  spec.static_framework = true
  
  
  spec.resource = 'NEChatUIKit/Assets/**/*'
  spec.dependency 'NEChatKit'
  spec.dependency 'NECommonUIKit'
  spec.dependency 'RSKPlaceholderTextView'
  spec.dependency 'MJRefresh'
  spec.dependency 'NIMSDK_LITE'

#  spec.dependency 'AMap2DMap'
#  spec.dependency 'AMapSearch'
#  spec.dependency 'AMapLocation'

end
