Pod::Spec.new do |s| 
  s.name = 'NIMKit' 
  s.version = '$version' 
  s.summary = 'Netease IM UI Kit' 
  s.homepage = 'http://netease.im' 
  s.license = { :'type' => 'Copyright', :'text' => ' Copyright 2017 Netease '} 
  s.authors = 'Netease IM Team'  
  s.source  = { :git => '$git_url', :tag => '#{s.version}'}  
  s.platform = :ios, '8.0' 
  s.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
  s.libraries  = 'sqlite3.0', 'z', 'c++' 
  s.subspec 'Full' do |cs|	
    cs.source_files = 'NIMKit/NIMKit/**/*.{h,m}' 
    cs.dependency 'NIMKit/Core' 
    cs.dependency 'NIMSDK', '~> $version' 
  end 

  s.subspec 'Lite' do |cs|  
    cs.source_files = 'NIMKit/NIMKit/**/*.{h,m}'  
    cs.dependency 'NIMKit/Core'  
    cs.dependency 'NIMSDK_LITE', '~> $version'  
  end  

  s.subspec 'Core' do |os|     
    os.resources = 'NIMKit/Resources/*.*'   
    os.dependency 'SDWebImage', '~> 3.8.2'  
    os.dependency 'Toast', '~> 3.0'         
    os.dependency 'SVProgressHUD', '~> 2.0.3'            
    os.dependency 'M80AttributedLabel', '~> 1.6.3'       
    os.dependency 'TZImagePickerController', '~> 1.7.7'  
  end   

  s.default_subspec = 'Lite'  

 end Pod::Spec.new do |s|s.name = "NIMSDK"s.version = "${version}"s.summary = "Netease IM SDK"s.homepage = "http://netease.im"s.license = { :"type" => "Copyright", :"text" => " Copyright 2017 Netease "}s.authors = "Netease IM Team"s.source = { :git => "$git_url", :tag => "#{s.version}"}s.platform = :ios, '7.0's.vendored_libraries  = '**/Libs/*.a's.vendored_frameworks = '**/NIMSDK.framework','**/NIMAVChat.framework's.frameworks = 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox's.libraries = 'sqlite3.0', 'z', 'c++'endPod::Spec.new do |s|s.name = "NIMSDK_LITE"s.version = "$version"s.summary = "Netease AV Chat SDK"s.homepage = "http://netease.im"s.license = { :"type" => "Copyright", :"text" => " Copyright 2017 Netease "}s.authors = "Netease IM Team"s.source = { :git => "$git_url", :tag => "#{s.version}"}s.platform = :ios, '7.0's.vendored_libraries  = '**/Libs/*.a's.vendored_frameworks = '**/NIMSDK.framework's.frameworks = 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox's.libraries = 'sqlite3.0', 'z', 'c++'endPod::Spec.new do |s|s.name = 'NIMKit's.version = '$version's.summary = 'Netease IM UI Kit's.homepage = 'http://netease.im's.license = { :'type' => 'Copyright', :'text' => ' Copyright 2017 Netease '}s.authors = 'Netease IM Team's.source  = { :git => '$git_url', :tag => '#{s.version}'}s.platform = :ios, '8.0's.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox's.libraries  = 'sqlite3.0', 'z', 'c++'s.subspec 'Full' do |cs|cs.source_files = 'NIMKit/NIMKit/**/*.{h,m}'cs.dependency 'NIMKit/Core'cs.dependency 'NIMSDK', '~> $version'ends.subspec 'Lite' do |cs|cs.source_files = 'NIMKit/NIMKit/**/*.{h,m}'cs.dependency 'NIMKit/Core'cs.dependency 'NIMSDK_LITE', '~> $version'ends.subspec 'Core' do |os|os.resources = 'NIMKit/Resources/*.*'os.dependency 'SDWebImage', '~> 3.8.2'os.dependency 'Toast', '~> 3.0'os.dependency 'SVProgressHUD', '~> 2.0.3'os.dependency 'M80AttributedLabel', '~> 1.6.3'os.dependency 'TZImagePickerController', '~> 1.7.7'ends.default_subspec = 'Lite'end
