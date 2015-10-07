//
//  NIMSDKConfig.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  NIM SDK 配置项目
 *  @discussion 配置项的所有方法必须在 NIMSDK 任一一个 sharedSDK 方法调用之前调用，否则配置无法生效
 */
@interface NIMSDKConfig : NSObject

/**
 *  返回配置项实例
 *
 *  @return 配置项
 */
+ (instancetype)sharedConfig;

/**
 *  设置 SDK 根目录
 *
 *  @param sdkDir SDK 根目录
 *  @discussion 设置该值后 SDK 产生的数据(包括聊天记录，但不包括临时文件)都将放置在这个目录下，如果不设置，所有数据将放置于 $Document/NIMSDK目录下
 */
- (void)setupSDKDir:(NSString *)sdkDir;
@end
