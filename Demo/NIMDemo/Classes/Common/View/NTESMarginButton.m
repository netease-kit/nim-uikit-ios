//
//  NTESMarginButton.m
//  NIM
//
//  Created by amao on 4/14/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESMarginButton.h"

@implementation NTESMarginButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGFloat margin = 20;
    CGRect hitRect = CGRectMake(0 - margin, 0 - margin, self.bounds.size.width + 2 * margin, self.bounds.size.height + 2 * margin);
    return CGRectContainsPoint(hitRect, point) ? self : nil;
}

@end
