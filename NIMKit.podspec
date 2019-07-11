Pod::Spec.new do |s| 
  s.name = 'NIMKit' 
  s.version = '2.11.13' 
  s.summary = 'Netease IM UI Kit' 
  s.homepage = 'http://netease.im' 
  s.license = { :'type' => 'Copyright', :'text' => ' Copyright 2019 Netease '} 
  s.authors = 'Netease IM Team'  
  s.source  = { :git => 'https://github.com/netease-im/NIM_iOS_UIKit.git', :tag => '2.11.13'}  
  s.platform = :ios, '8.0' 
  s.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
  s.libraries  = 'sqlite3.0', 'z', 'c++' 
  s.subspec 'Full' do |cs|	
    cs.source_files = 'NIMKit/NIMKit/**/*.{h,m}' 
    cs.dependency 'NIMKit/Core' 
    cs.dependency 'NIMSDK', '~> 6.6.6' 
  end 

  s.subspec 'Lite' do |cs|  
    cs.source_files = 'NIMKit/NIMKit/Class/*.{h,m}'
    cs.dependency 'NIMKit/Core'  
    cs.dependency 'NIMSDK_LITE', '~> 6.6.6'
	
	cs.subspec 'Global' do |global| 
	 	global.source_files  	= 'NIMKit/NIMKit/Class/Global/*.{h.m}'
	end
	
	cs.subspec 'Protocols' do |Protocols| 
	 	Protocols.source_files  = 'NIMKit/NIMKit/Class/Protocols/*.{h.m}'
	end
	
	cs.subspec 'Category' do |Category| 
	 	Category.source_files  	= 'NIMKit/NIMKit/Class/Category/*.{h.m}'
	end
	
	cs.subspec 'Sections' do |Sections| 
	 	Sections.source_files  	= 'NIMKit/NIMKit/Class/Sections/*.{h.m}'
		
		Sections.subspec 'Common' do |Common| 
		 	Common.source_files  	= 'NIMKit/NIMKit/Class/Sections/Common/**/*.{h.m}'
		end
		
		Sections.subspec 'Contact' do |Contact| 
		 	Contact.source_files  	= 'NIMKit/NIMKit/Class/Sections/Contact/**/*.{h.m}'
		end
		
		Sections.subspec 'Input' do |Input| 
		 	Input.source_files  	= 'NIMKit/NIMKit/Class/Sections/Input/**/*.{h.m}'
		end
		
		Sections.subspec 'Model' do |Model| 
		 	Model.source_files  	= 'NIMKit/NIMKit/Class/Sections/Model/**/*.{h.m}'
		end
		
		Sections.subspec 'Session' do |Session| 
		 	Session.source_files  	= 'NIMKit/NIMKit/Class/Sections/Session/**/*.{h.m}'
		end
		
		Sections.subspec 'SessionList' do |SessionList| 
		 	SessionList.source_files= 'NIMKit/NIMKit/Class/Sections/SessionList/**/*.{h.m}'
		end
		
		Sections.subspec 'Team' do |Team| 
		 	Team.source_files  		= 'NIMKit/NIMKit/Class/Sections/Team/**/*.{h.m}'
		end
		
		Sections.subspec 'Util' do |Util| 
		 	Util.source_files  		= 'NIMKit/NIMKit/Class/Sections/Util/**/*.{h.m}'
		end
	end
	
  end  

  s.subspec 'Core' do |os|     
    os.resources = 'NIMKit/Resources/*.*'   
    os.dependency 'SDWebImage', '~> 4.4.6'  
    os.dependency 'Toast', '~> 3.0'         
    os.dependency 'M80AttributedLabel', '~> 1.6.3'       
    os.dependency 'TZImagePickerController', '~> 3.0.7'  
  end   

  s.default_subspec = 'Lite'  

end 
