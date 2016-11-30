//
//  NIMMessageCell.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMMessageCell.h"
#import "NIMMessageModel.h"
#import "NIMAvatarImageView.h"
#import "NIMBadgeView.h"
#import "NIMSessionMessageContentView.h"
#import "NIMKitUtil.h"
#import "NIMSessionAudioContentView.h"
#import "UIView+NIM.h"
#import "NIMKitUIConfig.h"
#import "M80AttributedLabel.h"
#import "UIImage+NIM.h"
#import "NIMSessionUnknowContentView.h"
#import "NIMKitUIConfig.h"
#import "NIMKit.h"

@interface NIMMessageCell()<NIMPlayAudioUIDelegate,NIMMessageContentViewDelegate>{
    UILongPressGestureRecognizer *_longPressGesture;
    UIMenuController             *_menuController;
}

@property (nonatomic,strong) NIMMessageModel *model;

@property (nonatomic,copy)   NSArray *customViews;

@end

@implementation NIMMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = NIMKit_UIColorFromRGB(0xe4e7ec);
        [self makeComponents];
        [self makeGesture];
    }
    return self;
}

- (void)dealloc
{
    [self removeGestureRecognizer:_longPressGesture];
}

- (void)makeComponents
{
    //retyrBtn
    _retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_retryButton setImage:[UIImage nim_imageInKit:@"icon_message_cell_error"] forState:UIControlStateNormal];
    [_retryButton setImage:[UIImage nim_imageInKit:@"icon_message_cell_error"] forState:UIControlStateHighlighted];
    [_retryButton setFrame:CGRectMake(0, 0, 20, 20)];
    [_retryButton addTarget:self action:@selector(onRetryMessage:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_retryButton];
    
    //audioPlayedIcon
    _audioPlayedIcon = [NIMBadgeView viewWithBadgeTip:@""];
    [self.contentView addSubview:_audioPlayedIcon];
    
    //traningActivityIndicator
    _traningActivityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0,0,20,20)];
    [self.contentView addSubview:_traningActivityIndicator];
    
    //headerView
    _headImageView = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [_headImageView addTarget:self action:@selector(onTapAvatar:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_headImageView];
    
    //nicknamel
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.opaque = YES;
    _nameLabel.font = [UIFont systemFontOfSize:13.0];
    [_nameLabel setTextColor:[UIColor darkGrayColor]];
    [_nameLabel setHidden:YES];
    [self.contentView addSubview:_nameLabel];
    
    //readlabel
    _readLabel = [[UILabel alloc] init];
    _readLabel.backgroundColor = [UIColor clearColor];
    _readLabel.opaque = YES;
    _readLabel.font = [UIFont systemFontOfSize:13.0];
    [_readLabel setTextColor:[UIColor darkGrayColor]];
    [_readLabel setHidden:YES];
    [_readLabel setText:NSLocalizedString(@"已读", nil)];
    [_readLabel setBounds:CGRectMake(0, 0, 28, 20.0)];
    [self.contentView addSubview:_readLabel];
}

- (void)makeGesture{
    _longPressGesture= [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longGesturePress:)];
    [self addGestureRecognizer:_longPressGesture];
}

- (void)refreshData:(NIMMessageModel *)data{
    self.model = data;
    if ([self checkData]) {
        [self refresh];
    }
}

- (BOOL)checkData{
    return [self.model isKindOfClass:[NIMMessageModel class]];
}


- (void)setModel:(NIMMessageModel *)model{
    _model = model;
}

- (void)injected
{
    [self refreshData:_model];
}

- (void)refresh{
    [self addContentViewIfNotExist];
    [self addUserCustomViews];
    
    if ([self needShowAvatar])
    {
        [_headImageView setAvatarByMessage:self.model.message];
    }

    if([self needShowNickName])
    {
        NSString *nick = [NIMKitUtil showNick:self.model.message.from inMessage:self.model.message];
        [self.nameLabel setText:nick];
    }
    [_nameLabel setHidden:![self needShowNickName]];
    
    
    [_bubbleView refresh:self.model];
    [_bubbleView setNeedsLayout];
    
    BOOL isActivityIndicatorHidden = [self activityIndicatorHidden];
    if (isActivityIndicatorHidden)
    {
        [_traningActivityIndicator stopAnimating];
    }
    else
    {
        [_traningActivityIndicator startAnimating];
    }
    [_traningActivityIndicator setHidden:isActivityIndicatorHidden];
    [_retryButton setHidden:[self retryButtonHidden]];
    [_audioPlayedIcon setHidden:[self unreadHidden]];
    [_readLabel setHidden:[self readLabelHidden]];
    
    [self setNeedsLayout];
}

