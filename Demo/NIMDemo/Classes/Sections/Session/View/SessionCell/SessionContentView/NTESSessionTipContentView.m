//
//  NTESSessionTipContentView.m
//  NIM
//
//  Created by chris on 2016/11/6.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESSessionTipContentView.h"
#import "NTESCustomAttachmentDefines.h"
#import "UIView+NTES.h"

@implementation NTESSessionTipContentView

- (instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.numberOfLines = 0;
        [self addSubview:_label];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)model{
    [super refresh:model];
    NIMCustomObject *object = (NIMCustomObject *)model.message.messageObject;
    id<NTESCustomAttachmentInfo> attachment = (id<NTESCustomAttachmentInfo>)object.attachment;
    if ([attachment respondsToSelector:@selector(formatedMessage)]) {
        self.label.text =  [attachment formatedMessage];
    }
    self.label.textColor = [UIColor whiteColor];;
    self.label.font = [UIFont systemFontOfSize:10.f];
}

- (UIImage *)chatBubbleImageForState:(UIControlState)state outgoing:(BOOL)outgoing
{
    NSString *name = [[[NIMKit sharedKit] resourceBundleName] stringByAppendingPathComponent:@"icon_session_time_bg"];
    UIEdgeInsets insets = UIEdgeInsetsFromString(@"{8,20,8,20}");
    return [[UIImage imageNamed:name] resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat padding = 20.f;
    self.label.size = [self.label sizeThatFits:CGSizeMake(self.width - 2 * padding, CGFLOAT_MAX)];
    self.label.centerX = self.width * .5f;
    self.label.centerY = self.height * .5f;
    self.bubbleImageView.frame = CGRectInset(self.label.frame, -8, -4);
}


@end
