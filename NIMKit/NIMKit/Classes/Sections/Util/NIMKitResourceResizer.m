//
//  YXNOSResizer.m
//  NIM
//
//  Created by amao on 11/19/14.
//  Copyright (c) 2014 Netease. All rights reserved.
//

#import "NIMKitResourceResizer.h"

@interface NIMKitResourceResizer ()
@property (nonatomic,assign)    CGFloat   scale;
@end

@implementation NIMKitResourceResizer

+ (instancetype)sharedResizer
{
    static NIMKitResourceResizer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMKitResourceResizer alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _scale = [[UIScreen mainScreen] scale];
    }
    return self;
}


- (NSString *)resize:(NSString *)mode
               width:(CGFloat)width
              height:(CGFloat)height
{
    CGSize size = [self resizeWidth:width height:height];
    return [NSString stringWithFormat:@"%ld%@%ld",(long)(size.width),mode,(long)(size.height)];
}


- (CGSize)resizeWidth:(CGFloat)width
               height:(CGFloat)height{
    return CGSizeMake(width * _scale,height * _scale);
}

- (NSString *)imageThumbnailURL:(NSString *)urlString
{
    return [urlString length] ? [urlString stringByAppendingFormat:@"?imageView&thumbnail=%@",NIMKitNOSZ(75, 75)] : urlString;
}

- (NSString *)videoThumbnailURL:(NSString *)urlString
{
    return [urlString length] ? [urlString stringByAppendingString:@"?vframe=1"] : urlString;
}


@end
