//
//  NIMImageObject.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMMessageObjectProtocol.h"
#import <UIKit/UIKit.h>
/**
 *  图片格式
 */
typedef enum : NSUInteger
{
    /**
     *  Jpeg格式
     */
    NIMImageFormatJPEG,
    /**
     *  Png格式
     */
    NIMImageFormatPNG,
} NIMImageFormat;

/**
 *  图片选项
 */
@interface NIMImageOption : NSObject
/**
*  压缩参数默认为0,可传入0.0-1.0的值,如果值为0或者不合法参数时按照0.5进行压缩
*/
@property (nonatomic,assign)    CGFloat compressQuality;

/**
 *  图片压缩格式,默认为JPEG
 */
@property (nonatomic,assign)    NIMImageFormat format;

@end

/**
 *  图片实例对象
 */
@interface NIMImageObject : NSObject<NIMMessageObject>

/**
 *  图片实例对象初始化方法
 *
 *  @param image 要发送的图片
 *
 *  @return 图片实例对象
 */
- (instancetype)initWithImage:(UIImage*)image;

/**
 *  文件展示名
 */
@property (nonatomic, copy) NSString * displayName;

/**
 *  图片本地路径
 *  @discussion 目前SDK没有提供下载大图的方法,但推荐使用这个地址作为图片下载地址,APP可以使用自己的下载类或者SDWebImage做图片的下载和管理
 */
@property (nonatomic, copy, readonly) NSString * path;

/**
 *  缩略图本地路径
 */
@property (nonatomic, copy, readonly) NSString * thumbPath;


/**
 *  图片远程路径
 */
@property (nonatomic, copy, readonly) NSString * url;

/**
 *  缩略图远程路径
 */
@property (nonatomic, copy, readonly) NSString * thumbUrl;

/**
 *  图片尺寸
 */
@property (nonatomic, assign, readonly) CGSize size;

/**
 *  图片选项
 */
@property (nonatomic ,strong) NIMImageOption *option;

/**
 *  文件大小
 */
@property (nonatomic, assign, readonly) long long fileLength;


@end