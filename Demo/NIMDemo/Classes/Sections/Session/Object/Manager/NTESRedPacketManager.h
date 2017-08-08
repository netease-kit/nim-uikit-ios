//
//  NTESRedPacketManager.h
//  NIM
//
//  Created by chris on 2017/7/17.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTESRedPacketManager : NSObject

+ (instancetype)sharedManager;

- (void)start;

- (void)updateUserInfo;

- (void)sendRedPacket:(NIMSession *)session;

- (void)openRedPacket:(NSString *)redpacketId
                 from:(NSString *)from
              session:(NIMSession *)session;

- (void)showRedPacketDetail:(NSString *)redPacketId;


#pragma mark - open url

- (void)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;

- (void)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString*, id> *)options;

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url;

@end
