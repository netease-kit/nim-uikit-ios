//
//  NTESJanKenPonAttachment.m
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESJanKenPonAttachment.h"
#import "NTESSessionUtil.h"

@implementation NTESJanKenPonAttachment

- (NSString *)encodeAttachment
{
    NSDictionary *dict = @{CMType : @(CustomMessageTypeJanKenPon),
                           CMData : @{CMValue:@(self.value)}};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:0
                                                     error:nil];
    NSString *content = nil;
    if (data) {
        content = [[NSString alloc] initWithData:data
                                        encoding:NSUTF8StringEncoding];
    }
    return content;
}


- (NSString *)cellContent:(NIMMessage *)message{
    return @"NTESSessionJankenponContentView";
}

- (CGSize)contentSize:(NIMMessage *)message cellWidth:(CGFloat)width{

    return self.showCoverImage.size;
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    if (message.session.sessionType == NIMSessionTypeChatroom)
    {
        CGFloat bubbleMarginTopForImage  = 15.f;
        CGFloat bubbleMarginLeftForImage = 12.f;
        return  UIEdgeInsetsMake(bubbleMarginTopForImage,bubbleMarginLeftForImage,0,0);
    }
    else
    {
        CGFloat bubbleMarginForImage    = 3.f;
        CGFloat bubbleArrowWidthForImage = 5.f;
        if (message.isOutgoingMsg) {
            return  UIEdgeInsetsMake(bubbleMarginForImage,bubbleMarginForImage,bubbleMarginForImage,bubbleMarginForImage + bubbleArrowWidthForImage);
        }else{
            return  UIEdgeInsetsMake(bubbleMarginForImage,bubbleMarginForImage + bubbleArrowWidthForImage, bubbleMarginForImage,bubbleMarginForImage);
        }
    }
}

- (UIImage *)showCoverImage
{
    if (_showCoverImage == nil)
    {
        UIImage *image;
        switch (self.value) {
            case CustomJanKenPonValueJan:
                image    = [UIImage imageNamed:@"custom_msg_jan"];
                break;
            case CustomJanKenPonValueKen:
                image    = [UIImage imageNamed:@"custom_msg_ken"];
                break;
            case CustomJanKenPonValuePon:
                image    = [UIImage imageNamed:@"custom_msg_pon"];
                break;
            default:
                break;
        }
        _showCoverImage = image;
    }
    return _showCoverImage;
}


@end
