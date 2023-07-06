// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReportActionInfo : NSObject

@end

@interface CallbackEventInfo : NSObject

@property(nonatomic, strong) NSString *callback;
@property(nonatomic, strong) NSNumber *code;
@property(nonatomic, strong) NSString *response;
@property(nonatomic, assign) long time;

@end

@interface EventInfo : NSObject
@property(nonatomic, strong) NSString *params;
@property(nonatomic, strong) NSNumber *code;
@property(nonatomic, strong) NSString *response;
@property(nonatomic, assign) long time;
@property(nonatomic, assign) long requestId;

@end

@interface ApiEventInfo : EventInfo
@property(nonatomic, strong) NSString *api;
@property(nonatomic, assign) long costTime;

@end

@interface ApiCallbackEventInfo : EventInfo
@property(nonatomic, strong) NSString *apiCallback;

@property(nonatomic, strong) NSString *event;

@property(nonatomic, strong) NSString *user;

@property(nonatomic, strong) NSString *extra;

@property(nonatomic, strong) NSString *result;

@end

NS_ASSUME_NONNULL_END
