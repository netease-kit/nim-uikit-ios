//
//  UIColor+NIMKit.h
//  NIMKit
//
//  Created by He on 2020/4/15.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (NIMKit)
+ (instancetype)colorWithHex:(NSInteger)rgbValue alpha:(CGFloat)alphaValue;
@end

NS_ASSUME_NONNULL_END
