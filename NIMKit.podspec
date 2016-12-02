Pod::Spec.new do |s| 
 s.name = "NIMKit" 
 s.version = "1.0.4" 
 s.summary = "Netease IM UI Kit" 
 s.homepage = "http://netease.im" 
 s.license = { :"type" => "Copyright", :"text" => " Copyright 2016 Netease "} 
 s.authors = "Netease IM Team" 
 s.source  = { :git => "https://github.com/netease-im/NIM_iOS_UIKit.git", :tag => "#{s.version}"} 
 s.platform = :ios, '8.0' 
 s.resource   = 'NIMKit/Resources/*'
 s.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
 s.libraries  = 'sqlite3.0', 'z', 'c++'
 s.subspec 'Full' do |cs|
	cs.source_files = "NIMKit/NIMKit/**/*.{h,m}" 	
	cs.dependency 'SDWebImage', '~> 3.8.2'
	cs.dependency 'Toast', '~> 3.0'
	cs.dependency 'SVProgressHUD', '~> 2.0.3'
	cs.dependency 'M80AttributedLabel', '~> 1.5.0’
	cs.dependency 'CTAssetsPickerController', '~> 3.3.2-alpha'
    cs.dependency 'NIMSDK', '~> 3.2.0'
  end

 s.subspec 'Lite' do |cs|
    cs.source_files = "NIMKit/NIMKit/**/*.{h,m}" 
	cs.dependency 'SDWebImage', '~> 3.8.2'
	cs.dependency 'Toast', '~> 3.0'
	cs.dependency 'SVProgressHUD', '~> 2.0.3'
	cs.dependency 'M80AttributedLabel', '~> 1.5.0’
	cs.dependency 'CTAssetsPickerController', '~> 3.3.2-alpha'
	cs.dependency 'NIMSDK_LITE', '~> 3.2.0'
  end

 s.default_subspec = 'Lite'

 end 