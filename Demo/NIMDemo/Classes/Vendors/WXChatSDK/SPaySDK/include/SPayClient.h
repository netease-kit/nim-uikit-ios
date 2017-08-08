//
//  SPayClient.h
//  SPaySDK
//
//  Created by wongfish on 15/6/16.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SPayClientHeaders.h"
#import "SPayClientWechatConfigModel.h"
#import "SPayClientAlipayConfigModel.h"
#import "SPayClientReverseScanPayDetailModel.h"
#import "SPayClientQQConfigModel.h"
#import "SPayClientWapPayDetailModel.h"

@interface SPayClient : NSObject


+ (SPayClient*)sharedInstance;


/**
 *  设置商户渠道模式
 *
 *  @return <#return value description#>
 */
- (void)macChannelConfig:(SPayClientConstEnumMacChannel)channel  NS_DEPRECATED_IOS(1.1.2, 1.2.2, "此方法已废弃，如果有用到此方法的请联系技术支持");


/**
 *  SpaySDK 当前版本号
 *
 *  @return <#return value description#>
 */
- (NSString*)spaySDKVersion;


/**
 *  SpaySDK 版本类型
 *
 *  @return <#return value description#>
 */
- (NSString*)spaySDKTypeName;


/**
 *  支付宝支付配置参数
 *
 *  @param alipayConfigModel <#alipayConfigModel description#>
 */
- (void)alipayAppConfig:(SPayClientAlipayConfigModel*)alipayConfigModel;



/**
 *  微信支付配置参数
 *
 *  @param wechatConfigModel <#wechatConfigModel description#>
 */
- (void)wechatpPayConfig:(SPayClientWechatConfigModel*)wechatConfigModel;


/**
 *  手Qwap支付配置参数
 *
 *  @param wechatConfigModel <#wechatConfigModel description#>
 */
- (void)qqPayConfig:(SPayClientQQConfigModel*)qqConfigModel;



/**
 *  SPay支付
 *
 *  @param pushFromCtrl      当前支付所在的页面（付款码和扫码需要传入，其他为nil）
 *  @param amount            支付的金额精确到分，整数类型（付款码需要传入，其他为nil）

 *  @param spayTokenIDString 支付授权码（必填）
 *  @param payServicesString 支付类型(必填如pay.weixin.app)
 *  @param finish            SDK支付完成回调
 */
- (void)pay:(UIViewController*)pushFromCtrl
     amount:(NSNumber*)amount
spayTokenIDString:(NSString*)spayTokenIDString
payServicesString:(NSString*)payServicesString
     finish:(SPayPayFinishBlock)finish ;



/**
 *  支付UI配置1.1.2以后使用此方法失效。
 *
 *  @param payDetail      正扫-支付详情页面UI
 *  @param paySuccess     支付成功后显示的UI
 *  @param payHelp        支付帮助页面的UI
 *  @param payReverseScan 反扫-支付详情页面UI
 */
- (void)payUIConfig:(SPayClientPayDetailModel*)payDetail
         paySuccess:(SPayClientPaySuccessModel*)paySuccess
            payHelp:(SPayClientPayHelpModel*)payHelp
     payReverseScan:(SPayClientReverseScanPayDetailModel*)payReverseScan;

/**
 *  UI配置 正扫-支付详情页面UI
 *
 *  @param payDetail <#payDetail description#>
 */
- (void)uiConfigPayDetail:(SPayClientPayDetailModel*)payDetail;

/**
 *  UI配置 支付成功后显示的UI
 *
 *  @param paySuccess <#paySuccess description#>
 */
- (void)uiConfigPaySuccess:(SPayClientPaySuccessModel*)paySuccess;

/**
 *  UI配置 支付帮助页面的UI
 *
 *  @param payHelp <#payHelp description#>
 */
- (void)uiConfigPayHelp:(SPayClientPayHelpModel*)payHelp;

/**
 *  UI配置 反扫-支付详情页面UI
 *
 *  @param payReverseScan <#payReverseScan description#>
 */
- (void)uiConfigPayReverseScan:(SPayClientReverseScanPayDetailModel*)payReverseScan;

/**
 *  UI配置 Wap,H5支付详情页面
 *
 *  @param wapPayDetailModel <#wapPayDetailModel description#>
 */
- (void)uiConfigWapPayDetailModel:(SPayClientWapPayDetailModel*)wapPayDetailModel;


#pragma mark - 使用微信APP支付和支付宝APP支付，必须实现以下三个UIApplicationDelegate代理方法

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;

- (BOOL)application:(UIApplication *)application
      handleOpenURL:(NSURL *)url;

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString*, id> *)options NS_AVAILABLE_IOS(9_0); // no equiv. notification. return NO if the application can't open for some reason


/**
 *   代理商户模式（SPayClientConstEnumMacChannelAgent）需要实现此方法。
 *
 *  @return <#return value description#>
 */
- (void)applicationWillEnterForeground:(UIApplication *)application;

@end
