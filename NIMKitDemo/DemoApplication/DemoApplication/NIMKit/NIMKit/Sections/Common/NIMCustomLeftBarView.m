//
//  NIMCustomLeftBarView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2014年 Netease. All rights reserved.
//

#import "NIMCustomLeftBarView.h"
#import "NIMBadgeView.h"
#import "UIView+NIM.h"
@implementation NIMCustomLeftBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initSubviews];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)initSubviews
{
    self.badgeView = [NIMBadgeView viewWithBadgeTip:@""];
    self.badgeView.frame = CGRectMake(0, 8, 0, 0);
    self.badgeView.hidden = YES;
    self.frame = CGRectMake(0.0, 0.0, 50.0, 44.f);
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.badgeView];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    for (UIView *view in self.subviews) {
        view.nim_centerY = self.nim_height * .5f;
    }
}
@end
