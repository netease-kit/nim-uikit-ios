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
#import "NIMContactSelectViewController.h"
#import "NIMInputAtCache.h"
#import "NIMKit.h"
#import "NIMKitInfoFetchOption.h"



@interface NIMInputView()<NIMInputToolBarDelegate,NIMInputEmoticonProtocol,NIMContactSelectDelegate>
{
    UIView  *_emoticonView;
}

@property (nonatomic, strong) NIMInputAudioRecordIndicatorView *audioRecordIndicator;
@property (nonatomic, assign) NIMAudioRecordPhase recordPhase;
@property (nonatomic, weak) id<NIMSessionConfig> inputConfig;
@property (nonatomic, weak) id<NIMInputDelegate> inputDelegate;
@property (nonatomic, weak) id<NIMInputActionDelegate> actionDelegate;
@property (nonatomic, strong) NIMInputAtCache *atCache;

@property (nonatomic, assign) NIMInputStatus status;
@property (nonatomic, assign) CGFloat containerHeight;

@property (nonatomic, assign) CGFloat keyBoardFrameTop; //键盘的frame的top值，屏幕高度 - 键盘高度，由于有旋转的可能，这个值只有当 键盘弹出时才有意义。

@end


@implementation NIMInputView

- (instancetype)initWithFrame:(CGRect)frame
                       config:(id<NIMSessionConfig>)config
{
    self = [super initWithFrame:frame];
    if (self) {
        _recording = NO;
        _recordPhase = AudioRecordPhaseEnd;
        _atCache = [[NIMInputAtCache alloc] init];
        _inputConfig = config;
        _containerHeight = 216.f;
        self.backgroundColor = [UIColor whiteColor];
        [self addListenEvents];
    }
    return self;
}

- (void)didMoveToWindow
{
    [self setup];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat toolBarHeight = self.toolBar.nim_height;
    CGFloat containerHeight = self.moreContainer.nim_height > self.emoticonContainer.nim_height? self.moreContainer.nim_height : self.emoticonContainer.nim_height;
    CGFloat height = toolBarHeight + containerHeight;
    CGFloat width = self.superview? self.superview.nim_width : self.nim_width;
    return CGSizeMake(width, height);
}


- (void)setInputDelegate:(id<NIMInputDelegate>)delegate
{
    _inputDelegate = delegate;
}

- (void)setInputActionDelegate:(id<NIMInputActionDelegate>)actionDelegate
{
    self.actionDelegate = actionDelegate;
    self.moreContainer.actionDelegate = self.actionDelegate;
}

- (void)reset
{
    self.nim_width = self.superview.nim_width;
    [self sizeToFit];
    [self refreshStatus:NIMInputStatusText];
    [self callDidChangeHeight];
}

- (void)refreshStatus:(NIMInputStatus)status
{
    self.status = status;
    [self.toolBar update:status];
    switch (status) {
        case NIMInputStatusText:
        case NIMInputStatusAudio:{
            if (self.toolBar.showsKeyboard) {
                self.nim_top = self.keyBoardFrameTop - self.toolBar.nim_height;
            }else{
                self.nim_top = self.superview.nim_height - self.toolBar.nim_height;
            }
            break;
        }
        case NIMInputStatusMore:
        case NIMInputStatusEmoticon:
            self.nim_bottom = self.superview.nim_height;
            break;
        default:
            break;
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
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

- (void)setup
{
    if (!_toolBar)
    {
        _toolBar = [[NIMInputToolBar alloc] initWithFrame:CGRectMake(0, 0, self.nim_width, 0)];
        [self addSubview:_toolBar];
        
        //设置placeholder
        NSString *placeholder = [NIMKitUIConfig sharedConfig].globalConfig.placeholder;
        [_toolBar setPlaceHolder:placeholder];
        
        //设置input bar 上的按钮
        if ([_inputConfig respondsToSelector:@selector(inputBarItemTypes)]) {
            NSArray *types = [_inputConfig inputBarItemTypes];
            [_toolBar setInputBarItemTypes:types];
        }
        
        _toolBar.delegate = self;
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
        [_toolBar.recordButton setHidden:YES];
        
        //设置最大输入字数
        NSInteger textInputLength = [NIMKitUIConfig sharedConfig].globalConfig.maxLength;
        self.maxTextLength = textInputLength;
        
        [self refreshStatus:NIMInputStatusText];
        [self sizeToFit];
        [self callDidChangeHeight];
    }
}

- (NIMInputMoreContainerView *)moreContainer
{
    if (!_moreContainer) {
        _moreContainer = [[NIMInputMoreContainerView alloc] initWithFrame:CGRectMake(0,0, self.nim_width,_containerHeight)];
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
        _emoticonContainer = [[NIMInputEmoticonContainerView alloc] initWithFrame:CGRectMake(0,0,
                                                                                             self.nim_width, _containerHeight)];
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
    [_toolBar setPlaceHolder:placeHolder];
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

#pragma mark - UIKeyboardNotification

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    if (!self.window) {
        return;//如果当前vc不是堆栈的top vc，则不需要监听
    }
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame   = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    self.keyBoardFrameTop = endFrame.origin.y;
    [self willShowKeyboardFromFrame:beginFrame toFrame:endFrame];
}

- (void)willShowKeyboardFromFrame:(CGRect)beginFrame toFrame:(CGRect)toFrame
{
    if (_keyBoardFrameTop == [UIScreen mainScreen].bounds.size.height) {
        if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(hideInputView)]) {
            [self.inputDelegate hideInputView];
        }
    }
    else
    {
        if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(showInputView)]) {
            [self.inputDelegate showInputView];
        }
    }
    [self sizeToFit];
    [self refreshStatus:self.status];
    [self callDidChangeHeight];
}



