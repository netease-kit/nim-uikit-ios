//
//  NIMInputView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputView.h"
#import <AVFoundation/AVFoundation.h>
#import "NIMInputMoreContainerView.h"
#import "NIMInputEmoticonContainerView.h"
#import "NIMInputAudioRecordIndicatorView.h"
#import "UIView+NIM.h"
#import "NIMInputEmoticonDefine.h"
#import "NIMInputEmoticonManager.h"
#import "NIMInputToolBar.h"
#import "UIImage+NIM.h"
#import "NIMGlobalMacro.h"
#import "NIMKitUIConfig.h"

@interface NIMInputView()<UITextViewDelegate,NIMInputEmoticonProtocol>
{
    UIView  *_emoticonView;
    NIMInputType  _inputType;
    CGFloat   _inputTextViewOlderHeight;
}

@property (nonatomic, strong) NIMInputAudioRecordIndicatorView *audioRecordIndicator;
@property (nonatomic, assign) NIMAudioRecordPhase recordPhase;
@property (nonatomic, weak) id<NIMSessionConfig> inputConfig;
@property (nonatomic, weak) id<NIMInputDelegate> inputDelegate;
@property (nonatomic, weak) id<NIMInputActionDelegate> actionDelegate;


@end


@implementation NIMInputView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _recording = NO;
        _recordPhase = AudioRecordPhaseEnd;
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self initUIComponents];
    }
    return self;
}

- (void)setInputConfig:(id<NIMSessionConfig>)config
{
    _inputConfig = config;
    
    //设置最大输入字数
    NSInteger textInputLength = [NIMKitUIConfig sharedConfig].globalConfig.maxLength;
    self.maxTextLength = textInputLength;
    
    //设置placeholder
    NSString *placeholder = [NIMKitUIConfig sharedConfig].globalConfig.placeholder;
    _toolBar.inputTextView.placeHolder = placeholder;
    
    //设置input bar 上的按钮
    if ([_inputConfig respondsToSelector:@selector(inputBarItemTypes)]) {
        NSArray *types = [_inputConfig inputBarItemTypes];
        [_toolBar setInputBarItemTypes:types];
    }
}

- (void)setInputDelegate:(id<NIMInputDelegate>)delegate
{
    _inputDelegate = delegate;

}

- (void)setInputActionDelegate:(id<NIMInputActionDelegate>)actionDelegate
{
    self.actionDelegate = actionDelegate;
}


- (NIMInputAudioRecordIndicatorView *)audioRecordIndicator {
    if(!_audioRecordIndicator) {
        _audioRecordIndicator = [[NIMInputAudioRecordIndicatorView alloc] init];
    }
    return _audioRecordIndicator;
}

- (void)setRecordPhase:(NIMAudioRecordPhase)recordPhase {
    NIMAudioRecordPhase prevPhase = _recordPhase;
    _recordPhase = recordPhase;
    self.audioRecordIndicator.phase = _recordPhase;
    if(prevPhase == AudioRecordPhaseEnd) {
        if(AudioRecordPhaseStart == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onStartRecording)]) {
                [_actionDelegate onStartRecording];
            }
        }
    } else if (prevPhase == AudioRecordPhaseStart || prevPhase == AudioRecordPhaseRecording) {
        if (AudioRecordPhaseEnd == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onStopRecording)]) {
                [_actionDelegate onStopRecording];
            }
        }
    } else if (prevPhase == AudioRecordPhaseCancelling) {
        if(AudioRecordPhaseEnd == _recordPhase) {
            if ([_actionDelegate respondsToSelector:@selector(onCancelRecording)]) {
                [_actionDelegate onCancelRecording];
            }
        }
    }
}

