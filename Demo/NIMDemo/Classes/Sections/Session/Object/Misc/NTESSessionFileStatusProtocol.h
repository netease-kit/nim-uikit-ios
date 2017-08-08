//
//  NTESSessionFileTransDelegate.h
//  NIMDemo
//
//  Created by ght on 15-1-29.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 图片 视频等上传进度 和 语音播放等子状态回调
 */
@protocol NTESSessionFileStatusProtocol <NSObject>

@optional
- (void)updateMsgSubStatusByAudio:(NSInteger)status;

- (void)updateProgress:(float)progress;


@end
