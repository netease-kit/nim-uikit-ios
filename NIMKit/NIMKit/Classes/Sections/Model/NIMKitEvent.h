//
//  NIMKitEvent.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMMessageModel.h"

@interface NIMKitEvent : NSObject

@property (nonatomic,copy) NSString *eventName;

@property (nonatomic,strong) NIMMessageModel *messageModel;

@property (nonatomic,strong) id data;

@end




extern NSString *const NIMKitEventNameTapContent;
extern NSString *const NIMKitEventNameTapLabelLink;
extern NSString *const NIMKitEventNameTapAudio;
extern NSString *const NIMKitEventNameTapRobotLink;
extern NSString *const NIMKitEventNameTapRobotBlock;
extern NSString *const NIMKitEventNameTapRobotContinueSession;
