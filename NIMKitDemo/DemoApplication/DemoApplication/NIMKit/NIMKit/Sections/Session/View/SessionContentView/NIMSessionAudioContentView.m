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
#import "UIImage+NIM.h"
#import "NIMKitUIConfig.h"

@interface NIMSessionAudioContentView()<NIMMediaManagerDelgate>

@property (nonatomic,strong) UIImageView *voiceImageView;

@property (nonatomic,strong) UILabel *durationLabel;

@end

@implementation NIMSessionAudioContentView

-(instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        [self addVoiceView];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addVoiceView{
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

- (void)refresh:(NIMMessageModel *)data{
    [super refresh:data];
    NIMAudioObject *object = self.model.message.messageObject;
    self.durationLabel.text = [NSString stringWithFormat:@"%zd\"",(object.duration+500)/1000];//四舍五入
    
    NIMKitBubbleConfig *config = [[NIMKitUIConfig sharedConfig] bubbleConfig:data.message];

    self.durationLabel.font = config.contentTextFont;
    self.durationLabel.textColor = config.contentTextColor;
    
    [self.durationLabel sizeToFit];
}


- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    if (self.model.message.isOutgoingMsg) {
        self.voiceImageView.nim_right = self.nim_width - contentInsets.right;
        _durationLabel.nim_left = contentInsets.left;
    } else
    {
       self.voiceImageView.nim_left = contentInsets.left;
        _durationLabel.nim_right = self.nim_width - contentInsets.right;
    }
    _voiceImageView.nim_centerY = self.nim_height * .5f;
    _durationLabel.nim_centerY = _voiceImageView.nim_centerY;
}

-(void)onTouchUpInside:(id)sender
{
    if ([self.model.message attachmentDownloadState]== NIMMessageAttachmentDownloadStateFailed) {
        if (self.audioUIDelegate && [self.audioUIDelegate respondsToSelector:@selector(retryDownloadMsg)]) {
            [self.audioUIDelegate retryDownloadMsg];
        }
        return;
    }
    if ([self.model.message attachmentDownloadState] == NIMMessageAttachmentDownloadStateDownloaded) {
        if (![[NIMSDK sharedSDK].mediaManager isPlaying]) {
            [[NIMSDK sharedSDK].mediaManager switchAudioOutputDevice:NIMAudioOutputDeviceSpeaker];
            NIMAudioObject *audioObject = (NIMAudioObject*)self.model.message.messageObject;
            BOOL needProximityMonitor = YES;
            if ([self.model.sessionConfig respondsToSelector:@selector(disableProximityMonitor)]) {
                needProximityMonitor = !self.model.sessionConfig.disableProximityMonitor;
            }
            [[NIMSDK sharedSDK].mediaManager setNeedProximityMonitor:needProximityMonitor];
            [[NIMSDK sharedSDK].mediaManager addDelegate:self];
            [[NIMSDK sharedSDK].mediaManager play:audioObject.path];
        } else {
            [[NIMSDK sharedSDK].mediaManager stopPlay];
            [self stopPlayingUI];
        }
    }
}

#pragma mark - NIMMediaManagerDelgate

- (void)playAudio:(NSString *)filePath didBeganWithError:(NSError *)error {
    if(filePath && !error) {
        NIMAudioObject *audioObject = (NIMAudioObject*)self.model.message.messageObject;
        
        if ([audioObject.path isEqualToString:filePath] && [self.audioUIDelegate respondsToSelector:@selector(startPlayingAudioUI)]) {
            [self.audioUIDelegate startPlayingAudioUI];
            [self.voiceImageView startAnimating];
        }
    }
}

- (void)playAudio:(NSString *)filePath didCompletedWithError:(NSError *)error
{
    [self stopPlayingUI];
}

#pragma mark - private methods
- (void)stopPlayingUI
{
    [self.voiceImageView stopAnimating];
}
@end
