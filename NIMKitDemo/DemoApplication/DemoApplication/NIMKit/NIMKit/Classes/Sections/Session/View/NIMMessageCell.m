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
#import "NIMDefaultValueMaker.h"
#import "NIMAttributedLabel.h"
#import "UIImage+NIM.h"
#import "NIMSessionUnknowContentView.h"

@interface NIMMessageCell()<NIMPlayAudioUIDelegate,NIMMessageContentViewDelegate>{
    UILongPressGestureRecognizer *_longPressGesture;
    UIMenuController             *_menuController;
}

@property (nonatomic,strong) NIMMessageModel *model;

@end

@implementation NIMMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        //
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
    [_retryButton setFrame:CGRectMake(0, 0, 25, 25)];
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
    _nameLabel.opaque = YES;
    _nameLabel.font = [UIFont systemFontOfSize:12.0];
    [_nameLabel setTextColor:[UIColor darkGrayColor]];
    [_nameLabel setHidden:YES];
    [self.contentView addSubview:_nameLabel];
    
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

- (void)refresh{
    [self addContentViewIfNotExist];
    
    if ([self needShowAvatar])
    {
        NSString *from = self.model.message.from;
        NIMSession *avatarSession = [NIMSession session:from
                                                   type:NIMSessionTypeP2P];
        [_headImageView setAvatarBySession:avatarSession];
    }
    
    if([self needShowNickName])
    {
        NSString *nick = [NIMKitUtil showNick:self.model.message.from inSession:self.model.message.session];
        [_nameLabel setText:nick];
    }
    [_nameLabel setHidden:![self needShowNickName]];
    [_bubbleView refresh:self.model];
    
    BOOL isActivityIndicatorHidden = [self activityIndicatorHidden];
    if (isActivityIndicatorHidden) {
        [_traningActivityIndicator stopAnimating];
    } else
    {
        [_traningActivityIndicator startAnimating];
    }
    [_traningActivityIndicator setHidden:isActivityIndicatorHidden];
    [_retryButton setHidden:[self retryButtonHidden]];
    [_audioPlayedIcon setHidden:[self unreadHidden]];
    [self setNeedsLayout];
}

- (void)addContentViewIfNotExist
{
    if (_bubbleView == nil)
    {
        id<NIMCellLayoutConfig> config = self.model.layoutConfig;
        NSString *contentStr = [config cellContent:self.model];
        if (!contentStr.length) {
            //针对上层实现了cellContent:接口，但是没有覆盖全的情况
            NIMCellLayoutDefaultConfig *config = [NIMDefaultValueMaker sharedMaker].cellLayoutDefaultConfig;
            contentStr = [config cellContent:self.model];
        }
        Class clazz = NSClassFromString(contentStr);
        NIMSessionMessageContentView *contentView =  [[clazz alloc] initSessionMessageContentView];
        if (!contentView) {
            //还是拿不到那就只好unsupported了
            contentView = [self unSupportContentView];
        }
        _bubbleView = contentView;
        _bubbleView.delegate = self;
        NIMMessageType messageType = self.model.message.messageType;
        if (messageType == NIMMessageTypeAudio) {
            ((NIMSessionAudioContentView *)_bubbleView).audioUIDelegate = self;
        }
        [self.contentView addSubview:_bubbleView];
    }
}

- (NIMSessionMessageContentView *)unSupportContentView{
    return [[NIMSessionUnknowContentView alloc] initSessionMessageContentView];
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
        CGFloat otherBubbleOriginX  = 55.f;
        CGFloat otherNickNameHeight = 20.f;
        _nameLabel.frame = CGRectMake(otherBubbleOriginX + 2, -3,
                                      200, otherNickNameHeight);
    }
}

