#
# Be sure to run `pod lib lint NERtcCallUIKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NERtcCallUIKit'
  s.version          = '2.4.0'
  s.summary          = 'Netease XKit'
  s.homepage         = 'http://netease.im'
  s.license          =  { :'type' => "Copyright", :'text' => " Copyright 2022 Netease " }
  s.author           = 'yunxin engineering department'
  s.ios.deployment_target = '11.0'
  s.source = { :http => "" }
  s.source_files = 'NERtcCallUIKit/Classes/**/*'
  s.resource = 'NERtcCallUIKit/Assets/**/*'
  s.dependency 'NERtcCallKit/NOS_Special','2.4.0'
  s.dependency 'SDWebImage'
  s.dependency 'NECoreKit'
  s.dependency 'NECommonKit'
  s.dependency 'NECommonUIKit'
  s.dependency 'NERtcSDK'

end