- (void)initUIComponents
{
    self.backgroundColor = [UIColor whiteColor];
    _toolBar = [[NIMInputToolBar alloc] initWithFrame:CGRectZero];
    [_toolBar.emoticonBtn addTarget:self action:@selector(onTouchEmoticonBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar.moreMediaBtn addTarget:self action:@selector(onTouchMoreBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar.voiceBtn addTarget:self action:@selector(onTouchVoiceBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDown:) forControlEvents:UIControlEventTouchDown];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar.recordButton addTarget:self action:@selector(onTouchRecordBtnUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    _toolBar.nim_size = [_toolBar sizeThatFits:CGSizeMake(self.nim_width, CGFLOAT_MAX)];
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_toolBar.recordButton setTitle:@"按住说话" forState:UIControlStateNormal];
    [self addSubview:_toolBar];
    _toolBar.inputTextView.delegate = self;
    
    [_toolBar.inputTextView setCustomUI];
    _inputType = InputTypeText;
    _inputBottomViewHeight = 0;
    _inputTextViewOlderHeight = [[[NIMKitUIConfig sharedConfig] globalConfig] topInputViewHeight];
    [_toolBar.recordButton setHidden:YES];
    [self addListenEvents];
}

- (NIMInputMoreContainerView *)moreContainer
{
    if (!_moreContainer) {
        _moreContainer = [[NIMInputMoreContainerView alloc] initWithFrame:CGRectMake(0, [[[NIMKitUIConfig sharedConfig] globalConfig] topInputViewHeight], self.nim_width,
                                                                                     [[[NIMKitUIConfig sharedConfig] globalConfig] bottomInputViewHeight])];
        _moreContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _moreContainer.hidden   = YES;
        _moreContainer.config   = _inputConfig;
        _moreContainer.actionDelegate = self.actionDelegate;
        [self addSubview:_moreContainer];
    }
    return _moreContainer;
}

- (NIMInputEmoticonContainerView *)emoticonContainer
{
    if (!_emoticonContainer) {
        _emoticonContainer = [[NIMInputEmoticonContainerView alloc] initWithFrame:CGRectMake(0, [[[NIMKitUIConfig sharedConfig] globalConfig] topInputViewHeight],
                                                                                             self.nim_width, [[[NIMKitUIConfig sharedConfig] globalConfig] bottomInputViewHeight])];
        _emoticonContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _emoticonContainer.delegate = self;
        _emoticonContainer.hidden = YES;
        _emoticonContainer.config = _inputConfig;
        [self addSubview:_emoticonContainer];
    }
    return _emoticonContainer;
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _emoticonContainer.delegate = nil;
    _toolBar.inputTextView.delegate = nil;
}

- (void)setRecording:(BOOL)recording {
    if(recording) {
        self.audioRecordIndicator.center = self.superview.center;
        [self.superview addSubview:self.audioRecordIndicator];
        self.recordPhase = AudioRecordPhaseRecording;
    } else {
        [self.audioRecordIndicator removeFromSuperview];
        self.recordPhase = AudioRecordPhaseEnd;
    }
    _recording = recording;
}

#pragma mark - 外部接口
- (void)setInputTextPlaceHolder:(NSString*)placeHolder
{
    [_toolBar.inputTextView setPlaceHolder:placeHolder];
}

- (void)updateAudioRecordTime:(NSTimeInterval)time {
    self.audioRecordIndicator.recordTime = time;
}

- (void)updateVoicePower:(float)power {
    
}

#pragma mark - private methods
- (void)addListenEvents
{
    // 显示键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)updateAllButtonImages
{
    if (_inputType == InputTypeText || _inputType == InputTypeMedia)
    {
        [self updateVoiceBtnImages:YES];
        [self updateEmotAndTextBtnImages:YES];
        [_toolBar.recordButton setHidden:YES];
        [_toolBar.inputTextView setHidden:NO];
        [_toolBar.inputTextBkgImage setHidden:NO];
    }
    else if(_inputType == InputTypeAudio)
    {
        [self updateVoiceBtnImages:NO];
        [self updateEmotAndTextBtnImages:YES];
        [_toolBar.recordButton setHidden:NO];
        [_toolBar.inputTextView setHidden:YES];
        [_toolBar.inputTextBkgImage setHidden:YES];
    }
    else
    {
        [self updateVoiceBtnImages:YES];
        [self updateEmotAndTextBtnImages:YES];
        [_toolBar.recordButton setHidden:YES];
        [_toolBar.inputTextView setHidden:NO];
        [_toolBar.inputTextBkgImage setHidden:NO];
    }
}

- (CGFloat)getTextViewContentH:(UITextView *)textView
{
    return textView.contentSize.height;
}

- (void)updateVoiceBtnImages:(BOOL)selected
{
    [_toolBar.voiceBtn setImage:selected?[UIImage nim_imageInKit:@"icon_toolview_voice_normal"]:[UIImage nim_imageInKit:@"icon_toolview_keyboard_normal"] forState:UIControlStateNormal];
    [_toolBar.voiceBtn setImage:selected?[UIImage nim_imageInKit:@"icon_toolview_voice_pressed"]:[UIImage nim_imageInKit:@"icon_toolview_keyboard_pressed"] forState:UIControlStateHighlighted];
}

- (void)updateEmotAndTextBtnImages:(BOOL)selected
{
    [_toolBar.emoticonBtn setImage:selected?[UIImage nim_imageInKit:@"icon_toolview_emotion_normal"]:[UIImage nim_imageInKit:@"icon_toolview_keyboard_normal"] forState:UIControlStateNormal];
    [_toolBar.emoticonBtn setImage:selected?[UIImage nim_imageInKit:@"icon_toolview_emotion_pressed"]:[UIImage nim_imageInKit:@"icon_toolview_keyboard_pressed"] forState:UIControlStateHighlighted];
}

#pragma mark - UIKeyboardNotification

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    if (!self.window) {
        return;//如果当前vc不是堆栈的top vc，则不需要监听
    }
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame   = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    void(^animations)() = ^{
        [self willShowKeyboardFromFrame:beginFrame toFrame:endFrame];
    };
    [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
}

- (void)willShowKeyboardFromFrame:(CGRect)beginFrame toFrame:(CGRect)toFrame
{
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    BOOL ios7 = ([[[UIDevice currentDevice] systemVersion] doubleValue] < 8.0);
    //IOS7的横屏UIDevice的宽高不会发生改变，需要手动去调整
    if (ios7 && (orientation == UIDeviceOrientationLandscapeLeft
                 || orientation == UIDeviceOrientationLandscapeRight)) {
        toFrame.origin.y -= _inputBottomViewHeight;
        if (toFrame.origin.y == [[UIScreen mainScreen] bounds].size.width) {
            [self willShowBottomHeight:0];
        }else{
            [self willShowBottomHeight:toFrame.size.width];
        }
    }else{
        toFrame.origin.y -= _inputBottomViewHeight;
        if (toFrame.origin.y == [[UIScreen mainScreen] bounds].size.height) {
            [self willShowBottomHeight:0];
        }else{
            [self willShowBottomHeight:toFrame.size.height];
        }
    }
}

- (void)willShowBottomHeight:(CGFloat)bottomHeight
{
    CGRect fromFrame = self.frame;
    CGFloat toHeight = self.toolBar.frame.size.height + bottomHeight;
    CGRect toFrame = CGRectMake(fromFrame.origin.x, fromFrame.origin.y + (fromFrame.size.height - toHeight), fromFrame.size.width, toHeight);
    
    if(bottomHeight == 0 && self.frame.size.height == self.toolBar.frame.size.height)
    {
        return;
    }
    self.frame = toFrame;
    
    if (bottomHeight == 0) {
        if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(hideInputView)]) {
            [self.inputDelegate hideInputView];
        }
    } else
    {
        if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(showInputView)]) {
            [self.inputDelegate showInputView];
        }
    }
    if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(inputViewSizeToHeight:showInputView:)]) {
        [self.inputDelegate inputViewSizeToHeight:toHeight showInputView:!(bottomHeight==0)];
    }
}

