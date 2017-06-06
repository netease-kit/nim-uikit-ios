//
//  NTESTeamMeetingMutesCell.m
//  NIM
//
//  Created by chris on 2017/5/9.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESTeamMeetingMuteCell.h"
#import "NIMAvatarImageView.h"
#import "UIView+NTES.h"
#import "NIMKitInfoFetchOption.h"

@interface NTESTeamMeetingMuteCell()

@property (nonatomic,strong) NIMAvatarImageView *avatarImageView;

@property (nonatomic,strong) UILabel *nameLabel;

@property (nonatomic,strong) UIButton *micButton;

@end


@implementation NTESTeamMeetingMuteCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _avatarImageView = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
        [self addSubview:_avatarImageView];
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self addSubview:_nameLabel];
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _micButton.size = CGSizeMake(35, 35);
        [_micButton setImage:[UIImage imageNamed:@"btn_meeting_mute_disable_normal"] forState:UIControlStateNormal];
        [_micButton setImage:[UIImage imageNamed:@"btn_meeting_mute_disable_pressed"] forState:UIControlStateHighlighted];
        [_micButton setImage:[UIImage imageNamed:@"btn_meeting_mute_disable_selected"] forState:UIControlStateSelected];
        [_micButton setImage:[UIImage imageNamed:@"btn_meeting_mute_disable_selected_pressed"] forState:UIControlStateSelected | UIControlStateHighlighted];
        [self addSubview:_micButton];
    }
    return self;
}

- (void)refresh:(NSString *)userId muted:(BOOL)muted
{
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.session = [NIMSession session:self.team.teamId type:NIMSessionTypeTeam];

    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:userId option:option];
    [self.avatarImageView nim_setImageWithURL:[NSURL URLWithString:info.avatarUrlString] placeholderImage:info.avatarImage];
    self.nameLabel.text = info.showName;
    [self.nameLabel sizeToFit];
    self.micButton.selected = muted;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect hitRect = self.micButton.frame;
    return CGRectContainsPoint(hitRect, point) ? self : nil;
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{}


- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat avatarLeft = 8.f;
    self.avatarImageView.left = avatarLeft;
    self.avatarImageView.centerY = self.height * .5f;
    CGFloat nameAndAvatarSpacing = 5.f;
    self.nameLabel.left = self.avatarImageView.right + nameAndAvatarSpacing;
    self.nameLabel.centerY = self.height * .5f;
    CGFloat micButtonRight = 10.f;
    self.micButton.right   = self.width - micButtonRight;
    self.micButton.centerY = self.height * .5f;
}

@end
