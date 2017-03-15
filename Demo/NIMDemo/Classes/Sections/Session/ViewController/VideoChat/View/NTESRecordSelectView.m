//
//  NTESRecordSelectView.m
//  NIM
//
//  Created by Simon Blue on 17/2/21.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESRecordSelectView.h"
#import "UIView+NTES.h"

#define NTESRecordSelectLabelTextColor 0x333333
#define NTESRecordSelectLabelTextGrayColor 0x999999
#define NTESRecordSelectStartButtonGrayColor 0xd0d0d0

@interface NTESRecordSelectView ()

@property (nonatomic ,strong) UIButton *audioConversation;

@property (nonatomic ,strong) UIButton *myMediaButton;

@property (nonatomic ,strong) UIButton *otherSideMediaButton;

@property (nonatomic ,strong) UIButton *cancelButton;

@property (nonatomic ,strong) UIButton *startButton;

@property (nonatomic ,strong) UILabel *audioConversationLable;

@property (nonatomic ,strong) UILabel *myMediaLable;

@property (nonatomic ,strong) UILabel *otherSideMediaLable;

@property (nonatomic ,strong) UILabel *title;

@property (nonatomic ,strong) UILabel *subTitle;

@property (nonatomic ,strong) UIView *horizontalSplitLine;

@property (nonatomic ,strong) UIView *verticalSplitLine;

@property (nonatomic ) BOOL isVideo;


@end

@implementation NTESRecordSelectView

-(instancetype)initWithFrame:(CGRect)frame Video:(BOOL)isVideo
{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 3.5f;
        self.layer.masksToBounds = YES;
        //title
        _title = [[UILabel alloc]init];
        [_title setText:@"选择录制内容"];
        [_title setFont:[UIFont systemFontOfSize:16]];
        _title.textColor = UIColorFromRGB(NTESRecordSelectLabelTextColor);
        _title.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_title];
        
        //subTitle
        _subTitle = [[UILabel alloc]init];
        [_subTitle setText:@"录制的内容会被单独保存"];
        _subTitle.textAlignment = NSTextAlignmentCenter;
        [_subTitle setFont:[UIFont systemFontOfSize:10]];
        _subTitle.textColor = UIColorFromRGB(NTESRecordSelectLabelTextGrayColor);
        [self addSubview:_subTitle];

        _audioConversationLable = [[UILabel alloc]init];
        [_audioConversationLable setText:@"语音对话"];
        _audioConversationLable.textAlignment = NSTextAlignmentLeft;
        _audioConversationLable.textColor = UIColorFromRGB(NTESRecordSelectLabelTextColor);

        [self addSubview:_audioConversationLable];

        _myMediaLable = [[UILabel alloc]init];
        [_myMediaLable setText: isVideo ? @"我的音视频" : @"我的音频"];
        _myMediaLable.textAlignment = NSTextAlignmentLeft;
        _myMediaLable.textColor = UIColorFromRGB(NTESRecordSelectLabelTextColor);

        [self addSubview:_myMediaLable];

        _otherSideMediaLable = [[UILabel alloc]init];
        [_otherSideMediaLable setText: isVideo ? @"对方音视频": @"对方音频"];
        _otherSideMediaLable.textAlignment = NSTextAlignmentLeft;
        _otherSideMediaLable.textColor = UIColorFromRGB(NTESRecordSelectLabelTextColor);

        [self addSubview:_otherSideMediaLable];

        //audioConversation
        _audioConversation = [UIButton buttonWithType:UIButtonTypeCustom];
        [_audioConversation addTarget:self action:@selector(audioConversationPressed) forControlEvents:UIControlEventTouchUpInside];
        [_audioConversation setImage:[UIImage imageNamed:@"record_not_selected"] forState:UIControlStateNormal];
        [_audioConversation setImage:[UIImage imageNamed:@"record_selected"] forState:UIControlStateSelected];
        [self addSubview:_audioConversation];
        [_audioConversation sizeToFit];

        //myMediaButton
        _myMediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_myMediaButton setImage:[UIImage imageNamed:@"record_not_selected"] forState:UIControlStateNormal];
        [_myMediaButton setImage:[UIImage imageNamed:@"record_selected"] forState:UIControlStateSelected];
        [_myMediaButton addTarget:self action:@selector(myMediaPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_myMediaButton];

        _otherSideMediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_otherSideMediaButton setImage:[UIImage imageNamed:@"record_not_selected"] forState:UIControlStateNormal];
        [_otherSideMediaButton setImage:[UIImage imageNamed:@"record_selected"] forState:UIControlStateSelected];
        [_otherSideMediaButton addTarget:self action:@selector(otherSideMediaPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_otherSideMediaButton];
        
        //splitLine
        _horizontalSplitLine = [[UIView alloc]init];
        _horizontalSplitLine.backgroundColor = [UIColor grayColor];
        [self addSubview:_horizontalSplitLine];

        //splitLine
        _verticalSplitLine = [[UIView alloc]init];
        _verticalSplitLine.backgroundColor = [UIColor grayColor];
        [self addSubview:_verticalSplitLine];
        
        _cancelButton = [[UIButton alloc]init];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:UIColorFromRGB(NTESRecordSelectLabelTextColor) forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cancelButton];
        
        _startButton = [[UIButton alloc]init];
        [_startButton setTitle:@"开始录制" forState:UIControlStateNormal];
        [_startButton setTitleColor:UIColorFromRGB(NTESRecordSelectLabelTextColor) forState:UIControlStateNormal];
        [_startButton setTitleColor:UIColorFromRGB(NTESRecordSelectStartButtonGrayColor) forState:UIControlStateDisabled];
        [_startButton addTarget:self action:@selector(startButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _startButton.enabled = NO;

        [self addSubview:_startButton];

    }
    return self;
}

