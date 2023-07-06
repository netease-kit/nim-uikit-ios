
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#ifndef NIMCustomObject_NEExtension_h
#define NIMCustomObject_NEExtension_h

#import "CustomParserManager.h"

@interface NIMCustomObject (NEExtension)

+ (void)addCustomAttachmentParser:(id<NIMCustomAttachmentCoding>)parser;

+ (void)removeCustomAttachmentParser:(id<NIMCustomAttachmentCoding>)parser;
@end

#endif /* NIMCustomObject_NEExtension_h */
