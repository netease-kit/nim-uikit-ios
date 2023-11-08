//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECallKitUtil.h"

@implementation NECallKitUtil

// 16 进制颜色转换 转换成 UIColor
+ (UIColor *)colorWithHexString:(NSString *)hexString {
  unsigned int hexValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner setScanLocation:1];     // 跳过字符串开头的#
  [scanner scanHexInt:&hexValue];  // 将字符串转换为16进制整数
  UIColor *color = [UIColor colorWithRed:((hexValue & 0xFF0000) >> 16) / 255.0
                                   green:((hexValue & 0xFF00) >> 8) / 255.0
                                    blue:(hexValue & 0xFF) / 255.0
                                   alpha:1.0];
  return color;
}

@end
