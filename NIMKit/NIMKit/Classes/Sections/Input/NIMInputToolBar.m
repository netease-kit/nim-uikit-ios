//
//  NIMInputToolBar.m
//  NIMKit
//
//  Created by chris
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputToolBar.h"
#import "NIMGrowingTextView.h"
#import "UIView+NIM.h"
#import "UIImage+NIMKit.h"
#import "NIMInputBarItemType.h"

@interface NIMInputToolBar()<NIMGrowingTextViewDelegate>

@property (nonatomic,copy)  NSArray<NSNumber *> *types;

@property (nonatomic,copy)  NSDictionary *dict;

@property (nonatomic,strong) NIMGrowingTextView *inputTextView;

@property (nonatomic,assign) NIMInputStatus status;

@end

@implementation NIMInputToolBar

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        _voiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_voiceButton setImage:[UIImage nim_imageInKit:@"icon_toolview_voice_normal"] forState:UIControlStateNormal];
        [_voiceButton setImage:[UIImage nim_imageInKit:@"icon_toolview_voice_pressed"] forState:UIControlStateHighlighted];
        [_voiceButton sizeToFit];
        
        
        _emoticonBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_emoticonBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_emotion_normal"] forState:UIControlStateNormal];
        [_emoticonBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_emotion_pressed"] forState:UIControlStateHighlighted];
        [_emoticonBtn sizeToFit];
        
        _moreMediaBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreMediaBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_add_normal"] forState:UIControlStateNormal];
        [_moreMediaBtn setImage:[UIImage nim_imageInKit:@"icon_toolview_add_pressed"] forState:UIControlStateHighlighted];
        [_moreMediaBtn sizeToFit];
        
        _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_recordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_recordButton.titleLabel setFont:[UIFont systemFontOfSize:14.f]];
        [_recordButton setBackgroundImage:[[UIImage nim_imageInKit:@"icon_input_text_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(15,80,15,80) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
        _recordButton.exclusiveTouch = YES;
        [_recordButton sizeToFit];
        
        _inputTextBkgImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_inputTextBkgImage setImage:[[UIImage nim_imageInKit:@"icon_input_text_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(15,80,15,80) resizingMode:UIImageResizingModeStretch]];
        
        _inputTextView = [[NIMGrowingTextView alloc] initWithFrame:CGRectZero];
        _inputTextView.font = [UIFont systemFontOfSize:14.0f];
        _inputTextView.maxNumberOfLines = _maxNumberOfInputLines?:4;
        _inputTextView.minNumberOfLines = 1;
        _inputTextView.textColor = [UIColor blackColor];
        _inputTextView.backgroundColor = [UIColor clearColor];
        _inputTextView.nim_size = [_inputTextView intrinsicContentSize];
        _inputTextView.textViewDelegate = self;
        _inputTextView.returnKeyType = UIReturnKeySend;
        
        //顶部分割线
        UIView *sep = [[UIView alloc] initWithFrame:CGRectZero];
        sep.backgroundColor = [UIColor lightGrayColor];
        sep.nim_size = CGSizeMake(self.nim_width, .5f);
        sep.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:sep];
        
        //底部分割线
        _bottomSep = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomSep.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:_bottomSep];
        
        self.types = @[
                         @(NIMInputBarItemTypeVoice),
                         @(NIMInputBarItemTypeTextAndRecord),
                         @(NIMInputBarItemTypeEmoticon),
                         @(NIMInputBarItemTypeMore),
                       ];
    }
    return self;
}



- (void)setInputBarItemTypes:(NSArray<NSNumber *> *)types{
    self.types = types;
    [self setNeedsLayout];
}

- (NSString *)contentText
{
    return self.inputTextView.text;
}

- (void)setContentText:(NSString *)contentText
{
    self.inputTextView.text = contentText;
}

- (NSArray *)inputBarItemTypes
{
    return self.types;
}


- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat viewHeight = 0.0f;
    if (self.status == NIMInputStatusAudio) {
        viewHeight = 54.5;
    }else{
        //算出 TextView 的宽度
        [self adjustTextViewWidth:size.width];
        // TextView 自适应高度
        [self.inputTextView layoutIfNeeded];
        viewHeight = (int)self.inputTextView.frame.size.height;
        //得到 ToolBar 自身高度
        viewHeight = viewHeight + 2 * self.spacing + 2 * self.textViewPadding;
    }
    
    return CGSizeMake(size.width,viewHeight);
}