- (void)addContentViewIfNotExist
{
    if (_bubbleView == nil)
    {
        id<NIMCellLayoutConfig> layoutConfig = [[NIMKit sharedKit] layoutConfig];
        NSString *contentStr = [layoutConfig cellContent:self.model];
        NSAssert([contentStr length] > 0, @"should offer cell content class name");
        Class clazz = NSClassFromString(contentStr);
        NIMSessionMessageContentView *contentView =  [[clazz alloc] initSessionMessageContentView];
        NSAssert(contentView, @"can not init content view");
        _bubbleView = contentView;
        _bubbleView.delegate = self;
        NIMMessageType messageType = self.model.message.messageType;
        if (messageType == NIMMessageTypeAudio) {
            ((NIMSessionAudioContentView *)_bubbleView).audioUIDelegate = self;
        }
        [self.contentView addSubview:_bubbleView];
    }
}

- (void)addUserCustomViews
{
    for (UIView *view in self.customViews) {
        [view removeFromSuperview];
    }
    id<NIMCellLayoutConfig> layoutConfig = [[NIMKit sharedKit] layoutConfig];
    self.customViews = [layoutConfig customViews:self.model];

    for (UIView *view in self.customViews) {
        [self.contentView addSubview:view];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutAvatar];
    [self layoutNameLabel];
    [self layoutBubbleView];
    [self layoutRetryButton];
    [self layoutAudioPlayedIcon];
    [self layoutActivityIndicator];
    [self layoutReadLabel];
}

- (void)layoutAvatar
{
    BOOL needShow = [self needShowAvatar];
    _headImageView.hidden = !needShow;
    if (needShow) {
        _headImageView.frame = [self avatarViewRect];
    }
}

- (void)layoutNameLabel
{
    if ([self needShowNickName]) {
        CGFloat otherBubbleOriginX  = self.cellPaddingToNick;
        CGFloat otherBubbleOriginy  = -3.f;
        CGFloat otherNickNameWidth  = 200.f;
        CGFloat otherNickNameHeight = 20.f;
        CGFloat cellPaddingToProtrait = self.cellPaddingToProtrait;
        CGFloat avatarWidth = self.headImageView.nim_width;
        CGFloat myBubbleOriginX = self.nim_width - cellPaddingToProtrait - avatarWidth - self.cellPaddingToNick;
        _nameLabel.frame = self.model.shouldShowLeft ? CGRectMake(otherBubbleOriginX,otherBubbleOriginy,
                                                                  otherNickNameWidth, otherNickNameHeight) :        CGRectMake(myBubbleOriginX,otherBubbleOriginy,                   otherNickNameWidth,otherNickNameHeight) ;
    }
}

- (void)layoutBubbleView
{
    UIEdgeInsets contentInsets = self.model.bubbleViewInsets;
    if (!self.model.shouldShowLeft)
    {
        CGFloat protraitRightToBubble = 5.f;
        CGFloat right = self.model.shouldShowAvatar? CGRectGetMinX(self.headImageView.frame)  - protraitRightToBubble : self.nim_width;
        contentInsets.left = right - CGRectGetWidth(self.bubbleView.bounds);
    }
    _bubbleView.nim_left = contentInsets.left;
    _bubbleView.nim_top  = contentInsets.top;
}

- (void)layoutActivityIndicator
{
    if (_traningActivityIndicator.isAnimating) {
        CGFloat centerX = 0;
        if (!self.model.shouldShowLeft)
        {
            centerX = CGRectGetMinX(_bubbleView.frame) - [self retryButtonBubblePadding] - CGRectGetWidth(_traningActivityIndicator.bounds)/2;;
        }
        else
        {
            centerX = CGRectGetMaxX(_bubbleView.frame) + [self retryButtonBubblePadding] +  CGRectGetWidth(_traningActivityIndicator.bounds)/2;
        }
        self.traningActivityIndicator.center = CGPointMake(centerX,
                                                           _bubbleView.center.y);
    }
}

- (void)layoutRetryButton
{
    if (!_retryButton.isHidden) {
        CGFloat centerX = 0;
        if (self.model.shouldShowLeft)
        {
            centerX = CGRectGetMaxX(_bubbleView.frame) + [self retryButtonBubblePadding] +CGRectGetWidth(_retryButton.bounds)/2;
        }
        else
        {
            centerX = CGRectGetMinX(_bubbleView.frame) - [self retryButtonBubblePadding] - CGRectGetWidth(_retryButton.bounds)/2;
        }
        
        _retryButton.center = CGPointMake(centerX, _bubbleView.center.y);
    }
}

