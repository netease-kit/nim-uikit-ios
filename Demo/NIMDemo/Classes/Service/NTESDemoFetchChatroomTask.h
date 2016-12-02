//
//  NTESDemoFetchChatroomTask.h
//  NIM
//
//  Created by amao on 1/20/16.
//  Copyright © 2016 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESDemoServiceTask.h"

typedef void (^NTESChatroomListHandler)(NSError *error, NSArray<NIMChatroom *> *chatroom);


@interface NTESDemoFetchChatroomTask : NSObject<NTESDemoServiceTask>
@property (nonatomic,copy)  NTESChatroomListHandler handler;
@end
