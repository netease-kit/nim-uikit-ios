//
//  VideoChatNetStateView.m
//  NIM
//
//  Created by chris on 15/5/20.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESVideoChatNetStatusView.h"
#import "UIView+NTES.h"

@interface NTESVideoChatNetStatusView()

@property (nonatomic,strong) UIImageView *statusImageView;

@property (nonatomic,strong) UILabel *statusLabel;

@end

@implementation NTESVideoChatNetStatusView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}

- (void)setup{
    self.backgroundColor = [UIColor clearColor];
    _statusImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _statusImageView.hidden = YES;
    _statusLabel     = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.hidden = YES;
    _statusLabel.backgroundColor = [UIColor clearColor];
    _statusLabel.textColor = UIColorFromRGB(0xffffff);
    _statusLabel.font = [UIFont systemFontOfSize:16.f];
    [self addSubview:_statusImageView];
    [self addSubview:_statusLabel];
}


- (void)refreshWithNetState:(NIMNetCallNetStatus)status{
    NSString *prefix = @"netstat_";
    NSString * imageName = [NSString stringWithFormat:@"%@%zd",prefix,status];
    self.statusImageView.image = [UIImage imageNamed:imageName];
    [self.statusImageView sizeToFit];
    self.statusLabel.hidden  = NO;
    self.statusImageView.hidden = NO;
    NSString *netState;
    switch (status) {
        case NIMNetCallNetStatusVeryGood:
            netState = @"网络通畅:";
            break;
        case NIMNetCallNetStatusGood:
            netState = @"网络正常:";
            break;
        case NIMNetCallNetStatusBad:
            netState = @"网络一般:";
            break;
        case NIMNetCallNetStatusVeryBad:
            netState = @"网络较差:";
            break;
        default:
            break;
    }
    self.statusLabel.text = netState;
    [self.statusLabel sizeToFit];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.statusLabel.centerY   = self.height * .5f;
    self.statusImageView.right = self.width;
    self.statusImageView.centerY = self.height * .5f;
}

@end
