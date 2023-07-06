// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReportModuleInfo : NSObject

@property(nonatomic, strong) NSString *serviceName;

@property(nonatomic, strong) NSString *versionName;

@property(nonatomic, strong) NSString *appkey;

@end

NS_ASSUME_NONNULL_END
