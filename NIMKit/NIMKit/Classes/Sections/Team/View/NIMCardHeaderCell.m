//
//  TeamCardHeaderCell.m
//  NIM
//
//  Created by chris on 15/3/7.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMCardHeaderCell.h"
#import "NIMAvatarImageView.h"
#import "UIView+NIM.h"
#import "UIImage+NIMKit.h"
#import "NIMTeamHelper.h"
#import "NSString+NIMKit.h"

@interface NIMCardHeaderCell()

@property (nonatomic,strong) id<NIMKitCardHeaderData> data;

@end

@implementation NIMCardHeaderCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView                  = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 55, 55)];
        [self addSubview:_imageView];
        _titleLabel                 = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font            = [UIFont systemFontOfSize:13.f];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment   = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
        _roleImageView              = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:_roleImageView];
        _removeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _removeBtn.hidden = YES;
        [_removeBtn setImage:[UIImage nim_imageInKit:@"icon_avatar_del"] forState:UIControlStateNormal];
        [_removeBtn sizeToFit];
        [_removeBtn addTarget:self action:@selector(onTouchRemoveBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_removeBtn];
    }
    return self;
}

- (void)refreshData:(id<NIMKitCardHeaderData>)data{
    self.data = data;
    NSURL *url = [NSURL URLWithString:data.imageUrl];
    [self.imageView nim_setImageWithURL:url placeholderImage:data.imageNormal];
    [self.imageView addTarget:self action:@selector(onSelected:) forControlEvents:UIControlEventTouchUpInside];

    NSString *showName = data.title;
    if ([data isMyUserId]) {
        showName = @"我".nim_localized;
    }
    self.titleLabel.text = showName;
    self.roleImageView.image = [NIMTeamHelper imageWithMemberType:data.userType];
    [self.titleLabel sizeToFit];
}

- (void)onSelected:(id)sender{
    if ([self.delegate respondsToSelector:@selector(cellDidSelected:)]) {
        [self.delegate cellDidSelected:self];
    }
}

- (void)onTouchRemoveBtn:(id)sender{
    if ([self.delegate respondsToSelector:@selector(cellShouldBeRemoved:)]) {
        [self.delegate cellShouldBeRemoved:self];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.imageView.nim_centerX    = self.nim_width * .5f;
    self.titleLabel.nim_width     = self.nim_width + 10;
    self.titleLabel.nim_bottom    = self.nim_height;
    self.titleLabel.nim_centerX   = self.nim_width * .5f;
    [self.roleImageView sizeToFit];
    self.roleImageView.nim_bottom = self.imageView.nim_bottom;
    self.roleImageView.nim_right  = self.imageView.nim_right;
    self.removeBtn.nim_right      = self.nim_width;
    
}

@end
