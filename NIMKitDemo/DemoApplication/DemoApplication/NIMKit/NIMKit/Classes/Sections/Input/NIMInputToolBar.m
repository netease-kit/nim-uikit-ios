//
//  NIMInputToolBar.m
//  NIMKit
//
//  Created by chris
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputToolBar.h"
#import "NIMInputTextView.h"
#import "UIView+NIM.h"
#import "UIImage+NIM.h"

@interface NIMInputToolBar()

@property (nonatomic,strong) UIView *sep;

@end

@implementation NIMInputToolBar

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        _voiceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_voiceBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_voice_normal"] forState:UIControlStateNormal];
        [_voiceBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_voice_pressed"] forState:UIControlStateHighlighted];
        [_voiceBtn sizeToFit];
        [self addSubview:_voiceBtn];
        
        
        _emoticonBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_emoticonBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_emotion_normal"] forState:UIControlStateNormal];
        [_emoticonBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_emotion_pressed"] forState:UIControlStateHighlighted];
        [_emoticonBtn sizeToFit];
        [self addSubview:_emoticonBtn];
        
        _moreMediaBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreMediaBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_add_normal"] forState:UIControlStateNormal];
        [_moreMediaBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_add_pressed"] forState:UIControlStateHighlighted];
        [_moreMediaBtn sizeToFit];
        [self addSubview:_moreMediaBtn];
        
        _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_recordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_recordButton.titleLabel setFont:[UIFont systemFontOfSize:14.f]];
        [_recordButton setBackgroundImage:[[UIImage nim_imageInKit:@"icon_input_text_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(15,80,15,80) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
        [_recordButton sizeToFit];
        [self addSubview:_recordButton];
        
        _inputTextBkgImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_inputTextBkgImage setImage:[[UIImage nim_imageInKit:@"icon_input_text_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(15,80,15,80) resizingMode:UIImageResizingModeStretch]];
        [self addSubview:_inputTextBkgImage];
        
        _inputTextView = [[NIMInputTextView alloc] initWithFrame:CGRectZero];
        [self addSubview:_inputTextView];
        
        _sep = [[UIView alloc] initWithFrame:CGRectZero];
        _sep.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:_sep];
    }
    return self;
}


- (CGSize)sizeThatFits:(CGSize)size{
    CGFloat height = 46.f;
    return CGSizeMake(size.width,height);
}


- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat spacing               = 6.f;
    CGFloat textViewMargin        = 2.f;
    //左边话筒按钮
    self.voiceBtn.nim_left        = spacing;
    self.voiceBtn.nim_centerY     = self.nim_height * .5f;
    //中间输入框按钮
    self.inputTextBkgImage.nim_width = self.nim_width - 5 * spacing - self.emoticonBtn.nim_width - self.voiceBtn.nim_width - self.moreMediaBtn.nim_width;
    self.inputTextBkgImage.nim_height = self.nim_height - spacing * 2;
    self.inputTextBkgImage.nim_left = self.voiceBtn.nim_right + spacing;
    self.inputTextBkgImage.nim_centerY = self.voiceBtn.nim_centerY;
    self.inputTextView.frame = CGRectInset(self.inputTextBkgImage.frame, textViewMargin, textViewMargin);
    //中间点击录音按钮
    self.recordButton.frame    = self.inputTextBkgImage.frame;
    //右边表情按钮
    self.emoticonBtn.nim_left     = self.recordButton.nim_right + spacing;
    self.emoticonBtn.nim_centerY  = self.nim_height * .5f;
    //右边加号按钮
    self.moreMediaBtn.nim_left    = self.emoticonBtn.nim_right + spacing;
    self.moreMediaBtn.nim_centerY = self.nim_height * .5f;
    CGFloat sepHeight = .5f;
    //底部分割线
    _sep.nim_size     = CGSizeMake(self.nim_width, sepHeight);
    _sep.nim_bottom   = self.nim_height - sepHeight;
}
@end
