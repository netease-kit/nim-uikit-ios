//
//  Attachment.h
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
@interface NTESAttachment : NSObject<NIMCustomAttachment>

@property (nonatomic,copy) NSString *title;

@property (nonatomic,copy) NSString *subTitle;

@end
