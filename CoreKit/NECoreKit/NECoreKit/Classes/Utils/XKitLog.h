// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NECoreKit/XKitLogOptions.h>

NS_ASSUME_NONNULL_BEGIN

@interface XKitLog : NSObject

+ (XKitLog *)setUp:(XKitLogOptions *)options;

- (void)apiLog:(NSString *)className desc:(NSString *)desc;

- (void)infoLog:(NSString *)className desc:(NSString *)desc;

- (void)warnLog:(NSString *)className desc:(NSString *)desc;

- (void)errorLog:(NSString *)className desc:(NSString *)desc;
@end

NS_ASSUME_NONNULL_END
