//
//  NIMVideoObject.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMMessageObjectProtocol.h"
/**
 *  视频实例对象
 */
@interface NIMVideoObject : NSObject<NIMMessageObject>

/**
 *  视频实例对象的初始化方法
 *
 *  @param sourcePath 视频的文件路径
 *
 *  @return 视频实例对象
 */
- (instancetype)initWithSourcePath:(NSString *)sourcePath;

/**
 *  视频展示名
 */
@property (nonatomic, copy) NSString * displayName;
/**
 *  视频MD5
 */
@property (nonatomic, copy, readonly) NSString * md5;



/**
 *  视频的本地路径
 *  @discussion 目前SDK并不提供视频下载功能,但是建议APP使用这个path作为视频的下载地址,以便后期SDK提供缓存清理等功能
 */
@property (nonatomic, copy, readonly) NSString * path;

/**
 *  视频的远程路径
 */
@property (nonatomic, copy, readonly) NSString * url;

/**
 *  视频封面的远程路径
 */
@property (nonatomic, copy, readonly) NSString * coverUrl;

/**
 *  视频封面的本地路径
 */
@property (nonatomic, copy, readonly) NSString * coverPath;

/**
 *  封面尺寸
 */
@property (nonatomic, assign, readonly) CGSize coverSize;

/**
 *  视频时长，毫秒为单位
 */
@property (nonatomic, assign, readonly) NSInteger duration;

/**
 *  文件大小
 */
@property (nonatomic, assign, readonly) long long fileLength;



@end
