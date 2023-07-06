#
# Be sure to run `pod lib lint NECoreIMExtendKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NECoreIMExtendKit'
  s.version          = '0.1.0'
  s.summary          = 'A short description of NECoreIMExtendKit.'

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
                       s.author           = 'yunxinx engineering department'
                       s.source           = { :git => 'ssh://git@g.hz.netease.com:22222/yunxin-app/xkit-ios.git', :tag => s.version.to_s }
                       # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
                       s.ios.deployment_target = '9.0'
                       
  s.source_files = 'NECoreIMExtendKit/Classes/**/*'
  s.dependency 'NIMSDK_LITE'
  
  # s.resource_bundles = {
  #   'NECoreIMExtendKit' => ['NECoreIMExtendKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