- (void)inputTextViewToHeight:(CGFloat)toHeight
{
    toHeight = MAX([[[NIMKitUIConfig sharedConfig] globalConfig] topInputViewHeight], toHeight);
    toHeight = MIN([[[NIMKitUIConfig sharedConfig] globalConfig] bottomInputViewHeight], toHeight);
    
    if (toHeight != _inputTextViewOlderHeight)
    {
        CGFloat changeHeight = toHeight - _inputTextViewOlderHeight;
        CGRect rect = self.frame;
        rect.size.height += changeHeight;
        rect.origin.y -= changeHeight;
        self.frame = rect;
        
        rect = self.toolBar.frame;
        rect.size.height += changeHeight;
        [self updateInputTopViewFrame:rect];
        
        if (self.toolBar.inputTextView.text.length) {
            [self.toolBar.inputTextView setContentOffset:CGPointMake(0.0f, (self.toolBar.inputTextView.contentSize.height - self.toolBar.inputTextView.frame.size.height)) animated:YES];
        }
        _inputTextViewOlderHeight = toHeight;
        
        if (_inputDelegate && [_inputDelegate respondsToSelector:@selector(inputViewSizeToHeight:showInputView:)]) {
            [_inputDelegate inputViewSizeToHeight:self.frame.size.height showInputView:YES];
        }
    }
}

