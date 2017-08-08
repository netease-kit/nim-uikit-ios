//
//  NSDictionary+SafeObj.h
//  JYangToolKit
//
//  Created by 一路财富 on 16/11/3.
//  Copyright © 2016年 JYang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SafeObj)

/**
 discuss 红包2.0(包含2.0),钱包1.2(包含1.2)之前使用
 */
- (NSString *)safeObjectForKey:(id)key  NS_DEPRECATED_IOS(1.1.0, 1.2.1, "红包2.0(包含2.0),钱包1.2(包含1.2)之前使用, 之后的版本请使用jrmfSafeObjectForKey:");

/**
 @discuss 红包v2.0,钱包1.2以后的版本都必须使用该方法
 */
- (NSString *)jrmfSafeObjectForKey:(id)key;

@end
