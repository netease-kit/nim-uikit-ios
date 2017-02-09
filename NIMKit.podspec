Pod::Spec.new do |s| 
 s.name = "NIMKit" 
 s.version = "1.1.1" 
 s.summary = "Netease IM UI Kit" 
 s.homepage = "http://netease.im" 
 s.license = { :"type" => "Copyright", :"text" => " Copyright 2017 Netease "} 
 s.authors = "Netease IM Team" 
 s.source  = { :git => "https://github.com/netease-im/NIM_iOS_UIKit.git", :tag => "#{s.version}"} 
 s.platform = :ios, '8.0'
 s.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
 s.libraries  = 'sqlite3.0', 'z', 'c++'
 s.subspec 'Full' do |cs|	
	cs.source_files = "NIMKit/NIMKit/**/*.{h,m}"
	cs.dependency 'NIMKit/Core'
    cs.dependency 'NIMSDK', '~> 3.4.1'
  end

 s.subspec 'Lite' do |cs|
    cs.source_files = "NIMKit/NIMKit/**/*.{h,m}"
    cs.dependency 'NIMKit/Core'
	cs.dependency 'NIMSDK_LITE', '~> 3.4.1'
  end

 s.subspec 'Core' do |os|     
    os.resources = 'NIMKit/Resources/*.*'
	os.dependency 'SDWebImage', '~> 3.8.2'
	os.dependency 'Toast', '~> 3.0'
	os.dependency 'SVProgressHUD', '~> 2.0.3'
	os.dependency 'M80AttributedLabel', '~> 1.5.0'
	os.dependency 'TZImagePickerController', '~> 1.7.7'
 end

 s.default_subspec = 'Lite'

 end 