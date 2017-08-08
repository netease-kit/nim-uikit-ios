//
//  NSDictionary+SPayUtilsExtras.h
//  SPaySDKDemo
//
//  Created by wongfish on 15/6/14.
//  Copyright (c) 2015年 wongfish. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SPayUtilsExtras)

/**
 *  安全的对字典赋值
 *
 *  @param key <#key description#>
 *  @param val <#val description#>
 */
- (void)safeSetValue:(NSString*)key
                 val:(NSString*)val;

/**
 *  通过字典的key，以ASCII排序
 *
 *  @return <#return value description#>
 */
- (NSArray*)orderForKeyAscii;

/**
 *  获取SPay请求签名
 *
 *  @param commercialTenantKeyValString 商户密钥值
 *
 *  @return <#return value description#>
 */
- (NSString*)spayRequestSign:(NSString*)commercialTenantKeyValString;


/**
 *  判断字典中某个key是否存在
 *
 *  @param keyName 存在返回YES
 *
 *  @return <#return value description#>
 */
- (BOOL)isForKeyExists:(NSString*)keyName;


/**
 *  安全获取字典里面的值
 *
 *  @param key <#key description#>
 *
 *  @return <#return value description#>
 */
- (id)safeObjectForKey:(NSString*)key;

@end
