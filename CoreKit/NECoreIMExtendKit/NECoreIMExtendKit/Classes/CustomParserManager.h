
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#ifndef CustomAttachmentParser_h
#define CustomAttachmentParser_h

#import "NIMSDK/NIMSDK.h"

@interface CustomParserManager : NSObject <NIMCustomAttachmentCoding>

+ (void)addCustomAttachmentParse:(id<NIMCustomAttachmentCoding>)parser;
+ (void)removeCustomAttachmentParser:(id<NIMCustomAttachmentCoding>)parser;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

#endif /* CustomAttachmentParser_h */
