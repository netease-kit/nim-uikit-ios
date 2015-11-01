//
//  Attachment.h
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMSDK.h"
@interface Attachment : NSObject<NIMCustomAttachment>

@property (nonatomic,strong) NSString *title;

@property (nonatomic,strong) NSString *subTitle;

@end