- (void)layoutAudioPlayedIcon{
    if (!_audioPlayedIcon.hidden) {
        CGFloat padding = [self audioPlayedIconBubblePadding];
        if (self.model.shouldShowLeft)
        {
            _audioPlayedIcon.nim_left = _bubbleView.nim_right + padding;
        }
        else
        {
            _audioPlayedIcon.nim_right = _bubbleView.nim_left - padding;
        }
        _audioPlayedIcon.nim_top = _bubbleView.nim_top;
    }
}

- (void)layoutReadLabel{
    
    if (!_readLabel.isHidden) {
        
        CGFloat left = _bubbleView.nim_left;
        CGFloat bottom = _bubbleView.nim_bottom;
        
        _readLabel.nim_left = left - CGRectGetWidth(_readLabel.bounds) - [self readLabelBubblePadding];
        _readLabel.nim_bottom = bottom;

    }
}

#pragma mark - NIMMessageContentViewDelegate
- (void)onCatchEvent:(NIMKitEvent *)event{
    if ([self.delegate respondsToSelector:@selector(onTapCell:)]) {
        [self.delegate onTapCell:event];
    }
}

#pragma mark - Action
- (void)onRetryMessage:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onRetryMessage:)]) {
        [self.delegate onRetryMessage:self.model.message];
    }
}

- (void)longGesturePress:(UIGestureRecognizer*)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] &&
        gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onLongPressCell:inView:)]) {
            [self.delegate onLongPressCell:self.model.message
                                       inView:_bubbleView];
        }
    }
}


#pragma mark - NIMPlayAudioUIDelegate
- (void)startPlayingAudioUI
{
    //更新DB
    NIMMessage * message = self.model.message;
    if (!message.isPlayed)
    {
        message.isPlayed  = YES;
        [self refreshData:self.model];
    }
}



#pragma mark - Private
- (CGRect)avatarViewRect
{
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat protraitImageWidth    = 42;//头像宽
    CGFloat selfProtraitOriginX   = (cellWidth - self.cellPaddingToProtrait - protraitImageWidth);
    return self.model.shouldShowLeft ? CGRectMake(self.cellPaddingToProtrait,0,protraitImageWidth, protraitImageWidth) :  CGRectMake(selfProtraitOriginX, 0,protraitImageWidth,protraitImageWidth);
}

- (BOOL)needShowAvatar
{
    return self.model.shouldShowAvatar;
}

- (BOOL)needShowNickName
{
    return self.model.shouldShowNickName;
}


- (BOOL)retryButtonHidden
{
    if (!self.model.message.isReceivedMsg) {
        return self.model.message.deliveryState != NIMMessageDeliveryStateFailed;
    } else
    {
        return self.model.message.attachmentDownloadState != NIMMessageAttachmentDownloadStateFailed;
    }
}

- (CGFloat)retryButtonBubblePadding {
    BOOL isFromMe = !self.model.shouldShowLeft;
    if (self.model.message.messageType == NIMMessageTypeAudio) {
        return isFromMe ? 15 : 13;
    }
    return isFromMe ? 8 : 10;
}

- (BOOL)activityIndicatorHidden
{
    if (!self.model.message.isReceivedMsg)
    {
        return self.model.message.deliveryState != NIMMessageDeliveryStateDelivering;
    }
    else
    {
        return self.model.message.attachmentDownloadState != NIMMessageAttachmentDownloadStateDownloading;
    }
}


- (BOOL)unreadHidden {
    if (self.model.message.messageType == NIMMessageTypeAudio) { //音频
        BOOL disable = NO;
        if ([self.model.sessionConfig respondsToSelector:@selector(disableAudioPlayedStatusIcon)]) {
            disable = [self.model.sessionConfig disableAudioPlayedStatusIcon];
        }
        BOOL hideIcon = self.model.message.attachmentDownloadState != NIMMessageAttachmentDownloadStateDownloaded || disable;

        return (hideIcon || self.model.message.isOutgoingMsg || [self.model.message isPlayed]);
    }
    return YES;
}

- (BOOL)readLabelHidden
{
    if (self.model.shouldShowReadLabel &&
        [self activityIndicatorHidden] &&
        [self unreadHidden])
    {
        return NO;
    }
    return YES;
}


- (CGFloat)audioPlayedIconBubblePadding{
    return 10.0;
}

- (CGFloat)readLabelBubblePadding{
    return 2.0;
}

- (CGFloat)cellPaddingToProtrait
{
    return self.model.avatarMargin;
}

- (CGFloat)cellPaddingToNick
{
    return self.model.nickNameMargin;
}

- (void)onTapAvatar:(id)sender{
    if ([self.delegate respondsToSelector:@selector(onTapAvatar:)]) {
        [self.delegate onTapAvatar:self.model.message.from];
    }
}

@end
