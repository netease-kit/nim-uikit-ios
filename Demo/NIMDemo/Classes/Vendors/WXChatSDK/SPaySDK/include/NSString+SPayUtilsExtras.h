//
//  NSString+SPayUtilsExtras.h
//  SPaySDKDemo
//
//  Created by wongfish on 15/6/14.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SPayUtilsExtras)

/**
 *  生成md5
 */
@property (nonatomic, readonly) NSString* md5Hash;

/**
 *  生成SPay需要的随机字符串
 *
 *  @return <#return value description#>
 */
+ (NSString*)spay_nonce_str;

/**
 *  生成SPay商户订单号；
 *
 *  @return <#return value description#>
 */
+ (NSString*)spay_out_trade_no;

/**
 *  解析HTTP Get参数
 *
 *  @return <#return value description#>
 */
-(NSDictionary*)parseHTTGetParameter;

@end
