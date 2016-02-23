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

- (NIMKitInfo *)infoByUser:(NSString *)userId
                 inSession:(NIMSession *)session;

- (NIMKitInfo *)infoByTeam:(NSString *)teamId;

- (NIMKitInfo *)infoByUser:(NSString *)userId
               withMessage:(NIMMessage *)message;


@end
