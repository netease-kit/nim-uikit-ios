//
//  NIMAttributedLabelAttachment.h
//  NIMAttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMAttributedLabelDefines.h"

void NIMDeallocCallback(void* ref);
CGFloat NIMAscentCallback(void *ref);
CGFloat NIMDescentCallback(void *ref);
CGFloat NIMWidthCallback(void* ref);

@interface NIMAttributedLabelAttachment : NSObject
@property (nonatomic,strong)    id                  content;
@property (nonatomic,assign)    UIEdgeInsets        margin;
@property (nonatomic,assign)    NIMImageAlignment   alignment;
@property (nonatomic,assign)    CGFloat             fontAscent;
@property (nonatomic,assign)    CGFloat             fontDescent;
@property (nonatomic,assign)    CGSize              maxSize;


+ (NIMAttributedLabelAttachment *)attachmentWith: (id)content
                                          margin: (UIEdgeInsets)margin
                                       alignment: (NIMImageAlignment)alignment
                                         maxSize: (CGSize)maxSize;

- (CGSize)boxSize;

@end
