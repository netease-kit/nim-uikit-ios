//
//  TeamCardHeaderCell.m
//  NIM
//
//  Created by chris on 15/3/7.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamCardHeaderCell.h"
#import "NIMAvatarImageView.h"
#import "UIView+NIM.h"
#import "NIMCardMemberItem.h"

@interface NIMTeamCardHeaderCell()

@property (nonatomic,strong) id<NIMKitCardHeaderData> data;

@end

@implementation NIMTeamCardHeaderCell

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
        [_removeBtn setImage:[UIImage imageNamed:@"icon_avatar_del"] forState:UIControlStateNormal];
        [_removeBtn sizeToFit];
        [_removeBtn addTarget:self action:@selector(onTouchRemoveBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_removeBtn];
    }
    return self;
}

- (void)refreshData:(id<NIMKitCardHeaderData>)data{
    self.data = data;
    NSURL *url;
    if ([data respondsToSelector:@selector(imageUrl)] && data.imageUrl.length) {
        url = [NSURL URLWithString:data.imageUrl];
    }
    [self.imageView nim_setImageWithURL:url placeholderImage:data.imageNormal];
    [self.imageView addTarget:self action:@selector(onSelected:) forControlEvents:UIControlEventTouchUpInside];
    self.titleLabel.text = data.title;
    if([data isKindOfClass:[NIMTeamCardMemberItem class]]) {
        NIMTeamCardMemberItem *member = data;
        self.titleLabel.text = member.title.length ? member.title : member.memberId;
        switch (member.type) {
            case NIMTeamMemberTypeOwner:
                self.roleImageView.image = [UIImage imageNamed:@"icon_team_creator"];
                break;
            case NIMTeamMemberTypeManager:
                self.roleImageView.image = [UIImage imageNamed:@"icon_team_manager"];
                break;
            default:
                self.roleImageView.image = nil;
                break;
        }
    }else{
        self.roleImageView.image = nil;
    }
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
