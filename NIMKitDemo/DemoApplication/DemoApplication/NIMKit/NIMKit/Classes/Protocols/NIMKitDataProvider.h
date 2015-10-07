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

@protocol NIMKitDataProvider <NSObject>

@optional
/**
 *  上层提供用户信息的方法
 *
 *  @param userId 用户Id
 *
 *  @return 用户信息
 */
- (NIMKitInfo *)infoByUser:(NSString *)userId;


/**
 *  上层提供群组信息的方法
 *
 *  @param teamId 群组id
 *
 *  @return 群组信息
 */
- (NIMKitInfo *)infoByTeam:(NSString *)teamId;


@end
