//
//  NTESLiveMasterInfoView.m
//  NIM
//
//  Created by chris on 15/12/17.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESLiveMasterInfoView.h"
#import "NIMAvatarImageView.h"
#import "UIView+NTES.h"
#import "NIMKit.h"

@interface NTESLiveMasterInfoView()

@property (nonatomic, strong) NIMAvatarImageView *avatarImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UIImageView *countIconImageView;

@property (nonatomic, strong) UILabel *countLabel;

@property (nonatomic, strong) UIView  *topSep;

@property (nonatomic, strong) UIView  *bottomSep;

@end

@implementation NTESLiveMasterInfoView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorFromRGB(0xffffff);
        [self addSubview:self.avatarImageView];
        [self addSubview:self.nameLabel];
        [self addSubview:self.countIconImageView];
        [self addSubview:self.countLabel];
        [self addSubview:self.topSep];
        [self addSubview:self.bottomSep];
    }
    return self;
}

- (void)refresh:(NIMChatroomMember *)member chatroom:(NIMChatroom *)chatroom{
    NSURL *avatarUrl     = [NSURL URLWithString:member.roomAvatar];
    [self.avatarImageView nim_setImageWithURL:avatarUrl];
    NSString *masterName = member.roomNickname;
    self.nameLabel.text  = [NSString stringWithFormat:@"主播 :  %@",masterName];
    [self.nameLabel sizeToFit];
    self.countLabel.text = @(chatroom.onlineUserCount).stringValue;
    [self.countLabel sizeToFit];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat spacing = 10.f;
    self.avatarImageView.left = spacing;
    self.avatarImageView.centerY = self.height * .5f;
    self.nameLabel.top   = self.avatarImageView.top;
    self.nameLabel.left  = self.avatarImageView.right + spacing;
    self.countIconImageView.bottom = self.avatarImageView.bottom;
    self.countIconImageView.left = self.avatarImageView.right + spacing;
    self.countLabel.centerY = self.countIconImageView.centerY;
    self.countLabel.left  = self.countIconImageView.right + spacing;
    self.topSep.width     = self.width;
    self.bottomSep.width  = self.width;
    self.bottomSep.bottom = self.height;
}


#pragma mark - Get
- (CGFloat)avatarWidth
{
    return 55.f;
}

- (NIMAvatarImageView *)avatarImageView
{
    if (!_avatarImageView)
    {
        _avatarImageView = [[NIMAvatarImageView alloc] initWithFrame:
                                     CGRectMake(0, 0, self.avatarWidth, self.avatarWidth)];
    }
    return _avatarImageView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel)
    {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.font = [UIFont systemFontOfSize:15.f];
    }
    return _nameLabel;
}

- (UIImageView *)countIconImageView
{
    if (!_countIconImageView)
    {
        _countIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [_countIconImageView setImage:[UIImage imageNamed:@"chatroom_onlinecount_room"]];
    }
    return _countIconImageView;
}

- (UILabel *)countLabel
{
    if (!_countLabel)
    {
        _countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _countLabel.font = [UIFont systemFontOfSize:13.f];
    }
    return _countLabel;
}


- (UIView *)topSep
{
    if (!_topSep)
    {
        _topSep = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, .5f)];
        _topSep.backgroundColor = UIColorFromRGB(0xcbd0d8);
    }
    return _topSep;
}

- (UIView *)bottomSep
{
    if (!_bottomSep)
    {
        _bottomSep = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, .5f)];
        _bottomSep.backgroundColor = UIColorFromRGB(0xcbd0d8);
    }
    return _bottomSep;
}
@end
