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
    cs.source_files = 'NIMKit/NIMKit/Classes/*.{h,m}'
    cs.dependency 'NIMKit/Core'  
    cs.dependency 'NIMSDK_LITE', '~> 6.6.6'
	
	cs.subspec 'Global' do |global| 
	 	global.source_files  	= 'NIMKit/NIMKit/Classes/Global/**/*.{h.m}'
	end
	
	cs.subspec 'Protocols' do |protocols| 
	 	protocols.source_files  = 'NIMKit/NIMKit/Classes/Protocols/**/*.{h.m}'
	end
	
	cs.subspec 'Category' do |category| 
	 	category.source_files  	= 'NIMKit/NIMKit/Classes/Category/*.{h.m}'
	end
	
	cs.subspec 'Sections' do |sections| 
	 	sections.source_files  	= 'NIMKit/NIMKit/Classes/Sections/*.{h.m}'
		
		sections.subspec 'Common' do |common| 
		 	common.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Common/**/*.{h.m}'
		end
		
		sections.subspec 'Contact' do |contact| 
		 	contact.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Contact/**/*.{h.m}'
		end
		
		sections.subspec 'Input' do |input| 
		 	input.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Input/**/*.{h.m}'
		end
		
		sections.subspec 'Model' do |model| 
		 	model.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Model/**/*.{h.m}'
		end
		
		sections.subspec 'Session' do |session| 
		 	session.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Session/**/*.{h.m}'
		end
		
		sections.subspec 'SessionList' do |sessionList| 
		 	sessionList.source_files= 'NIMKit/NIMKit/Classes/Sections/SessionList/**/*.{h.m}'
		end
		
		sections.subspec 'Team' do |team| 
		 	team.source_files  		= 'NIMKit/NIMKit/Classes/Sections/Team/**/*.{h.m}'
		end
		
		sections.subspec 'Util' do |util| 
		 	util.source_files  		= 'NIMKit/NIMKit/Classes/Sections/Util/**/*.{h.m}'
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
