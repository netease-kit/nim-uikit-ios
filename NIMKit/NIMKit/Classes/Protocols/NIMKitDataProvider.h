//
//  NIMKitDataProvider.h
//  NIMKit
//
//  Created by amao on 8/13/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NIMSession;
@class NIMKitInfo;
@class NIMKitInfoFetchOption;

@protocol NIMKitDataProvider <NSObject>

@optional

/**
 *  上层提供用户信息的接口
 *
 *  @param userId  用户ID
 *  @param option  获取选项
 *
 *  @return 用户信息
 */
- (NIMKitInfo *)infoByUser:(NSString *)userId
                    option:(NIMKitInfoFetchOption *)option;


/**
 *  上层提供群组信息的接口
 *
 *  @param teamId 群组ID
 *  @param option 获取选项
 *
 *  @return 群组信息
 */
- (NIMKitInfo *)infoByTeam:(NSString *)teamId
                    option:(NIMKitInfoFetchOption *)option;

@end
