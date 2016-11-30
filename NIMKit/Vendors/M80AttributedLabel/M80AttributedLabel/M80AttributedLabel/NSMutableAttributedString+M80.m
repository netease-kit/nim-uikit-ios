//
//  NSMutableAttributedString+M80.m
//  M80AttributedLabel
//
//  Created by amao on 13-8-31.
//  Copyright (c) 2013年 www.xiangwangfeng.com. All rights reserved.
//

#import "NSMutableAttributedString+M80.h"

@implementation NSMutableAttributedString (M80)

- (void)m80_setTextColor:(UIColor*)color
{
    [self m80_setTextColor:color range:NSMakeRange(0, [self length])];
}

- (void)m80_setTextColor:(UIColor*)color range:(NSRange)range
{
    if (color.CGColor)
    {
        [self removeAttribute:(NSString *)kCTForegroundColorAttributeName range:range];
        
        [self addAttribute:(NSString *)kCTForegroundColorAttributeName
                     value:(id)color.CGColor
                     range:range];
    }
    
}


- (void)m80_setFont:(UIFont*)font
{
    [self m80_setFont:font range:NSMakeRange(0, [self length])];
}

- (void)m80_setFont:(UIFont*)font range:(NSRange)range
{
    if (font)
    {
        [self removeAttribute:(NSString*)kCTFontAttributeName range:range];
        
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, nil);
        if (nil != fontRef)
        {
            [self addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:range];
            CFRelease(fontRef);
        }
    }
}

- (void)m80_setUnderlineStyle:(CTUnderlineStyle)style
                 modifier:(CTUnderlineStyleModifiers)modifier
{
    [self m80_setUnderlineStyle:style
                   modifier:modifier
                      range:NSMakeRange(0, self.length)];
}

- (void)m80_setUnderlineStyle:(CTUnderlineStyle)style
                 modifier:(CTUnderlineStyleModifiers)modifier
                    range:(NSRange)range
{
    [self removeAttribute:(NSString *)kCTUnderlineColorAttributeName range:range];
    [self addAttribute:(NSString *)kCTUnderlineStyleAttributeName
                 value:[NSNumber numberWithInt:(style|modifier)]
                 range:range];
    
}

@end
