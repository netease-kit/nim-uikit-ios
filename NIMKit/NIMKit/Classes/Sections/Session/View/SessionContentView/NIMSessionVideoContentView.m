//
//  NIMSessionVideoContentView.m
//  NIMKit
//
//  Created by chris on 15/4/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionVideoContentView.h"
#import "NIMMessageModel.h"
#import "UIView+NIM.h"
#import "UIImage+NIMKit.h"
#import "NIMLoadProgressView.h"

#import <AVFoundation/AVFoundation.h>

@interface NIMSessionVideoContentView()

@property (nonatomic,strong,readwrite) UIImageView * imageView;

@property (nonatomic,strong) UIButton *playBtn;

@property (nonatomic,strong) NIMLoadProgressView * progressView;

@end

@implementation NIMSessionVideoContentView

- (instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        self.opaque = YES;
        _imageView  = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.backgroundColor = [UIColor blackColor];
        [self addSubview:_imageView];
        
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage nim_imageInKit:@"icon_play_normal"] forState:UIControlStateNormal];
        [_playBtn sizeToFit];
        [_playBtn setUserInteractionEnabled:NO];
        [self addSubview:_playBtn];
        
        _progressView = [[NIMLoadProgressView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        _progressView.maxProgress = 1.0;
        [self addSubview:_progressView];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data{
    [super refresh:data];
    NIMVideoObject * videoObject = (NIMVideoObject*)self.model.message.messageObject;
    UIImage * image              = [UIImage imageWithContentsOfFile:videoObject.coverPath];
    if (!image && videoObject.url)
    {
        NSString *videoUrl = videoObject.coverUrl;
        image = [self thumbnailImageForVideo:[NSURL URLWithString:videoUrl] atTime:0];
    }
    self.imageView.image         = image;
    _progressView.hidden         = (self.model.message.deliveryState != NIMMessageDeliveryStateDelivering);
    if (!_progressView.hidden) {
        [_progressView setProgress:[[[NIMSDK sharedSDK] chatManager] messageTransportProgress:self.model.message]];
    }
}


- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    
    CGFloat tableViewWidth = self.superview.nim_width;
    CGSize contentsize = [self.model contentSize:tableViewWidth];
    
    CGRect imageViewFrame = CGRectMake(contentInsets.left, contentInsets.top, contentsize.width, contentsize.height);
    self.imageView.frame  = imageViewFrame;
    _progressView.frame   = self.bounds;
    
    CALayer *maskLayer = [CALayer layer];
    maskLayer.cornerRadius = 13.0;
    maskLayer.backgroundColor = [UIColor blackColor].CGColor;
    maskLayer.frame = self.imageView.bounds;
    self.imageView.layer.mask = maskLayer;
    
    self.playBtn.nim_centerX = self.nim_width  * .5f;
    self.playBtn.nim_centerY = self.nim_height * .5f;
}


- (void)onTouchUpInside:(id)sender
{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMKitEventNameTapContent;
    event.messageModel = self.model;
    [self.delegate onCatchEvent:event];
}

- (void)updateProgress:(float)progress
{
    if (progress > 1.0) {
        progress = 1.0;
    }
    self.progressView.progress = progress;
}


- (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    if (!asset)
    {
        return nil;
    }
    
    AVAssetImageGenerator *generator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [generator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)
                                          actualTime:NULL
                                               error:&thumbnailImageGenerationError];
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    thumbnailImage = [thumbnailImage nim_cropedImageWithSize:CGSizeMake(600, 600)];
    
    CGImageRelease(thumbnailImageRef);
    return thumbnailImage;
}

@end
