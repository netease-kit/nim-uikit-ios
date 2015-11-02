//
//  NIMVideoContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMVideoContentConfig.h"
#import "UIImage+NIM.h"

@implementation NIMVideoContentConfig
- (CGSize)contentSize:(CGFloat)cellWidth
{
    CGFloat attachmentImageMinWidth  = (cellWidth / 4.0);
    CGFloat attachmentImageMinHeight = (cellWidth / 4.0);
    CGFloat attachmemtImageMaxWidth  = (cellWidth - 184);
    CGFloat attachmentImageMaxHeight = (cellWidth - 184);
    CGSize contentSize = CGSizeMake(attachmentImageMinWidth, attachmentImageMinHeight);
    
    NIMVideoObject *videoObject = (NIMVideoObject*)[self.message messageObject];
    if (!CGSizeEqualToSize(videoObject.coverSize, CGSizeZero)) {
        //有封面就直接拿封面大小
        contentSize = [UIImage nim_sizeWithImageOriginSize:videoObject.coverSize
                                                   minSize:CGSizeMake(attachmentImageMinWidth, attachmentImageMinHeight)
                                                   maxSize:CGSizeMake(attachmemtImageMaxWidth, attachmentImageMaxHeight)];
    }
    return contentSize;
}

- (NSString *)cellContent
{
    return @"NIMSessionVideoContentView";
}

- (UIEdgeInsets)contentViewInsets
{
    return self.message.isOutgoingMsg ? UIEdgeInsetsMake(3,3,3,8) : UIEdgeInsetsMake(3,8,3,3);
}
@end
