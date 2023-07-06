// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XKitService <NSObject>
@optional
@property(nonatomic, strong) NSString *serviceName;

@property(nonatomic, strong) NSString *versionName;

@property(nonatomic, strong) NSString *appKey;

- (id)onMethodCall:(NSString *)method param:(NSDictionary *)param;

@end

@interface XKit : NSObject

+ (instancetype)instance;

- (void)registerService:(id<XKitService>)service;

@end

NS_ASSUME_NONNULL_END
