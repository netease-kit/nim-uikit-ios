Pod::Spec.new do |s| 
 s.name = "NIMKit" 
 s.version = "1.0.3" 
 s.summary = "Netease IM UI Kit" 
 s.homepage = "http://netease.im" 
 s.license = { :"type" => "Copyright", :"text" => " Copyright 2016 Netease "} 
 s.authors = "Netease IM Team" 
 s.source  = { :git => "https://github.com/netease-im/NIM_iOS_UIKit.git", :tag => "#{s.version}"} 
 s.platform = :ios, '8.0' 


 s.subspec 'Full' do |cs|
	cs.source_files = "NIMKit/NIMKit/**/*.{h,m}" 
	cs.resource = 'NIMKit/Resources/*'
	cs.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
	cs.libraries  = 'sqlite3.0', 'z', 'c++'
	cs.dependency 'SDWebImage'
	cs.dependency 'Toast'
	cs.dependency 'SVProgressHUD'
	cs.dependency 'M80AttributedLabel'
	cs.dependency 'CTAssetsPickerController'
    cs.dependency 'NIMSDK', '~> 3.2.0'
  end

 s.subspec 'Lite' do |cs|
    cs.source_files = "NIMKit/NIMKit/**/*.{h,m}" 
	cs.resource = 'NIMKit/Resources/*'
	cs.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
	cs.libraries  = 'sqlite3.0', 'z', 'c++'
	cs.dependency 'SDWebImage'
	cs.dependency 'Toast'
	cs.dependency 'SVProgressHUD'
	cs.dependency 'M80AttributedLabel'
	cs.dependency 'CTAssetsPickerController'
	cs.dependency 'NIMSDK_LITE', '~> 3.2.0'
  end

 s.default_subspec = 'Lite'

 end 