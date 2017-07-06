//
//  NIMAdvancedTeamMemberCell.m
//  NIM
//
//  Created by chris on 15/3/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMAdvancedTeamMemberCell.h"
#import "UIView+NIM.h"
#import "NIMUsrInfoData.h"
#import "NIMAvatarImageView.h"
#import "NIMKitUtil.h"
#import "NIMKit.h"
#import "UIImage+NIMKit.h"

@interface NIMAdvancedTeamMemberView : UIView{

}

@property(nonatomic,strong) NIMAvatarImageView *imageView;

@property(nonatomic,strong) UILabel *titleLabel;

@property(nonatomic,strong) NIMKitInfo *member;

@end

#define RegularTeamMemberViewHeight 53
#define RegularTeamMemberViewWidth  38
@implementation NIMAdvancedTeamMemberView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont systemFontOfSize:12.f];
        [self addSubview:_titleLabel];
        _imageView   = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 37, 37)];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)setMember:(NIMKitInfo *)member{
    _member = member;
    NSURL *avatarURL;
    if (member.avatarUrlString.length) {
        avatarURL = [NSURL URLWithString:member.avatarUrlString];
    }
    [_imageView nim_setImageWithURL:avatarURL placeholderImage:member.avatarImage];
}


- (CGSize)sizeThatFits:(CGSize)size{
    return CGSizeMake(RegularTeamMemberViewWidth, RegularTeamMemberViewHeight);
}


#define RegularTeamMemberInvite
- (void)layoutSubviews{
    [super layoutSubviews];
    [self.titleLabel sizeToFit];
    self.titleLabel.nim_width = _titleLabel.nim_width > self.nim_width ? self.nim_width : _titleLabel.nim_width;
    self.imageView.nim_centerX = self.nim_width * .5f;
    self.titleLabel.nim_centerX = self.nim_width * .5f;
    self.titleLabel.nim_bottom = self.nim_height;
}
@end


@interface NIMAdvancedTeamMemberCell()

@property(nonatomic,strong) NSMutableArray *icons;

@property(nonatomic,strong) NIMTeam *team;

@property(nonatomic,copy)   NSArray *teamMembers;

@property(nonatomic,strong) UIButton *addBtn;

@end

@implementation NIMAdvancedTeamMemberCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _icons = [[NSMutableArray alloc] init];
        _addBtn = [[UIButton alloc]initWithFrame:CGRectZero];
        [_addBtn addTarget:self action:@selector(onPress:) forControlEvents:UIControlEventTouchUpInside];
        _addBtn.userInteractionEnabled = NO;
        [self addSubview:_addBtn];
    }
    return self;
}

- (void)rereshWithTeam:(NIMTeam*)team
               members:(NSArray*)members
                 width:(CGFloat)width{
    _team = team;
    _teamMembers = members;
    NIMTeamMember *myTeamInfo;
    for (NIMTeamMember *member in members) {
        if ([member.userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount]) {
            myTeamInfo = member;
            break;
        }
    }
    NSInteger count = 0;
    if ([NIMKitUtil canInviteMember:myTeamInfo]) {
        NIMAdvancedTeamMemberView *view = [self fetchMemeberView:0];
        UIImage *addImage = [UIImage nim_imageInKit:@"icon_add_normal"];
        [view.imageView nim_setImageWithURL:nil placeholderImage:addImage];
        view.titleLabel.text = @"邀请";
        count = 1;
        self.addBtn.userInteractionEnabled = YES;
    }else{
        self.addBtn.userInteractionEnabled = NO;
    }
    
    CGFloat padding = 44.f;
    CGFloat itemWidth = 49.f;
    NSInteger maxIconCount = (width - padding) / itemWidth;
    NSInteger iconCount = members.count > maxIconCount-count ? maxIconCount : members.count + count;
    NIMSession *session = [NIMSession session:team.teamId type:NIMSessionTypeTeam];
    for (UIView *view in _icons) {
        [view removeFromSuperview];
    }
    for (NSInteger i = 0; i < iconCount; i++) {
        NIMAdvancedTeamMemberView *view = [self fetchMemeberView:i];
        if (!count || i != 0) {
            NSInteger memberIndex       = i - count;
            NIMTeamMember *member       = members[memberIndex];
            NIMKitInfo *info            = [[NIMKit sharedKit] infoByUser:member.userId option:nil];
            view.member                 = info;
            view.titleLabel.text        = [NIMKitUtil showNick:member.userId inSession:session];
        }
        [self addSubview:view];
        [view setNeedsLayout];
    }
    [self bringSubviewToFront:self.addBtn];
}

- (void)onPress:(id)sender{
    if ([self.delegate respondsToSelector:@selector(didSelectAddOpeartor)]) {
        [self.delegate didSelectAddOpeartor];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    CGRect hitRect = self.addBtn.frame;
    return CGRectContainsPoint(hitRect, point) ? self.addBtn : [super hitTest:point withEvent:event];
}


- (void)layoutSubviews{
    [super layoutSubviews];
    _addBtn.frame = CGRectMake(0, 0, self.nim_width *.20f, self.nim_height);
    CGFloat left = 20.f;
    CGFloat top  = 17.f;
    self.textLabel.nim_left = left;
    self.textLabel.nim_top  = top;
    self.detailTextLabel.nim_top = top;
    self.accessoryView.nim_top = top;
    
    CGFloat spacing = 12.f;
    CGFloat bottom  = 10.f;
    for (NIMAdvancedTeamMemberView *view in _icons) {
        view.nim_left = left;
        left += view.nim_width;
        left += spacing;
        view.nim_bottom = self.nim_height - bottom;
    }
}


#pragma mark - Private

- (NIMAdvancedTeamMemberView *)fetchMemeberView:(NSInteger)index{
    if (_icons.count <= index) {
        for (int i = 0; i < index - _icons.count + 1 ; i++) {
            NIMAdvancedTeamMemberView *view = [[NIMAdvancedTeamMemberView alloc]initWithFrame:CGRectZero];
            view.userInteractionEnabled = NO;
            [view sizeToFit];
            [_icons addObject:view];
        }
    }
    return _icons[index];
}


@end
