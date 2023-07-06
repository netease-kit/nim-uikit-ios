// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "XKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface XKitServiceManager : NSObject

+ (instancetype)getInstance;

- (void)registerService:(NSString *)serviceName service:(id<XKitService>)service;

- (BOOL)serviceIsRegister:(NSString *)serviceName;

@end

NS_ASSUME_NONNULL_END
