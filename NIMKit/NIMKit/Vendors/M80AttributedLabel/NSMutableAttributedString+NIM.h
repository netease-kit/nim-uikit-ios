//
//  NSMutableAttributedString+NIM.h
//  NIMAttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

@interface NSMutableAttributedString (NIM)

- (void)nim_setTextColor:(UIColor*)color;
- (void)nim_setTextColor:(UIColor*)color range:(NSRange)range;

- (void)nim_setFont:(UIFont*)font;
- (void)nim_setFont:(UIFont*)font range:(NSRange)range;

- (void)nim_setUnderlineStyle:(CTUnderlineStyle)style
                 modifier:(CTUnderlineStyleModifiers)modifier;
- (void)nim_setUnderlineStyle:(CTUnderlineStyle)style
                 modifier:(CTUnderlineStyleModifiers)modifier
                    range:(NSRange)range;

@end
