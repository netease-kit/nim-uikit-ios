//
//  SessionAudioCententView.m
//  NIMDemo
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionAudioContentView.h"
#import "UIView+NIM.h"
#import "NIMMessageModel.h"
#import "UIImage+NIMKit.h"
#import "NIMKitAudioCenter.h"
#import "NIMKit.h"
#import "UIColor+NIMKit.h"

@interface NIMSessionAudioContentView()<NIMMediaManagerDelegate>

@property (nonatomic,strong) UIImageView *voiceImageView;

@property (nonatomic,strong) UILabel *durationLabel;

@end

@implementation NIMSessionAudioContentView

-(instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        [self addVoiceView];
        [[NIMSDK sharedSDK].mediaManager addDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NIMSDK sharedSDK].mediaManager removeDelegate:self];
}

- (void)setPlaying:(BOOL)isPlaying
{
    if (isPlaying) {
        [self.voiceImageView startAnimating];
    }else{
        [self.voiceImageView stopAnimating];
    }
}

- (void)addVoiceView{
    _audioBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    _audioBackgroundView.layer.cornerRadius = 16.f;
    _audioBackgroundView.userInteractionEnabled = NO;
    [self addSubview:_audioBackgroundView];
    
    UIImage * image = [UIImage nim_imageInKit:@"icon_receiver_voice_playing.png"];
    _voiceImageView = [[UIImageView alloc] initWithImage:image];
    NSArray * animateNames = @[@"icon_receiver_voice_playing_001.png",@"icon_receiver_voice_playing_002.png",@"icon_receiver_voice_playing_003.png"];
    NSMutableArray * animationImages = [[NSMutableArray alloc] initWithCapacity:animateNames.count];
    for (NSString * animateName in animateNames) {
        UIImage * animateImage = [UIImage nim_imageInKit:animateName];
        [animationImages addObject:animateImage];
    }
    _voiceImageView.animationImages = animationImages;
    _voiceImageView.animationDuration = 1.0;
    [self addSubview:_voiceImageView];
    
    _durationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _durationLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:_durationLabel];
    
    
}

- (void)refresh:(NIMMessageModel *)data {
    [super refresh:data];
    NIMAudioObject *object = self.model.message.messageObject;
    self.durationLabel.text = [NSString stringWithFormat:@"%zd\"",(NSInteger)((object.duration+500)/1000)];//四舍五入
    
    NIMKitSetting *setting = [[NIMKit sharedKit].config setting:data.message];

    self.durationLabel.font      = setting.font;
    self.durationLabel.textColor = setting.textColor;
    
    [self.durationLabel sizeToFit];
    
    [self setPlaying:self.isPlaying];
    
    [self refreshBackground:data];
}

- (void)refreshBackground:(NIMMessageModel *)data
{
    UIColor *color = nil;
    if (data.shouldShowLeft)
    {
        color = [UIColor colorWithHex:0xF3F3F3 alpha:1];
    }
    else
    {
        color = [UIColor colorWithHex:0x1A73E0 alpha:1];
    }
    
    _audioBackgroundView.backgroundColor = color;
}


- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    switch (self.layoutStyle) {
        case NIMSessionMessageContentViewLayoutLeft: {
            self.voiceImageView.nim_left = contentInsets.left * 2;
             _durationLabel.nim_right = self.nim_width - contentInsets.right * 2;
            break;
        }
        case NIMSessionMessageContentViewLayoutRight: {
            self.voiceImageView.nim_right = self.nim_width - contentInsets.right * 2;
            _durationLabel.nim_left = contentInsets.left;
            break;
        }
        case NIMSessionMessageContentViewLayoutAuto:
        default:
        {
            if (self.model.message.isOutgoingMsg) {
                self.voiceImageView.nim_right = self.nim_width - contentInsets.right * 2;
                _durationLabel.nim_left = contentInsets.left * 2;
            } else {
               self.voiceImageView.nim_left = contentInsets.left;
                _durationLabel.nim_right = self.nim_width - contentInsets.right * 2;
            }
            break;
        }
    }
    _voiceImageView.nim_centerY = self.nim_height * .5f;
    _durationLabel.nim_centerY = _voiceImageView.nim_centerY;
    
    CGFloat backgroundWidth = 0;
    CGFloat backgroundLeft = 0;
    switch (self.layoutStyle) {
        case NIMSessionMessageContentViewLayoutLeft:
            {
                backgroundWidth = self.nim_width - contentInsets.left * .5f - 2;
                backgroundLeft = contentInsets.left * .5f;
            }
            break;
        case NIMSessionMessageContentViewLayoutRight:
            {
                backgroundWidth = self.nim_width - 2 - contentInsets.right * .5f;
                backgroundLeft = 2;
            }
            break;
        default:
        {
            if (self.model.message.isOutgoingMsg) {
                backgroundWidth = self.nim_width - 2 - contentInsets.right * .5f;
                backgroundLeft = 2;
            } else {
                backgroundWidth = self.nim_width - contentInsets.left * .5f - 2;
                backgroundLeft = contentInsets.left * .5f;
            }
            break;
        }
    }
    _audioBackgroundView.nim_size = CGSizeMake(backgroundWidth,
                                               self.nim_height - 4);
    _audioBackgroundView.nim_left = backgroundLeft;
    _audioBackgroundView.nim_top = 2;
}

-(void)onTouchUpInside:(id)sender
{
    if ([self.model.message attachmentDownloadState]== NIMMessageAttachmentDownloadStateFailed
        || [self.model.message attachmentDownloadState] == NIMMessageAttachmentDownloadStateNeedDownload) {
        [[[NIMSDK sharedSDK] chatManager] fetchMessageAttachment:self.model.message
                                                           error:nil];
        return;
    }
    if ([self.model.message attachmentDownloadState] == NIMMessageAttachmentDownloadStateDownloaded) {
        
        if ([[NIMSDK sharedSDK].mediaManager isPlaying]) {
            [self stopPlayingUI];
        }
        
        NIMKitEvent *event = [[NIMKitEvent alloc] init];
        event.eventName = NIMKitEventNameTapAudio;
        event.messageModel = self.model;
        [self.delegate onCatchEvent:event];

    }
}

#pragma mark - NIMMediaManagerDelegate

- (void)playAudio:(NSString *)filePath didBeganWithError:(NSError *)error {
    if(filePath && !error) {
        if (self.isPlaying && [self.audioUIDelegate respondsToSelector:@selector(startPlayingAudioUI)]) {
            [self.audioUIDelegate startPlayingAudioUI];
        }        
    }
}

- (void)playAudio:(NSString *)filePath didCompletedWithError:(NSError *)error
{
    [self stopPlayingUI];
}

- (void)stopPlayAudio:(NSString *)filePath didCompletedWithError:(nullable NSError *)error
{
    [self stopPlayingUI];
}

#pragma mark - private methods
- (void)stopPlayingUI
{
    [self setPlaying:NO];
}

- (BOOL)isPlaying
{
    return [NIMKitAudioCenter instance].currentPlayingMessage == self.model.message; //对比是否是同一条消息，严格同一条，不能是相同ID，防止进了会话又进云端消息界面，导致同一个ID的云消息也在动画
}


@end
