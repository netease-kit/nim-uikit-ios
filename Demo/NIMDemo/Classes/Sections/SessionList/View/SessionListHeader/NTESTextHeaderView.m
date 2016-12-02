//
//  NTESNetStatusHeaderView.m
//  NIM
//
//  Created by chris on 15/7/22.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESTextHeaderView.h"
#import "UIView+NTES.h"

@implementation NTESTextHeaderView

- (instancetype) initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.textColor = UIColorFromRGB(0x888888);
        _label.font = [UIFont systemFontOfSize:14.f];
        [self addSubview:_label];
    }
    return self;
}

- (void)setContentText:(NSString *)content{
    self.label.text = content;
}

#define SessionListRowContentTopPadding 10
- (CGSize)sizeThatFits:(CGSize)size{
    [self.label sizeToFit];
    CGSize contentSize = self.label.frame.size;
    return CGSizeMake(self.width, contentSize.height + SessionListRowContentTopPadding * 2);
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.label.centerX = self.width  * .5f;
    self.label.centerY = self.height * .5f;
}

@end
