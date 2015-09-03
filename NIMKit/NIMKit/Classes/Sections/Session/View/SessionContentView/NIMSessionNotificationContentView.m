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

@implementation NIMSessionNotificationContentView

- (instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [UIFont boldSystemFontOfSize:10.f];
        _label.textColor = [UIColor whiteColor];
        [self addSubview:_label];
        self.bubbleType = NIMKitBubbleTypeNotify;
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)model{
    [super refresh:model];
    id<NIMCellLayoutConfig> config = model.layoutConfig;
    if ([config respondsToSelector:@selector(formatedMessage:)]) {
        _label.text = [model.layoutConfig formatedMessage:model];;
        [_label sizeToFit];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.label.nim_centerX = self.nim_width * .5f;
    self.label.nim_centerY = self.nim_height * .5f;
    self.bubbleImageView.frame = CGRectMake(self.label.nim_left - 7, self.label.nim_top - 2, self.label.nim_width + 14, self.label.nim_height + 4);
}


@end
