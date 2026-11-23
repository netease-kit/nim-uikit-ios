// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/// NEAdaptiveUIKit 自身不依赖 NEChatKit，通过运行时弱引用复用统一埋点入口。
/// 引入组件时即上报；宿主未接入 NEChatKit 时不产生副作用。
@protocol NEAdaptiveUIKitReportProxy <NSObject>
+ (instancetype)shared;
- (void)buryDataPoints:(NSString *)component
               version:(NSString *)version;
@end

static Class NEAdaptiveUIKitReporterClass(void) {
  static Class reporterClass = Nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    reporterClass = NSClassFromString(@"NEChatKit.ChatKitClient");
    if (!reporterClass) {
      reporterClass = NSClassFromString(@"_TtC9NEChatKit13ChatKitClient");
    }
    if (!reporterClass) {
      reporterClass = NSClassFromString(@"ChatKitClient");
    }
    if (!reporterClass) {
      unsigned int count = 0;
      Class *classes = objc_copyClassList(&count);
      for (unsigned int i = 0; i < count; i++) {
        Class candidate = classes[i];
        if ([candidate respondsToSelector:@selector(shared)] &&
            [candidate instancesRespondToSelector:@selector(buryDataPoints:version:)]) {
          reporterClass = candidate;
          break;
        }
      }
      free(classes);
    }
  });
  return reporterClass;
}

@interface NEAdaptiveUIKitAutoReport : NSObject
@end

@implementation NEAdaptiveUIKitAutoReport

+ (void)load {
  // Adaptive 不直接依赖 NEChatKit，延迟到主队列执行，确保 NEChatKit 已完成加载。
  dispatch_async(dispatch_get_main_queue(), ^{
    Class reporterClass = NEAdaptiveUIKitReporterClass();
    if (!reporterClass) {
      return;
    }
    id<NEAdaptiveUIKitReportProxy> reporter =
        [(Class<NEAdaptiveUIKitReportProxy>)reporterClass shared];
    if (![reporter respondsToSelector:@selector(buryDataPoints:version:)]) {
      return;
    }
    NSBundle *bundle = [NSBundle bundleForClass:[NEAdaptiveUIKitAutoReport class]];
    NSString *version = bundle == [NSBundle mainBundle]
                            ? @""
                            : ([bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"");
    [reporter buryDataPoints:@"AdaptiveUIKit" version:version];
  });
}

@end
