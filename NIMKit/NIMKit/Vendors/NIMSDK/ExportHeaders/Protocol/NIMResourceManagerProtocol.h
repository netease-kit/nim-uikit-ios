//
//  NIMResourceManager.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  上传Block
 *
 *  @param urlString 上传后得到的URL,失败时为nil
 *  @param error     错误信息,成功时为nil
 */
typedef void(^NIMUploadCompleteBlock)(NSString *urlString,NSError *error);

/**
 *  上传/下载进度Block
 *
 *  @param progress 进度 0%-100%
 */
typedef void(^NIMHttpProgressBlock)(CGFloat progress);


/**
 *  下载Block
 *
 *  @param error 错误信息,成功时为nil
 */
typedef void(^NIMDownloadCompleteBlock)(NSError *error);


/**
 *  资源管理
 */
@protocol NIMResourceManager <NSObject>

/**
 *  上传文件
 *
 *  @param filepath   上传文件路径
 *  @param progress   进度Block
 *  @param completion 上传Block
 */
- (void)upload:(NSString *)filepath
      progress:(NIMHttpProgressBlock)progress
    completion:(NIMUploadCompleteBlock)completion;

/**
 *  下载文件
 *
 *  @param urlString  下载的RL
 *  @param filepath   下载路径
 *  @param progress   进度Block
 *  @param completion 完成Block
 */
- (void)download:(NSString *)urlString
        filepath:(NSString *)filepath
        progress:(NIMHttpProgressBlock)progress
      completion:(NIMDownloadCompleteBlock)completion;

/**
 *  取消上传/下载任务
 *
 *  @param filepath 上传/下载任务对应的文件路径
 *  @discussion 如果同一个文件同时上传或者下载(理论上不应该出现这种情况),ResourceManager会进行任务合并,基于这个原则cancel的操作对象是某个文件对应的所有的上传/下载任务
 */
- (void)cancelTask:(NSString *)filepath;

@end
