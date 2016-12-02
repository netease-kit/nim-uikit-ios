//
//  NTESMutiClientsHeaderView.m
//  NIM
//
//  Created by chris on 15/7/22.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESMutiClientsHeaderView.h"
#import "UIView+NTES.h"

@interface NTESMutiClientsHeaderView()

@property (nonatomic,strong) UIImageView *icon;

@property (nonatomic,strong) UILabel *label;

@property (nonatomic,strong) UIButton *accessoryBtn;

@end

@implementation NTESMutiClientsHeaderView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _icon  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_muti_clients"]];
        [self addSubview:_icon];
        
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.textColor = UIColorFromRGB(0x888888);
        _label.font = [UIFont boldSystemFontOfSize:14.f];
        [self addSubview:_label];
        
        _accessoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_accessoryBtn setImage:[UIImage imageNamed:@"icon_arrow"] forState:UIControlStateNormal];
        [_accessoryBtn sizeToFit];
        [self addSubview:_accessoryBtn];
    }
    return self;
}

CGFloat TextPadding = 17.f;
- (CGSize)sizeThatFits:(CGSize)size{
    [self.label sizeToFit];
    CGSize contentSize = self.label.frame.size;
    return CGSizeMake(self.width, contentSize.height + TextPadding * 2);
}


#pragma mark - NTESSessionListHeaderView
- (void)setContentText:(NSString *)content{
    self.label.text = content;
}


CGFloat IconLeft              = 10.f;
CGFloat IconAndContentSpacing = 10.f;
CGFloat ArrowRight            = 12.f;
- (void)layoutSubviews{
    [super layoutSubviews];
    self.icon.left     = IconLeft;
    self.icon.centerY  = self.height * .5f;
    self.label.left    = self.icon.right + IconAndContentSpacing;
    self.label.centerY = self.height * .5f;
    self.accessoryBtn.right = self.width - ArrowRight;
    self.accessoryBtn.centerY = self.height * .5f;
}

@end
