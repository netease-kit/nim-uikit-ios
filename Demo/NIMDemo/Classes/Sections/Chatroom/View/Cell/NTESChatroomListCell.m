//
//  NTESChatroomListCell.m
//  NIM
//
//  Created by chris on 15/12/14.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomListCell.h"
#import "UIImageView+WebCache.h"
#import "UIView+NTES.h"

@interface NTESChatroomListCellInfoView : UIView
- (void)refresh:(id)data;
@end

@interface NTESChatroomListCell()

@property (nonatomic,strong) UIImageView *coverImageView;

@property (nonatomic,strong) NTESChatroomListCellInfoView *infoView;

@end

@implementation NTESChatroomListCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = .5f;
        [self addSubview:self.coverImageView];
        [self addSubview:self.infoView];
    }
    return self;
}

- (void)refresh:(NIMChatroom *)chatroom{
    NSInteger index = chatroom.roomId.hash % 8;
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"chatroom_cover_page_%zd",index]];
    [self.coverImageView sd_setImageWithURL:nil placeholderImage:image];
    [self.infoView refresh:chatroom];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.coverImageView.size = CGSizeMake(self.width, self.height);
    self.infoView.bottom = self.height;
}

#pragma mark - Get
- (UIImageView *)coverImageView{
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
        _coverImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _coverImageView;
}

- (NTESChatroomListCellInfoView *)infoView{
    if (!_infoView) {
        _infoView = [[NTESChatroomListCellInfoView alloc] initWithFrame:CGRectMake(0, 0, self.width, 44)];
        _infoView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return _infoView;
}

@end



@interface NTESChatroomListCellInfoView()

@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) UIImageView *iconImageView; //人数icon

@property (nonatomic, strong) UILabel *countLabel; //在线人数

@property (nonatomic, strong) UIView  *titleBackgroundView; //聊天室房间名背景

@property (nonatomic, strong) UILabel *titleLabel;         //聊天室房间名

@end

@implementation NTESChatroomListCellInfoView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorFromRGBA(0x0, .6f);
        [self addSubview:self.statusLabel];
        [self addSubview:self.titleBackgroundView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.iconImageView];
        [self addSubview:self.countLabel];
    }
    return self;
}

- (void)refresh:(NIMChatroom *)chatroom{
    self.statusLabel.text = @"正在直播";
    [self.statusLabel sizeToFit];
    float onlineUserCount = (float)chatroom.onlineUserCount;
    NSString *countText;
    if (onlineUserCount > 10000) {
        countText = [NSString stringWithFormat:@"%.1f万",onlineUserCount / 10000];
    }else{
        countText = @(chatroom.onlineUserCount).stringValue;
    }
    self.countLabel.text  = countText;
    [self.countLabel sizeToFit];
    self.titleLabel.text  = chatroom.name;
    [self.titleLabel sizeToFit];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat spacing = 8.f;
    self.statusLabel.centerY = (self.height - self.titleBackgroundViewHeight) * .5;
    self.statusLabel.left = spacing;
    self.countLabel.right = self.width - spacing;
    self.countLabel.centerY  = self.statusLabel.centerY;
    self.iconImageView.right = self.countLabel.left - spacing;
    self.iconImageView.centerY = self.statusLabel.centerY;
    self.titleBackgroundView.width = self.width;
    self.titleBackgroundView.bottom = self.height;
    self.titleLabel.width = self.width - 2 *spacing;
    self.titleLabel.left  = spacing;
    self.titleLabel.centerY = self.titleBackgroundView.centerY;
}


#pragma mark - Get

- (UILabel *)statusLabel{
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _statusLabel.font = [UIFont systemFontOfSize:10.f];
        _statusLabel.textColor = [UIColor whiteColor];
    }
    return _statusLabel;
}

- (UIImageView *)iconImageView{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
        [_iconImageView setImage:[UIImage imageNamed:@"chatroom_onlinecount_room"]];
    }
    return _iconImageView;
}

- (UILabel *)countLabel{
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _countLabel.font = [UIFont systemFontOfSize:10.f];
        _countLabel.textColor = [UIColor whiteColor];
    }
    return _countLabel;
}



- (CGFloat)titleBackgroundViewHeight{
    return 28.f;
}

- (CGFloat)titleLabelLeft{
    return 15.f;
}

- (UIView *)titleBackgroundView{
    if (!_titleBackgroundView) {
        _titleBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.titleBackgroundViewHeight)];
        _titleBackgroundView.backgroundColor = [UIColor whiteColor];
    }
    return _titleBackgroundView;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:13.f];
    }
    return _titleLabel;
}



@end
