Pod::Spec.new do |s| 
  s.name = 'NIMKit' 
  s.version = '2.12.0' 
  s.summary = 'Netease IM UI Kit' 
  s.homepage = 'http://netease.im' 
  s.license = { :'type' => 'Copyright', :'text' => ' Copyright 2019 Netease '} 
  s.authors = 'Netease IM Team'  
  s.source  = { :git => 'https://github.com/netease-im/NIM_iOS_UIKit.git', :tag => '2.12.0'}  
  s.platform = :ios, '8.0' 
  s.frameworks = 'CoreText', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'CoreMedia' , 'VideoToolbox' 
  s.libraries  = 'sqlite3.0', 'z', 'c++' 


  s.subspec 'Full' do |cs|
    cs.dependency 'NIMKit/Sources'	
    cs.dependency 'NIMKit/Core' 
    cs.dependency 'NIMSDK', '~> 6.7.0' 
  end 

  s.subspec 'Lite' do |cs|  
    cs.dependency 'NIMKit/Sources'
    cs.dependency 'NIMKit/Core'  
    cs.dependency 'NIMSDK_LITE', '~> 6.7.0'
  end






  # s.subspec 'FullFree' do |cs|
  #   cs.dependency 'NIMKit/Sources'
  #   cs.dependency 'NIMKit/CoreFree'
  #   cs.dependency 'NIMSDK', '~> 6.7.0'
  # end
  #
  # s.subspec 'LiteFree' do |cs|
  #   cs.dependency 'NIMKit/Sources'
  #   cs.dependency 'NIMKit/CoreFree'
  #   cs.dependency 'NIMSDK_LITE', '~> 6.7.0'
  # end







  s.subspec 'Core' do |os|     
    os.resources = 'NIMKit/Resources/*.*'   
    os.dependency 'SDWebImage', '~> 5.0.6'
    os.dependency 'FLAnimatedImage', '~> 1.0.12'
    os.dependency 'Toast', '~> 3.0'         
    os.dependency 'M80AttributedLabel', '~> 1.6.3'       
    os.dependency 'TZImagePickerController', '~> 3.0.7'  
  end  

  # s.subspec 'CoreFree' do |os|
  #   os.resources = 'NIMKit/Resources/*.*'
  #   os.dependency 'SDWebImage'
  #   os.dependency 'FLAnimatedImage'
  #   os.dependency 'Toast'
  #   os.dependency 'M80AttributedLabel'
  #   os.dependency 'TZImagePickerController'
  # end
  
  
  
  

  s.subspec 'Sources' do |cs|
	   	cs.source_files = 'NIMKit/NIMKit/Classes/*.{h,m}'
			cs.subspec 'Global' do |gs| 
			 	gs.source_files  = 'NIMKit/NIMKit/Classes/Global/**/*.{h,m}'
			end
		
			cs.subspec 'Protocols' do |ps| 
			 	ps.source_files  = 'NIMKit/NIMKit/Classes/Protocols/**/*.{h,m}'
			end
			
			cs.subspec 'Category' do |es| 
			 	es.source_files  	= 'NIMKit/NIMKit/Classes/Category/**/*.{h,m}'
			end
		
			cs.subspec 'Sections' do |ps|				
				ps.subspec 'Common' do |cs| 
				 	cs.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Common/**/*.{h,m}'
				end
				
				ps.subspec 'Contact' do |cs| 
				 	cs.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Contact/**/*.{h,m}'
				end
				
				ps.subspec 'Input' do |cs| 
				 	cs.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Input/**/*.{h,m}'
				end
				
				ps.subspec 'Model' do |cs| 
				 	cs.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Model/**/*.{h,m}'
				end
				
				ps.subspec 'Session' do |cs| 
				 	cs.source_files  	= 'NIMKit/NIMKit/Classes/Sections/Session/**/*.{h,m}'
				end
				
				ps.subspec 'SessionList' do |cs| 
				 	cs.source_files        = 'NIMKit/NIMKit/Classes/Sections/SessionList/**/*.{h,m}'
				end
				
				ps.subspec 'Team' do |cs| 
				 	cs.source_files        = 'NIMKit/NIMKit/Classes/Sections/Team/**/*.{h,m}'
				end
				
				ps.subspec 'Util' do |cs| 
				 	cs.source_files        = 'NIMKit/NIMKit/Classes/Sections/Util/**/*.{h,m}'
				end
			end
	end

  s.default_subspec = 'Lite'  

end 
