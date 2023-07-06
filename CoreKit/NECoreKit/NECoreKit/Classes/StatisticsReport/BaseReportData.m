// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "BaseReportData.h"
#import "NEReportConstans.h"

@interface BaseReportData ()

@end

@implementation BaseReportData

- (instancetype)initWithConfig:(ReportConfig *)config {
  self = [super init];
  if (self) {
    self.imVersion = config.imVersion;
    self.nertcVersion = config.nertcVersion;
    self.appKey = config.appKey;
    self.platform = PLATFORM_iOS;
  }
  return self;
}
@end
