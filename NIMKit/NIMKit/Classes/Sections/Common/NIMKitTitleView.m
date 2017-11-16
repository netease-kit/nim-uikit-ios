//
//  NIMKitTitleView.m
//  NIMKit
//
//  Created by chris on 2017/11/1.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMKitTitleView.h"
#import "UIView+NIM.h"

@implementation NIMKitTitleView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15.f];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _titleLabel.textAlignment = NSTextAlignmentCenter;

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.textColor = [UIColor grayColor];
        _subtitleLabel.font = [UIFont systemFontOfSize:12.f];
        _subtitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;

        [self addSubview:_titleLabel];
        [self addSubview:_subtitleLabel];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat margin = 80.f;
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - margin * 2;

    [self.titleLabel sizeToFit];
    self.titleLabel.nim_width = MIN(self.titleLabel.nim_width, maxWidth);
    
    [self.subtitleLabel sizeToFit];
    self.subtitleLabel.nim_width = MIN(self.subtitleLabel.nim_width, maxWidth);
    
    CGFloat width = MAX(self.titleLabel.nim_width, self.subtitleLabel.nim_width);
    return CGSizeMake(width, self.titleLabel.nim_height + self.subtitleLabel.nim_height);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.titleLabel.nim_centerX = self.nim_width * .5f;
    self.subtitleLabel.nim_centerX = self.nim_width * .5f;
    self.subtitleLabel.nim_bottom  = self.nim_height;
}

@end
