//
//  SPayClientPayAppPayManager.h
//  SPaySDK
//
//  Created by wongfish on 15/7/21.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPayClientHeaders.h"





@interface SPayClientPayAppPayManager : NSObject


+ (SPayClientPayAppPayManager*)sharedInstance;


/**
 * 支付宝APP支付
 *
 *  @param tokenId   授权码
 *  @param tradeType 支付类型
 *  @param success   <#success description#>
 *  @param failure   <#failure description#>
 */
- (void)alipayAppPay:(NSString*)tokenId
           tradeType:(NSString*)tradeType
             success:(SPayPayFinishBlock)success
             failure:(void (^)(NSString *message))failure;

/**
 *  微信APP支付
 *
 *  @param tokenId   授权码
 *  @param tradeType 支付类型（pay.weixin.app）
 *  @param appid     微信appid
 *  @param success   <#success description#>
 *  @param failure   <#failure description#>
 */
- (void)wechatAppPay:(NSString*)tokenId
           tradeType:(NSString*)tradeType
               appid:(NSString*)appid
             success:(SPayPayFinishBlock)success
             failure:(SPayPayFailureBlock)failure;


#pragma mark - 使用微信APP支付和支付宝APP支付，必须实现两种代理

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;

- (BOOL)application:(UIApplication *)application
      handleOpenURL:(NSURL *)url;


- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString*, id> *)options NS_AVAILABLE_IOS(9_0); // no equiv. notification. return NO if the application can't open for some reason

- (void)applicationWillEnterForeground:(UIApplication *)application;
@end
