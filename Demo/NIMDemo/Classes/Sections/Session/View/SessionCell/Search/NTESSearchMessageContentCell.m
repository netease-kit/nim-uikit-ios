//
//  NTESSearchMessageContentCell.m
//  NIM
//
//  Created by chris on 15/7/8.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESSearchMessageContentCell.h"
#import "NTESSearchLocalHistoryObject.h"
#import "NTESSessionUtil.h"
#import "UIView+NTES.h"
#import "NIMAvatarImageView.h"

//font
CGFloat SearchCellTitleFontSize   = 13.f;
CGFloat SearchCellContentFontSize = 12.f;
CGFloat SearchCellTimeFontSize    = 12.f;

//layout
CGFloat SearchCellAvatarLeft            = 15.f;
CGFloat SearchCellAvatarAndTitleSpacing = 10.f;
CGFloat SearchCellTitleTop              = 10.f;
CGFloat SearchCellTimeRight             = 15.f;
CGFloat SearchCellTimeTop               = 10.f;
CGFloat SearchCellContentTop            = 30.f;
CGFloat SearchCellContentBottom         = 8.f;
CGFloat SearchCellContentMaxWidth       = 260.f;
CGFloat SearchCellContentMinHeight      = 15.f; //cell的高度是由文本高度决定的。防止没有文本的情况，导致cell的高度过小。

@interface NTESSearchMessageContentCell()

@property (nonatomic,strong) NIMAvatarImageView *avatar;

@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) UILabel *contentLabel;

@property (nonatomic,strong) UILabel *timeLabel;

@property (nonatomic,strong) NTESSearchLocalHistoryObject *object;

@end

@implementation NTESSearchMessageContentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _avatar                     = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [self addSubview:_avatar];
        _titleLabel                 = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font            = [UIFont systemFontOfSize:13.f];
        [self addSubview:_titleLabel];
        _contentLabel               = [[UILabel alloc] initWithFrame:CGRectZero];
        _contentLabel.font          = [UIFont systemFontOfSize:12.f];
        _contentLabel.textColor     = [UIColor grayColor];
        _contentLabel.numberOfLines = 0;
        [self addSubview:_contentLabel];
        _timeLabel                  = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.font             = [UIFont systemFontOfSize:12.f];
        [self addSubview:_timeLabel];
    }
    return self;
}

- (void)refresh:(NTESSearchLocalHistoryObject *)object{
    self.object = object;
    NIMMessage *message    = object.message;
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:message.from option:nil];
    NSURL *avatarURL;
    if (info.avatarUrlString.length) {
        avatarURL = [NSURL URLWithString:info.avatarUrlString];
    }
    [self.avatar nim_setImageWithURL:avatarURL placeholderImage:info.avatarImage];
    self.titleLabel.text   = info.showName;
    self.contentLabel.text = message.text;
    self.timeLabel.text    = [NTESSessionUtil showTime:message.timestamp showDetail:YES];
    [self.titleLabel sizeToFit];
    self.contentLabel.size = [self.contentLabel sizeThatFits:CGSizeMake(SearchCellContentMaxWidth * UISreenWidthScale, CGFLOAT_MAX)];
    self.contentLabel.height = MAX(SearchCellContentMinHeight, self.contentLabel.height);
    [self.timeLabel sizeToFit];
}


- (void)layoutSubviews{
    [super layoutSubviews];
    self.avatar.top          = SearchCellTitleTop;
    self.avatar.left         = SearchCellAvatarLeft;
    self.titleLabel.left     = self.avatar.right + SearchCellAvatarAndTitleSpacing;
    self.contentLabel.left   = self.titleLabel.left;
    self.titleLabel.top      = SearchCellTitleTop;
    self.contentLabel.bottom = self.height - SearchCellContentBottom;
    self.timeLabel.right     = self.width - SearchCellTimeRight;
    self.timeLabel.top       = SearchCellTimeTop;
}


@end
