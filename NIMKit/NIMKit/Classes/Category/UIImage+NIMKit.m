//
//  UIImage+NIMKit.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "UIImage+NIMKit.h"
#import "NIMInputEmoticonDefine.h"
#import "NIMKit.h"
#import "NIMKitDevice.h"
#import "NSBundle+NIMKit.h"

@implementation UIImage (NIMKit)

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
    NSInteger imageMaxWidth = imageMaxSiz.width,  imageMaxHeight = imageMaxSiz.height;
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
    NSBundle *bundle = [NIMKit sharedKit].resourceBundle;
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    if (!image) {
        image = [UIImage imageNamed:imageName];
    }
    //NSAssert(image != nil, @"nim_imageInKit return nil!");
    return image;
}

+ (UIImage *)nim_emoticonInKit:(NSString *)imageName {
    NSBundle *bundle = [NIMKit sharedKit].emoticonBundle;
    NSString *name = [NIMKit_EmojiPath stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
    if (!image) {
        image = [UIImage imageNamed:imageName];
    }
    NSAssert(image != nil, @"nim_emoticonInKit return nil!");
    return image;
}

- (UIImage *)nim_imageForAvatarUpload
{
    CGFloat pixels = [[NIMKitDevice currentDevice] suggestImagePixels];
    UIImage * image = [self nim_imageForUpload:pixels];
    return [image nim_fixOrientation];
}


#pragma mark - Private

- (UIImage *)nim_imageForUpload: (CGFloat)suggestPixels
{
    CGFloat maxPixels = 4000000;
    CGFloat maxRatio  = 3;
    
    CGFloat width = self.size.width;
    CGFloat height= self.size.height;
    
    //对于超过建议像素，且长宽比超过max ratio的图做特殊处理
    if (width * height > suggestPixels &&
        (width / height > maxRatio || height / width > maxRatio))
    {
        return [self nim_scaleWithMaxPixels:maxPixels];
    }
    else
    {
        return [self nim_scaleWithMaxPixels:suggestPixels];
    }
}

- (UIImage *)nim_scaleWithMaxPixels: (CGFloat)maxPixels
{
    CGFloat width = self.size.width;
    CGFloat height= self.size.height;
    if (width * height < maxPixels || maxPixels == 0)
    {
        return self;
    }
    CGFloat ratio = sqrt(width * height / maxPixels);
    if (fabs(ratio - 1) <= 0.01)
    {
        return self;
    }
    CGFloat newSizeWidth = width / ratio;
    CGFloat newSizeHeight= height/ ratio;
    return [self nim_scaleToSize:CGSizeMake(newSizeWidth, newSizeHeight)];
}

//内缩放，一条变等于最长边，另外一条小于等于最长边
- (UIImage *)nim_scaleToSize:(CGSize)newSize
{
    CGFloat width = self.size.width;
    CGFloat height= self.size.height;
    CGFloat newSizeWidth = newSize.width;
    CGFloat newSizeHeight= newSize.height;
    if (width <= newSizeWidth &&
        height <= newSizeHeight)
    {
        return self;
    }
    
    if (width == 0 || height == 0 || newSizeHeight == 0 || newSizeWidth == 0)
    {
        return nil;
    }
    CGSize size;
    if (width / height > newSizeWidth / newSizeHeight)
    {
        size = CGSizeMake(newSizeWidth, newSizeWidth * height / width);
    }
    else
    {
        size = CGSizeMake(newSizeHeight * width / height, newSizeHeight);
    }
    return [self nim_drawImageWithSize:size];
}

- (UIImage *)nim_drawImageWithSize: (CGSize)size
{
    CGSize drawSize = CGSizeMake(floor(size.width), floor(size.height));
    UIGraphicsBeginImageContext(drawSize);
    
    [self drawInRect:CGRectMake(0, 0, drawSize.width, drawSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)nim_fixOrientation
{
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp)
        return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (UIImage *)nim_cropedImageWithSize:(CGSize)targetSize
{
    // 裁剪两边
    CGSize sourceSize = self.size;
    CGFloat cropedWidth = sourceSize.width;
    CGFloat cropedHeight = sourceSize.height;

    if (CGSizeEqualToSize(targetSize, CGSizeZero) ||
        CGSizeEqualToSize(sourceSize, CGSizeZero) ||
        targetSize.width == 0 ||
        targetSize.height == 0)
    {
        return  self;
    }
    
    if (targetSize.width / targetSize.height > sourceSize.width / sourceSize.height)
    {
        cropedHeight = cropedWidth * (targetSize.height / targetSize.width);
    }
    else
    {
        cropedWidth = cropedHeight * (targetSize.width / targetSize.height);
    }
    
    CGRect cropRect = CGRectMake((sourceSize.width - cropedWidth) * .5f, (sourceSize.height - cropedHeight) * .5f, cropedWidth, cropedHeight);
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    // 缩放
    UIGraphicsBeginImageContextWithOptions(targetSize, YES, 0);
    [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}



@end
