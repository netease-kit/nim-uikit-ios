//
//  NIMInputAudioRecordIndicatorView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputAudioRecordIndicatorView.h"
#import "UIImage+NIM.h"

#define NIMKit_ViewWidth 160
#define NIMKit_ViewHeight 110

#define NIMKit_TimeFontSize 30
#define NIMKit_TipFontSize 15

@interface NIMInputAudioRecordIndicatorView(){
    UIImageView *_backgrounView;
    UIImageView *_tipBackgroundView;
}

@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation NIMInputAudioRecordIndicatorView
- (instancetype)init {
    self = [super init];
    if(self) {
        self.frame = CGRectMake(0, 0, NIMKit_ViewWidth, NIMKit_ViewHeight);
        _backgrounView = [[UIImageView alloc] initWithImage:[UIImage nim_imageInKit:@"icon_input_record_indicator"]];
        [self addSubview:_backgrounView];
        
        _tipBackgroundView = [[UIImageView alloc] initWithImage:[UIImage nim_imageInKit:@"icon_input_record_indicator_cancel"]];
        _tipBackgroundView.hidden = YES;
        _tipBackgroundView.frame = CGRectMake(0, NIMKit_ViewHeight - CGRectGetHeight(_tipBackgroundView.bounds), NIMKit_ViewWidth, CGRectGetHeight(_tipBackgroundView.bounds));
        [self addSubview:_tipBackgroundView];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.font = [UIFont boldSystemFontOfSize:NIMKit_TimeFontSize];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.text = @"00:00";
        [self addSubview:_timeLabel];
        
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipLabel.font = [UIFont systemFontOfSize:NIMKit_TipFontSize];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = @"手指上滑，取消发送";
        [self addSubview:_tipLabel];
        
        self.phase = AudioRecordPhaseEnd;
    }
    return self;
}

- (void)setRecordTime:(NSTimeInterval)recordTime {
    NSInteger minutes = (NSInteger)recordTime / 60;
    NSInteger seconds = (NSInteger)recordTime % 60;
    _timeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", minutes, seconds];
}

- (void)setPhase:(NIMAudioRecordPhase)phase {
    if(phase == AudioRecordPhaseStart) {
        [self setRecordTime:0];
    } else if(phase == AudioRecordPhaseCancelling) {
        _tipLabel.text = @"松开手指，取消发送";
        _tipBackgroundView.hidden = NO;
    } else {
        _tipLabel.text = @"手指上滑，取消发送";
        _tipBackgroundView.hidden = YES;
    }
}

- (void)layoutSubviews {
    CGSize size = [_timeLabel sizeThatFits:CGSizeMake(NIMKit_ViewWidth, MAXFLOAT)];
    _timeLabel.frame = CGRectMake(0, 36, NIMKit_ViewWidth, size.height);
    size = [_tipLabel sizeThatFits:CGSizeMake(NIMKit_ViewWidth, MAXFLOAT)];
    _tipLabel.frame = CGRectMake(0, NIMKit_ViewHeight - 10 - size.height, NIMKit_ViewWidth, size.height);
}


@end
