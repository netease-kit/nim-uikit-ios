
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NIMCustomObject+NEExtension.h"

@implementation NIMCustomObject (NEExtension)

+ (void)addCustomAttachmentParser:(id<NIMCustomAttachmentCoding>)parser {
  [CustomParserManager addCustomAttachmentParse:parser];
}

+ (void)removeCustomAttachmentParser:(id<NIMCustomAttachmentCoding>)parser {
  [CustomParserManager removeCustomAttachmentParser:parser];
}

@end
