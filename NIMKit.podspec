Pod::Spec.new do |s| 
  s.name = 'NIMKit' 
  s.version = '1.9.1' 
  s.summary = 'Netease IM UI Kit' 
  s.homepage = 'http://netease.im' 
  s.license = { :'type' => 'Copyright', :'text' => ' Copyright 2017 Netease '} 
  s.authors = 'Netease IM Team'  
  s.source  = { :git => 'https://github.com/netease-im/NIM_iOS_UIKit.git', :tag => '1.9.1'}  
  s.platform = :ios, '8.0' 
  s.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
  s.libraries  = 'sqlite3.0', 'z', 'c++' 
  s.subspec 'Full' do |cs|	
    cs.source_files = 'NIMKit/NIMKit/**/*.{h,m}' 
    cs.dependency 'NIMKit/Core' 
    cs.dependency 'NIMSDK', '~> 4.2.0' 
  end 

  s.subspec 'Lite' do |cs|  
    cs.source_files = 'NIMKit/NIMKit/**/*.{h,m}'  
    cs.dependency 'NIMKit/Core'  
    cs.dependency 'NIMSDK_LITE', '~> 4.2.0'  
  end  

  s.subspec 'Core' do |os|     
    os.resources = 'NIMKit/Resources/*.*'   
    os.dependency 'SDWebImage', '~> 4.0.0'  
    os.dependency 'Toast', '~> 3.0'         
    os.dependency 'M80AttributedLabel', '~> 1.6.3'       
    os.dependency 'TZImagePickerController', '~> 1.9.0'  
  end   

  s.default_subspec = 'Lite'  

end 
