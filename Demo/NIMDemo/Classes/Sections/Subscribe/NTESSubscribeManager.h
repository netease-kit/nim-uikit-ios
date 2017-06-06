//
//  NTESSubscribeManager.h
//  NIM
//
//  Created by chris on 2017/4/5.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESService.h"

@interface NTESSubscribeManager : NSObject

+ (instancetype)sharedManager;

- (void)start;

- (NSDictionary<NIMSubscribeEvent *, NSString *> *)eventsForType:(NSInteger)type;

- (void)subscribeTempUserOnlineState:(NSString *)userId;

- (void)unsubscribeTempUserOnlineState:(NSString *)userId;

@end