- (void)adjustTextViewWidth:(CGFloat)width
{
    CGFloat textViewWidth = 0;
    for (NSNumber *type in self.types) {
        if (type.integerValue == NIMInputBarItemTypeTextAndRecord) {
            continue;
        }
        UIView *view = [self subViewForType:type.integerValue];
        textViewWidth += view.nim_width;
    }
    textViewWidth += (self.spacing * (self.types.count + 1));
    self.inputTextView.nim_width  = width  - textViewWidth - 2 * self.textViewPadding;
}


- (void)layoutSubviews{
    [super layoutSubviews];
    
    if ([self.types containsObject:@(NIMInputBarItemTypeTextAndRecord)]) {
        self.inputTextBkgImage.nim_width  = self.inputTextView.nim_width  + 2 * self.textViewPadding;
        self.inputTextBkgImage.nim_height = self.inputTextView.nim_height + 2 * self.textViewPadding;
    }
    CGFloat left = 0;
    for (NSNumber *type in self.types) {
        UIView *view  = [self subViewForType:type.integerValue];
        if (!view.superview)
        {
            [self addSubview:view];
        }
        
        view.nim_left = left + self.spacing;
        view.nim_centerY = self.nim_height * .5f;
        left = view.nim_right;
    }
    
    [self adjustTextAndRecordView];
    
    //底部分割线
    CGFloat sepHeight = .5f;
    _bottomSep.nim_size     = CGSizeMake(self.nim_width, sepHeight);
    _bottomSep.nim_bottom   = self.nim_height - sepHeight;
}


- (void)adjustTextAndRecordView
{
    if ([self.types containsObject:@(NIMInputBarItemTypeTextAndRecord)])
    {
        self.inputTextView.center  = self.inputTextBkgImage.center;
        
        if (!self.inputTextView.superview)
        {
            //输入框
            [self addSubview:self.inputTextView];
        }
        if (!self.recordButton.superview)
        {
            //中间点击录音按钮
            self.recordButton.frame    = self.inputTextBkgImage.frame;
            [self addSubview:self.recordButton];
        }
    }
}

- (BOOL)showsKeyboard
{
    return [self.inputTextView isFirstResponder];
}


- (void)setShowsKeyboard:(BOOL)showsKeyboard
{
    if (showsKeyboard)
    {
        [self.inputTextView becomeFirstResponder];
    }
    else
    {
        [self.inputTextView resignFirstResponder];
    }
}


- (void)update:(NIMInputStatus)status
{
    self.status = status;
    [self sizeToFit];
    
    if (status == NIMInputStatusText || status == NIMInputStatusMore)
    {
        [self.recordButton setHidden:YES];
        [self.inputTextView setHidden:NO];
        [self.inputTextBkgImage setHidden:NO];
        [self updateVoiceBtnImages:YES];
        [self updateEmotAndTextBtnImages:YES];
    }
    else if(status == NIMInputStatusAudio)
    {
        [self.recordButton setHidden:NO];
        [self.inputTextView setHidden:YES];
        [self.inputTextBkgImage setHidden:YES];
        [self updateVoiceBtnImages:NO];
        [self updateEmotAndTextBtnImages:YES];
    }
    else
    {
        [self.recordButton setHidden:YES];
        [self.inputTextView setHidden:NO];
        [self.inputTextBkgImage setHidden:NO];
        [self updateVoiceBtnImages:YES];
        [self updateEmotAndTextBtnImages:YES];
    }
}

- (void)updateVoiceBtnImages:(BOOL)selected
{
    [self.voiceButton setImage:selected?[UIImage nim_imageInKit:@"icon_toolview_voice_normal"]:[UIImage nim_imageInKit:@"icon_toolview_keyboard_normal"] forState:UIControlStateNormal];
    [self.voiceButton setImage:selected?[UIImage nim_imageInKit:@"icon_toolview_voice_pressed"]:[UIImage nim_imageInKit:@"icon_toolview_keyboard_pressed"] forState:UIControlStateHighlighted];
}

