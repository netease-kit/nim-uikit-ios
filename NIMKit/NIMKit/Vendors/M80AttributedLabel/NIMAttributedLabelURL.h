//
//  NIMAttributedLabelURL.h
//  NIMAttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMAttributedLabelDefines.h"

@interface NIMAttributedLabelURL : NSObject
@property (nonatomic,strong)    id      linkData;
@property (nonatomic,assign)    NSRange range;
@property (nonatomic,strong)    UIColor *color;

+ (NIMAttributedLabelURL *)urlWithLinkData: (id)linkData
                                     range: (NSRange)range
                                     color: (UIColor *)color;


+ (NSArray *)detectLinks: (NSString *)plainText;

+ (void)setCustomDetectMethod:(NIMCustomDetectLinkBlock)block;
@end


