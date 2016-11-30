//
//  M80AttributedLabelURL.h
//  M80AttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import "M80AttributedLabelDefines.h"


NS_ASSUME_NONNULL_BEGIN

@interface M80AttributedLabelURL : NSObject
@property (nonatomic,strong)                id      linkData;
@property (nonatomic,assign)                NSRange range;
@property (nonatomic,strong,nullable)       UIColor *color;

+ (M80AttributedLabelURL *)urlWithLinkData:(id)linkData
                                     range:(NSRange)range
                                     color:(nullable UIColor *)color;


+ (nullable NSArray *)detectLinks:(nullable NSString *)plainText;

+ (void)setCustomDetectMethod:(nullable M80CustomDetectLinkBlock)block;
@end


NS_ASSUME_NONNULL_END
