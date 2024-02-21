// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEMapClient : NSObject

+ (instancetype)shared;

- (void)setupMapClientWithAppkey:(NSString *)appkey;

/// 设置插件初始化
/// @param appkey appkey
/// @param serverKey serverKey
- (void)setupMapClientWithAppkey:(NSString *)appkey withServerKey:(NSString *)serverKey;

@end

NS_ASSUME_NONNULL_END