- (void)layoutBubbleView
{
    UIEdgeInsets contentInsets = self.model.bubbleViewInsets;
    if (self.model.message.isOutgoingMsg) {
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
        if (self.model.message.isOutgoingMsg) {
            centerX = CGRectGetMinX(_bubbleView.frame) - [self retryButtonBubblePadding] - CGRectGetWidth(_traningActivityIndicator.bounds)/2;;
        } else
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
        if (!self.model.message.isOutgoingMsg) {
            centerX = CGRectGetMaxX(_bubbleView.frame) + [self retryButtonBubblePadding] +CGRectGetWidth(_retryButton.bounds)/2;
        } else
        {
            centerX = CGRectGetMinX(_bubbleView.frame) - [self retryButtonBubblePadding] - CGRectGetWidth(_retryButton.bounds)/2;
        }
        
        _retryButton.center = CGPointMake(centerX, _bubbleView.center.y);
    }
}

- (void)layoutAudioPlayedIcon{
    if (!_audioPlayedIcon.hidden) {
        CGFloat padding = [self audioPlayedIconBubblePadding];
        if (!self.model.message.isOutgoingMsg) {
            _audioPlayedIcon.nim_left = _bubbleView.nim_right + padding;
        } else
        {
            _audioPlayedIcon.nim_right = _bubbleView.nim_left - padding;
        }
        _audioPlayedIcon.nim_top = _bubbleView.nim_top;
    }
}

#pragma mark - NIMMessageContentViewDelegate
- (void)onCatchEvent:(NIMKitEvent *)event{
    if ([self.messageDelegate respondsToSelector:@selector(onTapCell:)]) {
        [self.messageDelegate onTapCell:event];
    }
}

#pragma mark - Action
- (void)onRetryMessage:(id)sender
{
    if (_messageDelegate && [_messageDelegate respondsToSelector:@selector(onRetryMessage:)]) {
        [_messageDelegate onRetryMessage:self.model.message];
    }
}

- (void)longGesturePress:(UIGestureRecognizer*)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] &&
        gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (_messageDelegate && [_messageDelegate respondsToSelector:@selector(onLongPressCell:inView:)]) {
            [_messageDelegate onLongPressCell:self.model.message
                                       inView:_bubbleView];
        }
    }
}


#pragma mark - NIMPlayAudioUIDelegate
- (void)startPlayingAudioUI
{
    //更新DB
    NIMMessage * message = self.model.message;
    if (!message.isPlayed) {
        message.isPlayed  = YES;
        [self refreshData:self.model];
    }
}



#pragma mark - Private
- (CGRect)avatarViewRect
{
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat cellPaddingToProtrait = 8.f;
    CGFloat protraitImageWidth    = 42;//头像宽
    CGFloat selfProtraitOriginX   = (cellWidth - cellPaddingToProtrait - protraitImageWidth);
    return self.model.message.isOutgoingMsg ? CGRectMake(selfProtraitOriginX, 0,
                                                                       protraitImageWidth,
                                                                       protraitImageWidth) : CGRectMake(cellPaddingToProtrait, 0,                      protraitImageWidth, protraitImageWidth);
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
    BOOL isFromMe = self.model.message.isOutgoingMsg;
    if (self.model.message.messageType == NIMMessageTypeAudio) {
        return isFromMe ? 15 : 13;
    }
    return isFromMe ? 8 : 10;
}

- (BOOL)activityIndicatorHidden
{
    if (!self.model.message.isReceivedMsg) {
        return self.model.message.deliveryState != NIMMessageDeliveryStateDelivering;
    } else
    {
        return self.model.message.attachmentDownloadState != NIMMessageAttachmentDownloadStateDownloading;
    }
}


- (BOOL)unreadHidden {
    if (self.model.message.messageType == NIMMessageTypeAudio) { //音频
        BOOL hideIcon = self.model.message.attachmentDownloadState != NIMMessageAttachmentDownloadStateDownloaded;
        if ([self.model.sessionConfig respondsToSelector:@selector(disableAudioPlayedStatusIcon)]) {
            hideIcon = [self.model.sessionConfig disableAudioPlayedStatusIcon];
        }
        return (hideIcon || self.model.message.isOutgoingMsg || [self.model.message isPlayed]);
    }
    return YES;
}

- (CGFloat)audioPlayedIconBubblePadding{
    return 10;
}



- (void)onTapAvatar:(id)sender{
    if ([_messageDelegate respondsToSelector:@selector(onTapAvatar:)]) {
        [_messageDelegate onTapAvatar:self.model.message.from];
    }
}

@end