- (void)callDidChangeHeight
{
    if (_inputDelegate && [_inputDelegate respondsToSelector:@selector(inputViewSizeToHeight:showInputView:)]) {
        CGFloat bottomPadding = self.superview.nim_height - self.nim_top;
        CGPoint point = [self convertPoint:CGPointMake(0, self.toolBar.nim_bottom) toView:self.superview];
        BOOL showInputView = point.y != self.superview.nim_height;
        [_inputDelegate inputViewSizeToHeight:bottomPadding showInputView:showInputView];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.moreContainer.nim_top     = self.toolBar.nim_bottom;
    self.emoticonContainer.nim_top = self.toolBar.nim_bottom;
}


#pragma mark - button actions
- (void)onTouchVoiceBtn:(id)sender {
    // image change
    if (self.status!= NIMInputStatusAudio) {
        __weak typeof(self) weakSelf = self;
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
            [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf.toolBar.showsKeyboard) {
                            weakSelf.status = NIMInputStatusAudio;
                            weakSelf.toolBar.showsKeyboard = NO;
                        }else{
                            [weakSelf refreshStatus:NIMInputStatusAudio];
                            [weakSelf callDidChangeHeight];
                        }
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
    }
    else
    {
        if ([self.toolBar.inputBarItemTypes containsObject:@(NIMInputBarItemTypeTextAndRecord)]) {
            self.status = NIMInputStatusText;
            self.toolBar.showsKeyboard = YES;
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
    // cancel Recording
    self.recordPhase = AudioRecordPhaseEnd;
}

- (IBAction)onTouchRecordBtnDragInside:(id)sender {
    // "手指上滑，取消发送"
    self.recordPhase = AudioRecordPhaseRecording;
}
- (IBAction)onTouchRecordBtnDragOutside:(id)sender {
    // "松开手指，取消发送"
    self.recordPhase = AudioRecordPhaseCancelling;
}


- (void)onTouchEmoticonBtn:(id)sender
{
    if (self.status != NIMInputStatusEmoticon) {
        [self bringSubviewToFront:_emoticonContainer];
        [self.emoticonContainer setHidden:NO];
        [self.moreContainer setHidden:YES];
        if (self.toolBar.showsKeyboard) {
            self.status = NIMInputStatusEmoticon;
            self.toolBar.showsKeyboard = NO;
        }
        else
        {
            [self refreshStatus:NIMInputStatusEmoticon];
            [self callDidChangeHeight];
        }
        
    }
    else
    {
        self.status = NIMInputStatusText;
        self.toolBar.showsKeyboard = YES;
    }
}

- (void)onTouchMoreBtn:(id)sender {
    if (self.status != NIMInputStatusMore)
    {
        [self bringSubviewToFront:self.moreContainer];
        [self.moreContainer setHidden:NO];
        [self.emoticonContainer setHidden:YES];
        if (self.toolBar.showsKeyboard) {
            self.status = NIMInputStatusMore;
            self.toolBar.showsKeyboard = NO;
        }
        else
        {
            [self refreshStatus:NIMInputStatusMore];
            [self callDidChangeHeight];
        }
    }
    else
    {
        self.status = NIMInputStatusText;
        self.toolBar.showsKeyboard = YES;
    }
}

- (BOOL)endEditing:(BOOL)force
{
    BOOL endEditing = [super endEditing:force];
    if (!self.toolBar.showsKeyboard) {
        UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;
        void(^animations)() = ^{
            [self refreshStatus:NIMInputStatusText];
            if (self.inputDelegate && [self.inputDelegate respondsToSelector:@selector(inputViewSizeToHeight:showInputView:)]) {
                [self.inputDelegate inputViewSizeToHeight:self.toolBar.nim_height showInputView:NO];
            }
        };
        NSTimeInterval duration = 0.25;
        [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
    }
    return endEditing;
}


#pragma mark - NIMInputToolBarDelegate

- (BOOL)textViewShouldBeginEditing
{
    self.status = NIMInputStatusText;
    return YES;
}

- (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [self didPressSend:nil];
        return NO;
    }
    if ([text isEqualToString:@""] && range.length == 1 ) {//非选择删除
        [self onTextDelete];
        return NO;
    }
    if ([text isEqualToString:NIMInputAtStartChar] && self.session.sessionType == NIMSessionTypeTeam) {
        NIMContactTeamMemberSelectConfig *config = [[NIMContactTeamMemberSelectConfig alloc] init];
        config.needMutiSelected = NO;
        config.teamId = self.session.sessionId;
        config.filterIds = @[[NIMSDK sharedSDK].loginManager.currentAccount];
        NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
        vc.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
           [vc show];
        });
        
    }
    NSString *str = [self.toolBar.contentText stringByAppendingString:text];
    if (str.length > self.maxTextLength) {
        return NO;
    }
    return YES;
}


- (void)textViewDidChange
{
    if (self.actionDelegate && [self.actionDelegate respondsToSelector:@selector(onTextChanged:)])
    {
        [self.actionDelegate onTextChanged:self];
    }
}


- (void)toolBarDidChangeHeight:(CGFloat)height
{
    [self sizeToFit];
    [self refreshStatus:self.status];
    [self callDidChangeHeight];
}



#pragma mark - NIMContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts
{
    NSMutableString *str = [[NSMutableString alloc] initWithString:@""];
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.session = self.session;
    option.forbidaAlias = YES;
    for (NSString *uid in selectedContacts) {
        NSString *nick = [[NIMKit sharedKit].provider infoByUser:uid option:option].showName;
        [str appendString:nick];
        [str appendString:NIMInputAtEndChar];
        if (![selectedContacts.lastObject isEqualToString:uid]) {
            [str appendString:NIMInputAtStartChar];
        }
        NIMInputAtItem *item = [[NIMInputAtItem alloc] init];
        item.uid  = uid;
        item.name = nick;
        [self.atCache addAtItem:item];
    }
    [self.toolBar insertText:str];
}

#pragma mark - InputEmoticonProtocol
- (void)selectedEmoticon:(NSString*)emoticonID catalog:(NSString*)emotCatalogID description:(NSString *)description{
    if (!emotCatalogID) { //删除键
        [self onTextDelete];
    }else{
        if ([emotCatalogID isEqualToString:NIMKit_EmojiCatalog]) {
            [self.toolBar insertText:description];
        }else{
            //发送贴图消息
            if ([self.actionDelegate respondsToSelector:@selector(onSelectChartlet:catalog:)]) {
                [self.actionDelegate onSelectChartlet:emoticonID catalog:emotCatalogID];
            }
        }
        
        
    }
}

- (void)didPressSend:(id)sender{
    if ([self.actionDelegate respondsToSelector:@selector(onSendText:atUsers:)] && [self.toolBar.contentText length] > 0) {
        NSString *sendText = self.toolBar.contentText;
        [self.actionDelegate onSendText:sendText atUsers:[self.atCache allAtUid:sendText]];
        [self.atCache clean];
        self.toolBar.contentText = @"";
        [self.toolBar layoutIfNeeded];
    }
}



- (void)onTextDelete
{
    NSRange range = [self delRangeForEmoticon];
    if (range.length == 1) {
        //删的不是表情，可能是@
        NIMInputAtItem *item = [self delRangeForAt];
        if (item) {
            range = item.range;
        }
    }
    [self.toolBar deleteText:range];
}

- (NSRange)delRangeForEmoticon
{
    NSString *text = self.toolBar.contentText;
    NSRange range = [self rangeForPrefix:@"[" suffix:@"]"];
    NSRange selectedRange = [self.toolBar selectedRange];
    if (range.length > 1)
    {
        NSString *name = [text substringWithRange:range];
        NIMInputEmoticon *icon = [[NIMInputEmoticonManager sharedManager] emoticonByTag:name];
        range = icon? range : NSMakeRange(selectedRange.location - 1, 1);
    }
    return range;
}


- (NIMInputAtItem *)delRangeForAt
{
    NSString *text = self.toolBar.contentText;
    NSRange range = [self rangeForPrefix:NIMInputAtStartChar suffix:NIMInputAtEndChar];
    NSRange selectedRange = [self.toolBar selectedRange];
    NIMInputAtItem *item = nil;
    if (range.length > 1)
    {
        NSString *name = [text substringWithRange:range];
        NSString *set = [NIMInputAtStartChar stringByAppendingString:NIMInputAtEndChar];
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:set]];
        item = [self.atCache item:name];
        range = item? range : NSMakeRange(selectedRange.location - 1, 1);
    }
    item.range = range;
    return item;
}


- (NSRange)rangeForPrefix:(NSString *)prefix suffix:(NSString *)suffix
{
    NSString *text = self.toolBar.contentText;
    NSRange range = [self.toolBar selectedRange];
    NSString *selectedText = range.length ? [text substringWithRange:range] : text;
    NSInteger endLocation = range.location;
    if (endLocation <= 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    NSInteger index = -1;
    if ([selectedText hasSuffix:suffix]) {
        //往前搜最多20个字符，一般来讲是够了...
        NSInteger p = 20;
        for (NSInteger i = endLocation; i >= endLocation - p && i-1 >= 0 ; i--)
        {
            NSRange subRange = NSMakeRange(i - 1, 1);
            NSString *subString = [text substringWithRange:subRange];
            if ([subString compare:prefix] == NSOrderedSame)
            {
                index = i - 1;
                break;
            }
        }
    }
    return index == -1? NSMakeRange(endLocation - 1, 1) : NSMakeRange(index, endLocation - index);
}

@end
