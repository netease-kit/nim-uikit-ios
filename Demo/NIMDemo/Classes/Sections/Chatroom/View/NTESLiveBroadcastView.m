//
//  NTESLiveBroadcastView.m
//  NIM
//
//  Created by chris on 15/12/17.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESLiveBroadcastView.h"
#import "UIView+NTES.h"

@interface NTESLiveBroadcastView ()

@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UITextView *contentTextView;

@end

@implementation NTESLiveBroadcastView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.iconImageView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.contentTextView];
    }
    return self;
}

- (void)refresh:(NIMChatroom *)room{
    self.contentTextView.text = room.announcement.length ? room.announcement : @"暂无公告";
    [self.contentTextView sizeToFit];
    self.titleLabel.text = @"直播公告";
    [self.titleLabel sizeToFit];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat spacing = 10.f;
    self.iconImageView.top  = spacing;
    self.iconImageView.left = spacing;
    self.titleLabel.width   = (self.width - self.iconImageView.right) - 2 * spacing;
    [self.titleLabel sizeToFit];
    self.titleLabel.centerY = self.iconImageView.centerY;
    self.titleLabel.left = self.iconImageView.right + spacing;
    self.contentTextView.width  = self.width - spacing * 2;
    self.contentTextView.height = self.height - self.titleLabel.height - spacing * 2;
    self.contentTextView.left =  spacing;
    self.contentTextView.top  =  self.iconImageView.bottom + spacing * 2;
}

- (UIImageView *)iconImageView{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatroom_announce"]];
    }
    return _iconImageView;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.numberOfLines = 3;
    }
    return _titleLabel;
}

-(UITextView *)contentTextView{
    if (!_contentTextView) {
        _contentTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        _contentTextView.backgroundColor  = [UIColor clearColor];
        _contentTextView.font             = [UIFont systemFontOfSize:14.f];
        _contentTextView.editable         = NO;
        _contentTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return _contentTextView;
}

@end
