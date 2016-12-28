//
//  SnapchatAttachment.m
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESSnapchatAttachment.h"
#import "NTESFileLocationHelper.h"
#import "NSData+NTES.h"
#import "NTESSessionUtil.h"

@interface NTESSnapchatAttachment()

@property (nonatomic,assign) BOOL isFromMe;

@end

@implementation NTESSnapchatAttachment

- (void)setImage:(UIImage *)image
{
    NSData *data = UIImageJPEGRepresentation(image, 0.7);
    NSString *md5= [data MD5String];
    self.md5 = md5;
    
    [data writeToFile:[self filepath]
           atomically:YES];
}

- (void)setImageFilePath:(NSString *)path
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSData *data = [NSData dataWithContentsOfFile:path];
        self.md5 =  [data MD5String];
        [data writeToFile:[self filepath]
               atomically:YES];
     }
}

- (void)setIsFired:(BOOL)isFired{
    if (_isFired != isFired) {
        _isFired = isFired;
        [self updateCover];
    }
}


- (NSString *)filepath
{
    NSString *filename = [_md5 stringByAppendingFormat:@".%@",ImageExt];
    return [NTESFileLocationHelper filepathForImage:filename];
}


- (NSString *)cellContent:(NIMMessage *)message{
    return @"NTESSessionSnapchatContentView";
}

- (CGSize)contentSize:(NIMMessage *)message cellWidth:(CGFloat)width{
    self.isFromMe = message.isOutgoingMsg;
    CGSize size = self.showCoverImage.size;
    CGFloat customSnapMessageImageRightToText = 5;
    return CGSizeMake(size.width + customSnapMessageImageRightToText, size.height);
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    CGFloat bubblePaddingForImage    = 3.f;
    CGFloat bubbleArrowWidthForImage = -4.f;
    if (message.isOutgoingMsg) {
        return  UIEdgeInsetsMake(bubblePaddingForImage,bubblePaddingForImage,bubblePaddingForImage,bubblePaddingForImage + bubbleArrowWidthForImage);
    }else{
        return  UIEdgeInsetsMake(bubblePaddingForImage,bubblePaddingForImage + bubbleArrowWidthForImage, bubblePaddingForImage,bubblePaddingForImage);
    }
}

- (void)setIsFromMe:(BOOL)isFromMe{
    if (_isFromMe != isFromMe) {
        _isFromMe = isFromMe;
        [self updateCover];
    }
}

#pragma NIMCustomAttachment
- (NSString *)encodeAttachment
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [dict setObject:@(CustomMessageTypeSnapchat) forKey:CMType];
    [data setObject:_md5?_md5:@"" forKey:CMMD5];
    [data setObject:@(_isFired) forKey:CMFIRE];
    if ([_url length])
    {
        [data setObject:_url forKey:CMURL];
    }
    [dict setObject:data forKey:CMData];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:0
                                                     error:nil];
    
    return [[NSString alloc] initWithData:jsonData
                                 encoding:NSUTF8StringEncoding];
}


#pragma mark - 实现文件上传需要接口
- (BOOL)attachmentNeedsUpload
{
    return [_url length] == 0;
}

- (NSString *)attachmentPathForUploading
{
    return [self filepath];
}

- (void)updateAttachmentURL:(NSString *)urlString
{
    self.url = urlString;
}


#pragma mark - Private
- (void)updateCover{
    UIImage *image;
    if (!self.isFromMe) {
        if (self.isFired) {
            image = [UIImage imageNamed:@"session_snapchat_other_readed"];
        }else{
            image = [UIImage imageNamed:@"session_snapchat_other_unread"];
        }
    }else{
        if (self.isFired) {
            image = [UIImage imageNamed:@"session_snapchat_self_readed"];
        }else{
            image = [UIImage imageNamed:@"session_snapchat_self_unread"];
        }
    }
    self.showCoverImage = image;
}

- (UIImage *)showCoverImage
{
    if (_showCoverImage == nil)
    {
        [self updateCover];
    }
    return _showCoverImage;
}

#pragma mark - https
- (NSString *)url
{
    return [_url length] ?
    [[[NIMSDK sharedSDK] resourceManager] convertHttpToHttps:_url] : nil;
}

@end