-(void)layoutSubviews
{
    CGFloat labelHight = 15.f;
    CGFloat leftMarigin = 20.f;
    CGFloat rightMarigin = 20.f;

    _title.top = 25.f;
    _title.width = 100.f;
    _title.height = 17.f;
    _title.centerX = self.width * .5f;

    _subTitle.top = _title.bottom + 10.f;
    _subTitle.width = 250.f;
    _subTitle.height = 13.f;
    _subTitle.centerX = self.width * .5f;
    
    _audioConversationLable.top = _subTitle.bottom + 20.f;
    _audioConversationLable.width = 150.f;
    _audioConversationLable.height = labelHight;
    _audioConversationLable.left = leftMarigin;
    
    _myMediaLable.top = _audioConversationLable.bottom + 20.f;
    _myMediaLable.width = 150.f;
    _myMediaLable.height = labelHight;
    _myMediaLable.left = leftMarigin;
    
    _otherSideMediaLable.top = _myMediaLable.bottom + 20.f;
    _otherSideMediaLable.width = 150.f;
    _otherSideMediaLable.height = labelHight;
    _otherSideMediaLable.left = leftMarigin;
    
    _audioConversation.width = 23.f;
    _audioConversation.height = 23.f;
    _audioConversation.right = self.width -rightMarigin;
    _audioConversation.centerY = _audioConversationLable.centerY;

    _myMediaButton.width = 23.f;
    _myMediaButton.height = 23.f;
    _myMediaButton.right = self.width -rightMarigin;
    _myMediaButton.centerY = _myMediaLable.centerY;

    _otherSideMediaButton.width = 23.f;
    _otherSideMediaButton.height = 23.f;
    _otherSideMediaButton.right = self.width -rightMarigin;
    _otherSideMediaButton.centerY = _otherSideMediaLable.centerY;

    _horizontalSplitLine.top = _otherSideMediaButton.bottom + 25.f;
    _horizontalSplitLine.width = self.width;
    _horizontalSplitLine.height = .5f;
    _horizontalSplitLine.centerX = self.width * .5f;
    
    _cancelButton.width = self.width/2;
    _cancelButton.height = self.height - _horizontalSplitLine.bottom;
    _cancelButton.left = 0;
    _cancelButton.bottom = self.height;

    _verticalSplitLine.width = .5f;
    _verticalSplitLine.height = self.height - _horizontalSplitLine.bottom;
    _verticalSplitLine.left = _cancelButton.right;
    _verticalSplitLine.bottom = self.height;

    _startButton.width = self.width/2;
    _startButton.height = self.height - _horizontalSplitLine.bottom;
    _startButton.right = self.width ;
    _startButton.bottom = self.height;

}

-(void)audioConversationPressed
{
   _audioConversation.selected = !_audioConversation.selected;
    [self updateStartButton];
}

-(void)myMediaPressed
{
    _myMediaButton.selected = !_myMediaButton.selected;
    [self updateStartButton];
}

-(void)otherSideMediaPressed
{
    _otherSideMediaButton.selected = !_otherSideMediaButton.selected;
    [self updateStartButton];
}

-(void)cancelButtonPressed
{
    //先全部设为未选中状态
    _audioConversation.selected = NO;
    _myMediaButton.selected = NO;
    _otherSideMediaButton.selected = NO;
    [self updateStartButton];
    [self removeFromSuperview];
}

-(void)startButtonPressed
{
    if (_delegate&&[_delegate respondsToSelector:@selector(onRecordWithAudioConversation:myMedia:otherSideMedia:)]) {
        [_delegate onRecordWithAudioConversation:_audioConversation.selected
                                         myMedia:_myMediaButton.selected
                                  otherSideMedia:_otherSideMediaButton.selected];
    }
    _audioConversation.selected = NO;
    _myMediaButton.selected = NO;
    _otherSideMediaButton.selected = NO;
    [self updateStartButton];
    [self removeFromSuperview];
}

-(void)updateStartButton
{
    if (!_otherSideMediaButton.selected&&!_audioConversation.selected&&!_myMediaButton.selected) {
        _startButton.enabled = NO;
    }
    else
    {
        _startButton.enabled = YES;
    }
}

@end
