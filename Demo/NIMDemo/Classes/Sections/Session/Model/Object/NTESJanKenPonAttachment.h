//
//  NTESJanKenPonAttachment.h
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESCustomAttachmentDefines.h"

typedef NS_ENUM(NSInteger, CustomJanKenPonValue) {
    CustomJanKenPonValueKen     = 1,//石头
    CustomJanKenPonValueJan     = 2,//剪子
    CustomJanKenPonValuePon     = 3,//布
};

@interface NTESJanKenPonAttachment : NSObject<NIMCustomAttachment,NTESCustomAttachmentInfo>

@property (nonatomic,assign)    CustomJanKenPonValue value;

@property (nonatomic,strong)    UIImage *showCoverImage;

@end