- (void)updateInputTopViewFrame:(CGRect)rect
{
    self.toolBar.frame             = rect;
    [self.toolBar layoutIfNeeded];
    self.moreContainer.nim_top     = self.toolBar.nim_bottom;
    self.emoticonContainer.nim_top = self.toolBar.nim_bottom;
}


#pragma mark - button actions
- (void)onTouchVoiceBtn:(id)sender {
    // image change
    if (_inputType!= InputTypeAudio) {
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
            [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _inputType = InputTypeAudio;
                        if ([self.toolBar.inputTextView isFirstResponder]) {
                            _inputBottomViewHeight = 0;
                            [self.toolBar.inputTextView resignFirstResponder];
                        } else if (_inputBottomViewHeight > 0)
                        {
                            _inputBottomViewHeight = 0;
                            [self willShowBottomHeight:_inputBottomViewHeight];
                        }
                        [self inputTextViewToHeight:[[[NIMKitUIConfig sharedConfig] globalConfig] topInputViewHeight]];;
                        [self updateAllButtonImages];
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"没有麦克风权限"
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    } else
    {
        if (self.toolBar.inputTextView.superview) {
            _inputType = InputTypeText;
            [self inputTextViewToHeight:[self getTextViewContentH:self.toolBar.inputTextView]];;
            [self.toolBar.inputTextView becomeFirstResponder];
            [self updateAllButtonImages];
        }
    }
}

- (IBAction)onTouchRecordBtnDown:(id)sender {
    self.recordPhase = AudioRecordPhaseStart;
}
- (IBAction)onTouchRecordBtnUpInside:(id)sender {
    // finish Recording
    self.recordPhase = AudioRecordPhaseEnd;
}
- (IBAction)onTouchRecordBtnUpOutside:(id)sender {
    //TODO cancel Recording
    self.recordPhase = AudioRecordPhaseEnd;
}

- (IBAction)onTouchRecordBtnDragInside:(id)sender {
    //TODO @"手指上滑，取消发送"
    self.recordPhase = AudioRecordPhaseRecording;
}
- (IBAction)onTouchRecordBtnDragOutside:(id)sender {
    //TODO @"松开手指，取消发送"
    self.recordPhase = AudioRecordPhaseCancelling;
}


- (void)onTouchEmoticonBtn:(id)sender
{
    if (_inputType != InputTypeEmot) {
        _inputType = InputTypeEmot;
        _inputBottomViewHeight = [[[NIMKitUIConfig sharedConfig] globalConfig] bottomInputViewHeight];
        [self bringSubviewToFront:_emoticonContainer];
        [self.emoticonContainer setHidden:NO];
        [self.moreContainer setHidden:YES];
        if ([self.toolBar.inputTextView isFirstResponder]) {
            [self.toolBar.inputTextView resignFirstResponder];
        }
        [UIView animateWithDuration:0.25 animations:^{
            [self willShowBottomHeight:_inputBottomViewHeight];
        }];
    }else
    {
        _inputBottomViewHeight = 0;
        _inputType = InputTypeText;
        [self.toolBar.inputTextView becomeFirstResponder];
    }
    [self updateAllButtonImages];
}

- (void)onTouchMoreBtn:(id)sender {
    if (_inputType != InputTypeMedia) {
        _inputType = InputTypeMedia;
        [self bringSubviewToFront:self.moreContainer];
        [self.moreContainer setHidden:NO];
        [self.emoticonContainer setHidden:YES];
        _inputBottomViewHeight = [[[NIMKitUIConfig sharedConfig] globalConfig] bottomInputViewHeight];
        if ([self.toolBar.inputTextView isFirstResponder]) {
            [self.toolBar.inputTextView resignFirstResponder];
        }
        [UIView animateWithDuration:0.25 animations:^{
            [self willShowBottomHeight:_inputBottomViewHeight];
        }];
    } else
    {
        _inputBottomViewHeight = 0;
        _inputType = InputTypeText;
        [self.toolBar.inputTextView becomeFirstResponder];
    }
    [self updateAllButtonImages];
}

- (BOOL)endEditing:(BOOL)force
{
    BOOL endEditing = [super endEditing:force];
    if (![self.toolBar.inputTextView isFirstResponder]) {
        _inputBottomViewHeight = 0.0;
        _inputType = InputTypeText;
        UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;
        void(^animations)() = ^{
            [self willShowKeyboardFromFrame:CGRectZero toFrame:CGRectZero];
        };
        NSTimeInterval duration = 0.25;
        [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
    }
    return endEditing;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    _inputType = InputTypeText;
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        if ([self.actionDelegate respondsToSelector:@selector(onSendText:)] && [textView.text length] > 0) {
            [self.actionDelegate onSendText:textView.text];
            textView.text = @"";
            [textView layoutIfNeeded];
            [self inputTextViewToHeight:[self getTextViewContentH:textView]];;
        }
        return NO;
    }
    NSString *str = [textView.text stringByAppendingString:text];
    if (str.length > self.maxTextLength) {
        return NO;
    }
    return YES;
}


- (void)textViewDidChange:(UITextView *)textView
{
    if (self.actionDelegate && [self.actionDelegate respondsToSelector:@selector(onTextChanged:)])
    {
        [self.actionDelegate onTextChanged:self];
    }
    [self inputTextViewToHeight:[self getTextViewContentH:textView]];
}


#pragma mark - InputEmoticonProtocol
- (void)selectedEmoticon:(NSString*)emoticonID catalog:(NSString*)emotCatalogID description:(NSString *)description{
    if (!emotCatalogID) { //删除键
        NSRange range = [self rangeForEmoticon];
        [self deleteTextRange:range];
    }else{
        if ([emotCatalogID isEqualToString:NIMKit_EmojiCatalog]) {
            [self.toolBar.inputTextView insertText:description];
        }else{
            //发送贴图消息
            if ([self.actionDelegate respondsToSelector:@selector(onSelectChartlet:catalog:)]) {
                [self.actionDelegate onSelectChartlet:emoticonID catalog:emotCatalogID];
            }
        }
        
        
    }
}

- (void)didPressSend:(id)sender{
    if ([self.actionDelegate respondsToSelector:@selector(onSendText:)] && [self.toolBar.inputTextView.text length] > 0) {
        [self.actionDelegate onSendText:self.toolBar.inputTextView.text];
        self.toolBar.inputTextView.text = @"";
        [self.toolBar.inputTextView layoutIfNeeded];
        [self inputTextViewToHeight:[self getTextViewContentH:self.toolBar.inputTextView]];;
    }
}

- (void)deleteTextRange: (NSRange)range
{
    NSString *text = [self.toolBar.inputTextView text];
    if (range.location + range.length <= [text length]
        && range.location != NSNotFound && range.length != 0)
    {
        NSString *newText = [text stringByReplacingCharactersInRange:range withString:@""];
        NSRange newSelectRange = NSMakeRange(range.location, 0);
        [self.toolBar.inputTextView setText:newText];
        [self.toolBar.inputTextView setSelectedRange:newSelectRange];
        [self textViewDidChange:self.toolBar.inputTextView];
    }
}

- (NSRange)rangeForEmoticon
{
    NSString *text = [self.toolBar.inputTextView text];
    NSRange range = [self.toolBar.inputTextView selectedRange];
    NSString *selectedText = range.length ? [text substringWithRange:range] : text;
    NSInteger endLocation =range.location;
    if (endLocation <= 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    NSInteger index = -1;
    if ([selectedText hasSuffix:@"]"]) {
        for (NSInteger i = endLocation; i >= endLocation - 6 && i-1 >= 0 ; i--)
        {
            NSRange subRange = NSMakeRange(i - 1, 1);
            NSString *subString = [text substringWithRange:subRange];
            if ([subString compare:@"["] == NSOrderedSame)
            {
                index = i - 1;
                break;
            }
        }
    }
    if (index == -1)
    {
        return NSMakeRange(endLocation - 1, 1);
    }
    else
    {
        NSRange emoticonRange = NSMakeRange(index, endLocation - index);
        NSString *name = [text substringWithRange:emoticonRange];
        NIMInputEmoticon *icon = [[NIMInputEmoticonManager sharedManager] emoticonByTag:name];
        return icon ? emoticonRange : NSMakeRange(endLocation - 1, 1);
    }
}


@end
