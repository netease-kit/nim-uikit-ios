//
//  NTESChatroomMemberCell.m
//  NIM
//
//  Created by chris on 15/12/18.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomMemberCell.h"
#import "NIMAvatarImageView.h"
#import "UIView+NTES.h"
#import "NIMKit.h"

@interface NTESChatroomMemberCell()

@property (nonatomic, strong) NIMAvatarImageView *avatarImageView;

@property (nonatomic, strong) UIImageView *roleImageView;

@end

@implementation NTESChatroomMemberCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self addSubview:self.avatarImageView];
        [self addSubview:self.roleImageView];
    }
    return self;
}

- (void)refresh:(NIMChatroomMember *)member{
    [self.avatarImageView nim_setImageWithURL:[NSURL URLWithString:member.roomAvatarThumbnail]
                             placeholderImage:[UIImage imageNamed:@"avatar_user"]];
    self.textLabel.text = member.roomNickname;
    [self.textLabel sizeToFit];
    [self refreshRole:member];
}

- (void)refreshRole:(NIMChatroomMember *)member
{
    UIImage *image;
    switch (member.type) {
        case NIMChatroomMemberTypeCreator:
            image = [UIImage imageNamed:@"chatroom_role_master"];
            break;
        case NIMChatroomMemberTypeManager:
            image = [UIImage imageNamed:@"chatroom_role_manager"];
            break;
        default:
            break;
    }
    self.roleImageView.image = image;
    self.roleImageView.hidden = !image;
    [self.roleImageView sizeToFit];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat spacing = 10.f;
    if (!self.roleImageView.hidden){
        self.roleImageView.left      = spacing;
        self.roleImageView.centerY   = self.height * .5f;
        self.avatarImageView.left    = self.roleImageView.right + spacing;
    }
    else{
        self.avatarImageView.left    = spacing;
    }
    self.avatarImageView.centerY = self.height * .5f;
    self.textLabel.left          = self.avatarImageView.right + spacing;
    self.textLabel.centerY       = self.height * .5f;
    
}


#pragma mark - Get
- (NIMAvatarImageView *)avatarImageView{
    if (!_avatarImageView) {
        _avatarImageView = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    }
    return _avatarImageView;
}

- (UIImageView *)roleImageView
{
    if (!_roleImageView) {
        _roleImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _roleImageView;
}

@end
