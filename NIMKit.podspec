Pod::Spec.new do |s| 
 s.name = 'NIMKit' 
 s.version = '$version' 
 s.summary = 'Netease IM UI Kit' 
 s.homepage = 'http://netease.im' 
 s.license = { :'type' => 'Copyright', :'text' => ' Copyright 2017 Netease '} 
 s.authors = 'Netease IM Team' 
 s.source = { :git => '$git_url', :tag => '#{s.version}'} 
 s.platform = :ios, '8.0' 
 s.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
 s.libraries = 'sqlite3.0', 'z', 'c++' 
 s.subspec 'Full' do |cs| 
 \