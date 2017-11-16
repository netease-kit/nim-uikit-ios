//
//  NIMSessionNotificationContentView.m
//  NIMKit
//
//  Created by chris on 15/3/9.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionNotificationContentView.h"
#import "NIMMessageModel.h"
#import "UIView+NIM.h"
#import "NIMKitUtil.h"
#import "UIImage+NIMKit.h"
#import "NIMKit.h"

@implementation NIMSessionNotificationContentView

- (instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.numberOfLines = 0;
        [self addSubview:_label];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)model
{
    [super refresh:model];
    self.label.text = [NIMKitUtil messageTipContent:model.message];
    NIMKitSetting *setting = [[NIMKit sharedKit].config setting:model.message];
    
    self.label.textColor = setting.textColor;
    self.label.font = setting.font;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat padding = [NIMKit sharedKit].config.maxNotificationTipPadding;
    self.label.nim_size = [self.label sizeThatFits:CGSizeMake(self.nim_width - 2 * padding, CGFLOAT_MAX)];
    self.label.nim_centerX = self.nim_width * .5f;
    self.label.nim_centerY = self.nim_height * .5f;
    self.bubbleImageView.frame = CGRectInset(self.label.frame, -8, -4);
}


@end
