//
//  NIMRTSRecordingInfo.h
//  NIMLib
//
//  Created by Netease on 15/7/24.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMRTSManagerProtocol.h"

/**
 *  实时会话录制服务信息
 */
@interface NIMRTSRecordingInfo : NSObject

/**
 *  录制文件的服务类型
 */
@property (nonatomic, readonly) NIMRTSService service;

/**
 *  录制存储服务器地址
 */
@property (nonatomic, readonly, copy) NSString *serverAddress;

/**
 *  录制存储文件名
 */
@property (nonatomic, readonly, copy) NSString *recordFileName;

@end
