//
//  UIImage+NIM.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "UIImage+NIM.h"
#import "NIMInputEmoticonDefine.h"
#import "NIMKit.h"

@implementation UIImage (NIM)

+ (UIImage *)nim_fetchImage:(NSString *)imageNameOrPath{
    UIImage *image = [UIImage imageNamed:imageNameOrPath];
    if (!image) {
        image = [UIImage imageWithContentsOfFile:imageNameOrPath];
    }
    return image;
}


+ (UIImage *)nim_fetchChartlet:(NSString *)imageName chartletId:(NSString *)chartletId{
    if ([chartletId isEqualToString:NIMKit_EmojiCatalog]) {
        return [UIImage imageNamed:imageName];
    }
    NSString *subDirectory = [NSString stringWithFormat:@"%@/%@/%@",NIMKit_ChartletChartletCatalogPath,chartletId,NIMKit_ChartletChartletCatalogContentPath];
    //先拿2倍图
    NSString *doubleImage  = [imageName stringByAppendingString:@"@2x"];
    NSString *tribleImage  = [imageName stringByAppendingString:@"@3x"];
    NSString *bundlePath   = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:subDirectory];
    NSString *path = nil;
    
    NSArray *array = [NSBundle pathsForResourcesOfType:nil inDirectory:bundlePath];
    NSString *fileExt = [[array.firstObject lastPathComponent] pathExtension];
    if ([UIScreen mainScreen].scale == 3.0) {
        path = [NSBundle pathForResource:tribleImage ofType:fileExt inDirectory:bundlePath];
    }
    path = path ? path : [NSBundle pathForResource:doubleImage ofType:fileExt inDirectory:bundlePath]; //取二倍图
    path = path ? path : [NSBundle pathForResource:imageName ofType:fileExt inDirectory:bundlePath]; //实在没了就去取一倍图
    return [UIImage imageWithContentsOfFile:path];
}


+ (CGSize)nim_sizeWithImageOriginSize:(CGSize)originSize
                              minSize:(CGSize)imageMinSize
                              maxSize:(CGSize)imageMaxSiz{
    CGSize size;
    NSInteger imageWidth = originSize.width ,imageHeight = originSize.height;
    NSInteger imageMinWidth = imageMinSize.width, imageMinHeight = imageMinSize.height;
    NSInteger imageMaxWidth = imageMaxSiz.width, imageMaxHeight = imageMaxSiz.height;
    if (imageWidth > imageHeight) //宽图
    {
        size.height = imageMinHeight;  //高度取最小高度
        size.width = imageWidth * imageMinHeight / imageHeight;
        if (size.width > imageMaxWidth)
        {
            size.width = imageMaxWidth;
        }
    }
    else if(imageWidth < imageHeight)//高图
    {
        size.width = imageMinWidth;
        size.height = imageHeight *imageMinWidth / imageWidth;
        if (size.height > imageMaxHeight)
        {
            size.height = imageMaxHeight;
        }
    }
    else//方图
    {
        if (imageWidth > imageMaxWidth)
        {
            size.width = imageMaxWidth;
            size.height = imageMaxHeight;
        }
        else if(imageWidth > imageMinWidth)
        {
            size.width = imageWidth;
            size.height = imageHeight;
        }
        else
        {
            size.width = imageMinWidth;
            size.height = imageMinHeight;
        }
    }
    return size;
}


+ (UIImage *)nim_imageInKit:(NSString *)imageName{
    NSString *name = [[[NIMKit sharedKit] bundleName] stringByAppendingPathComponent:imageName];
    return [UIImage imageNamed:name];
}


@end