- (void)updateEmotAndTextBtnImages:(BOOL)selected
{
    [self.emoticonBtn setImage:selected?[UIImage nim_imageInKit:@"icon_toolview_emotion_normal"]:[UIImage nim_imageInKit:@"icon_toolview_keyboard_normal"] forState:UIControlStateNormal];
    [self.emoticonBtn setImage:selected?[UIImage nim_imageInKit:@"icon_toolview_emotion_pressed"]:[UIImage nim_imageInKit:@"icon_toolview_keyboard_pressed"] forState:UIControlStateHighlighted];
}


#pragma mark - NIMGrowingTextViewDelegate
- (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)replacementText
{
    BOOL should = YES;
    if ([self.delegate respondsToSelector:@selector(shouldChangeTextInRange:replacementText:)]) {
        should = [self.delegate shouldChangeTextInRange:range replacementText:replacementText];
    }
    return should;
}


- (BOOL)textViewShouldBeginEditing:(NIMGrowingTextView *)growingTextView
{
    BOOL should = YES;
    if ([self.delegate respondsToSelector:@selector(textViewShouldBeginEditing)]) {
        should = [self.delegate textViewShouldBeginEditing];
    }
    return should;
}

- (void)textViewDidEndEditing:(NIMGrowingTextView *)growingTextView
{
    if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing)]) {
        [self.delegate textViewDidEndEditing];
    }
}


- (void)textViewDidChange:(NIMGrowingTextView *)growingTextView
{
    if ([self.delegate respondsToSelector:@selector(textViewDidChange)]) {
        [self.delegate textViewDidChange];
    }
}

- (void)willChangeHeight:(CGFloat)height
{
    CGFloat toolBarHeight = height + 2 * self.spacing;
    if ([self.delegate respondsToSelector:@selector(toolBarWillChangeHeight:)]) {
        [self.delegate toolBarWillChangeHeight:toolBarHeight];
    }
}

- (void)didChangeHeight:(CGFloat)height
{
    self.nim_height = height + 2 * self.spacing + 2 * self.textViewPadding;
    if ([self.delegate respondsToSelector:@selector(toolBarDidChangeHeight:)]) {
        [self.delegate toolBarDidChangeHeight:self.nim_height];
    }
}


#pragma mark - Get
- (UIView *)subViewForType:(NIMInputBarItemType)type{
    if (!_dict) {
        _dict = @{
                  @(NIMInputBarItemTypeVoice) : self.voiceButton,
                  @(NIMInputBarItemTypeTextAndRecord)  : self.inputTextBkgImage,
                  @(NIMInputBarItemTypeEmoticon) : self.emoticonBtn,
                  @(NIMInputBarItemTypeMore)     : self.moreMediaBtn
                };
    }
    return _dict[@(type)];
}

- (CGFloat)spacing{
    return 6.f;
}

- (CGFloat)textViewPadding
{
    return 3.f;
}


@end


@implementation NIMInputToolBar(InputText)

- (NSRange)selectedRange
{
    return self.inputTextView.selectedRange;
}

- (void)setPlaceHolder:(NSString *)placeHolder
{
    self.inputTextView.placeholderAttributedText = [[NSAttributedString alloc] initWithString:placeHolder attributes:@{NSForegroundColorAttributeName:[UIColor grayColor]}];
}

- (void)insertText:(NSString *)text
{
    NSRange range = self.inputTextView.selectedRange;
    NSString *replaceText = [self.inputTextView.text stringByReplacingCharactersInRange:range withString:text];
    range = NSMakeRange(range.location + text.length, 0);
    self.inputTextView.text = replaceText;
    self.inputTextView.selectedRange = range;
}

- (void)deleteText:(NSRange)range
{
    NSString *text = self.contentText;
    if (range.location + range.length <= [text length]
        && range.location != NSNotFound && range.length != 0)
    {
        NSString *newText = [text stringByReplacingCharactersInRange:range withString:@""];
        NSRange newSelectRange = NSMakeRange(range.location, 0);
        [self.inputTextView setText:newText];
        self.inputTextView.selectedRange = newSelectRange;
    }
}

@end
