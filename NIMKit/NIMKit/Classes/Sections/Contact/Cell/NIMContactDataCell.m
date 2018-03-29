//
//  NTESContactInfoCell.m
//  NIM
//
//  Created by chris on 15/2/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMContactDataCell.h"
#import "NIMAvatarImageView.h"
#import "UIView+NIM.h"
#import "NIMKit.h"
#import "UIImage+NIMKit.h"

@interface NIMContactDataCell()

@end

@implementation NIMContactDataCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _avatarImageView = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [_avatarImageView addTarget:self action:@selector(onPressAvatar:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_avatarImageView];
        _accessoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_accessoryBtn setImage:[UIImage nim_imageInKit:@"icon_accessory_normal"] forState:UIControlStateNormal];
        [_accessoryBtn setImage:[UIImage nim_imageInKit:@"icon_accessory_pressed"] forState:UIControlStateHighlighted];
        [_accessoryBtn setImage:[UIImage nim_imageInKit:@"icon_accessory_selected"] forState:UIControlStateSelected];
        [_accessoryBtn sizeToFit];
        _accessoryBtn.hidden = YES;
        _accessoryBtn.userInteractionEnabled = NO;
        [self addSubview:_accessoryBtn];
    }
    return self;
}

- (void)refreshItem:(id<NIMGroupMemberProtocol>)member withMemberInfo:(NIMKitInfo *)info {
    [self refreshTitle:member.showName];
    self.memberId = [member memberId];
    [self refreshAvatar:info];
}

- (void)refreshUser:(id<NIMGroupMemberProtocol>)member{
    [self refreshTitle:member.showName];
    self.memberId = [member memberId];
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:self.memberId option:nil];
    [self refreshAvatar:info];
}

- (void)refreshTeam:(id<NIMGroupMemberProtocol>)member{
    [self refreshTitle:member.showName];
    self.memberId = [member memberId];
    NIMKitInfo *info = [[NIMKit sharedKit] infoByTeam:self.memberId option:nil];
    [self refreshAvatar:info];
}

- (void)refreshTitle:(NSString *)title{
    self.textLabel.text = title;
}

- (void)refreshAvatar:(NIMKitInfo *)info{
    NSURL *url = info.avatarUrlString ? [NSURL URLWithString:info.avatarUrlString] : nil;
    [_avatarImageView nim_setImageWithURL:url placeholderImage:info.avatarImage options:SDWebImageRetryFailed];
}


- (void)onPressAvatar:(id)sender{
    if ([self.delegate respondsToSelector:@selector(onPressAvatar:)]) {
        [self.delegate onPressAvatar:self.memberId];
    }
}

- (void)addDelegate:(id)delegate{
    self.delegate = delegate;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    [self.accessoryBtn setHighlighted:highlighted];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated{

}


- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat scale = self.nim_width / 320;
    CGFloat maxTextLabelWidth = 210 * scale;
    self.textLabel.nim_width = MIN(self.textLabel.nim_width, maxTextLabelWidth);
    self.accessoryBtn.nim_left = NIMContactAccessoryLeft;
    self.accessoryBtn.nim_centerY = self.nim_height * .5f;
    self.avatarImageView.nim_left = self.accessoryBtn.hidden ? NIMContactAvatarLeft : NIMContactAvatarAndAccessorySpacing + self.accessoryBtn.nim_right;
    self.avatarImageView.nim_centerY = self.nim_height * .5f;
    self.textLabel.nim_left = self.avatarImageView.nim_right + NIMContactAvatarAndTitleSpacing;
}

@end
