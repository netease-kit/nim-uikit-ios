//
//  NTESChatroomMaker.h
//  NIM
//
//  Created by chris on 16/1/19.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTESChatroomMaker : NSObject

+ (nullable NIMChatroom *)makeChatroom:(nonnull NSDictionary *)dict;

@end
