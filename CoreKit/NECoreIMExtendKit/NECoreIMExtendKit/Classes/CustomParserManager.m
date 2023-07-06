
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomParserManager.h"

static NSMutableArray *parserList;
static BOOL hasInit;
static CustomParserManager *sharedInstance;

@implementation CustomParserManager

+ (instancetype)sharedInstance {
  NSLog(@"NECoreIMExtendKit sharedInstance");
  static dispatch_once_t CustomParserManagerOnceToken;
  dispatch_once(&CustomParserManagerOnceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void)addCustomAttachmentParse:(id<NIMCustomAttachmentCoding>)parser {
  NSLog(@"NECoreIMExtendKit addCustomAttachmentParse");
  if (!hasInit) {
    [NIMCustomObject registerCustomDecoder:[CustomParserManager sharedInstance]];
    hasInit = YES;
    parserList = [[NSMutableArray alloc] init];
    NSLog(@"NECoreIMExtendKit addCustomAttachmentParse !hasInit");
  }
  if ([parserList containsObject:parser]) {
    return;
  }

  [parserList addObject:parser];
  NSLog(@"NECoreIMExtendKit addCustomAttachmentParse parserList.count: %lu",
        (unsigned long)parserList.count);
}

+ (void)removeCustomAttachmentParser:(id<NIMCustomAttachmentCoding>)parser {
  NSLog(@"NECoreIMExtendKit removeCustomAttachmentParser");
  if ([parserList containsObject:parser]) {
    [parserList removeObject:parser];
    NSLog(@"NECoreIMExtendKit removeCustomAttachmentParser parserList.count: %lu",
          (unsigned long)parserList.count);
  }
}

- (nullable id<NIMCustomAttachment>)decodeAttachment:(nullable NSString *)content {
  NSLog(@"NECoreIMExtendKit decodeAttachment");
  id<NIMCustomAttachment> attachment = nil;
  for (id<NIMCustomAttachmentCoding> parser in parserList) {
    id<NIMCustomAttachment> result = [parser decodeAttachment:content];
    if (result && attachment == nil) {
      attachment = result;
    }
  }

  return attachment;
}

@end
