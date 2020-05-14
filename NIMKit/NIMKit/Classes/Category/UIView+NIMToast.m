//
//  UIView+NIMToast.m
//  NIMKit
//
//  Created by 丁文超 on 2020/3/19.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import "UIView+NIMToast.h"

@implementation UIView (NIMToast)

- (void)nim_showToast:(NSString *)message duration:(CGFloat)duration
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = UIColor.whiteColor;
    label.text = message;
    label.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.6];
    label.layer.cornerRadius = 10;
    label.layer.masksToBounds = YES;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:15];
    
    CGFloat width = label.intrinsicContentSize.width+24;
    CGFloat height = label.intrinsicContentSize.height+16;
    label.frame = CGRectMake(self.bounds.size.width/2-width/2, self.bounds.size.height/2-height/2, width, height);
    
    [UIView transitionWithView:self
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        [self addSubview:label];
    } completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView transitionWithView:self
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            [label removeFromSuperview];
        } completion:nil];
        
    });
}

@end
