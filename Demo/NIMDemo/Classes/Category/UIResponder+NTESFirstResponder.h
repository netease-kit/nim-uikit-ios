//
//  UIResponder+NTESFirstResponder.h
//  NIM
//
//  Created by chris on 15/9/26.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (NTESFirstResponder)

+ (instancetype)currentFirstResponder;

+ (instancetype)currentSecondResponder;

@end
