//
//  NIMVideoContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMVideoContentConfig.h"
#import "UIImage+NIM.h"
#import "NIMKitUIConfig.h"

@implementation NIMVideoContentConfig
- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    NIMVideoObject *videoObject = (NIMVideoObject*)[message messageObject];
    NSAssert([videoObject isKindOfClass:[NIMVideoObject class]], @"message should be video");
    
    CGFloat attachmentImageMinWidth  = (cellWidth / 4.0);
    CGFloat attachmentImageMinHeight = (cellWidth / 4.0);
    CGFloat attachmemtImageMaxWidth  = (cellWidth - 184);
    CGFloat attachmentImageMaxHeight = (cellWidth - 184);
    CGSize contentSize = CGSizeMake(attachmentImageMinWidth, attachmentImageMinHeight);
    
    
    if (!CGSizeEqualToSize(videoObject.coverSize, CGSizeZero)) {
        //有封面就直接拿封面大小
        contentSize = [UIImage nim_sizeWithImageOriginSize:videoObject.coverSize
                                                   minSize:CGSizeMake(attachmentImageMinWidth, attachmentImageMinHeight)
                                                   maxSize:CGSizeMake(attachmemtImageMaxWidth, attachmentImageMaxHeight)];
    }
    return contentSize;
}


- (NSString *)cellContent:(NIMMessage *)message
{
    return @"NIMSessionVideoContentView";
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    NIMKitBubbleConfig *config = [[NIMKitUIConfig sharedConfig] bubbleConfig:message];
    return config.contentInset;
}

@end
