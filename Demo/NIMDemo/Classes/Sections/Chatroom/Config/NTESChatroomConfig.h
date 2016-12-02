//
//  NTESChatroomConfig.h
//  NIM
//
//  Created by chris on 15/12/14.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESSessionConfig.h"

@interface NTESChatroomConfig : NTESSessionConfig

- (instancetype)initWithChatroom:(NSString *)roomId;

@end
