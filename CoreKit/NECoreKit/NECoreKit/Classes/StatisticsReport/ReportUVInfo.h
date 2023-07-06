// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReportUVInfo : NSObject

@property(nonatomic, strong) NSString *user;

@property(nonatomic, strong) NSString *page;

@property(nonatomic, strong) NSString *extra;

@end

NS_ASSUME_NONNULL_END
