//
//  UIColor+NIMKit.m
//  NIMKit
//
//  Created by He on 2020/4/15.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "UIColor+NIMKit.h"


@implementation UIColor (NIMKit)
+ (instancetype)colorWithHex:(NSInteger)rgbValue alpha:(CGFloat)alphaValue
{
   return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0
                          green:((float)((rgbValue & 0x00FF00) >> 8))/255.0
                           blue:((float)(rgbValue & 0x0000FF))/255.0
                          alpha:alphaValue];
}


@end
