//
//  NIMSessionFileTransContentView.m
//  NIM
//
//  Created by chris on 15/4/21.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionFileTransContentView.h"
#import "UIView+NIM.h"
#import "NIMMessageModel.h"
#import "UIImage+NIM.h"
#import "NIMKitUIConfig.h"

@interface NIMSessionFileTransContentView()

@property (nonatomic,strong) UIImageView *imageView;

@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) UILabel *sizeLabel;

@property (nonatomic,strong) UIProgressView *progressView;

@property (nonatomic,strong) UIView *bkgView;

@end

@implementation NIMSessionFileTransContentView

- (instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        self.opaque              = YES;
        _bkgView                 = [[UIView alloc]initWithFrame:CGRectZero];
        _bkgView.userInteractionEnabled = NO;
        _bkgView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_bkgView];
        _imageView               = [[UIImageView alloc] initWithFrame:CGRectZero];
        UIImage * image          = [UIImage nim_imageInKit:@"icon_file"];
        _imageView.image         = image;
        [_imageView sizeToFit];
        [self addSubview:_imageView];
        
        _titleLabel               = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self addSubview:_titleLabel];
        
        _sizeLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
        _sizeLabel.textColor = [UIColor lightGrayColor];
        [self addSubview:_sizeLabel];
        
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progress = 0.0f;
        [self addSubview:_progressView];
        
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data{
    [super refresh:data];
    NIMFileObject *fileObject = (NIMFileObject *)self.model.message.messageObject;
    
    NIMKitBubbleConfig *config = [[NIMKitUIConfig sharedConfig] bubbleConfig:data.message];
    
    self.titleLabel.font = config.contentTextFont;
    self.titleLabel.text = fileObject.displayName;
    [self.titleLabel sizeToFit];
    
    self.sizeLabel.font = config.contentTextFont;
    self.sizeLabel.text = [NSString stringWithFormat:@"%zdKB",fileObject.fileLength/1024];
    [self.sizeLabel sizeToFit];
    if (self.model.message.deliveryState == NIMMessageDeliveryStateDelivering) {
        self.progressView.hidden   = NO;
        self.progressView.progress = [[NIMSDK sharedSDK].chatManager messageTransportProgress:self.model.message];
    }else{
        self.progressView.hidden = YES;
    }
}



- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    CGSize size = self.model.contentSize;
    CGRect bkgViewFrame = CGRectMake(contentInsets.left, contentInsets.top, size.width, size.height);
    self.bkgView.frame = bkgViewFrame;

    CGFloat fileTransMessageIconLeft        = 15.f;
    CGFloat fileTransMessageSizeTitleRight  = 15.f;
    CGFloat fileTransMessageTitleLeft       = 90.f;
    CGFloat fileTransMessageTitleTop        = 25.f;
    CGFloat fileTransMessageSizeTitleBottom = 15.f;
    CGFloat fileTransMessageProgressTop     = 75.f;
    CGFloat fileTransMessageProgressLeft    = 90.f;
    CGFloat fileTransMessageProgressRight   = 20.f;

    self.imageView.nim_left          = fileTransMessageIconLeft;
    self.imageView.nim_centerY       = self.nim_height * .5f;

    if (self.nim_width < fileTransMessageTitleLeft + self.titleLabel.nim_width + fileTransMessageSizeTitleRight) {
        self.titleLabel.nim_width = self.nim_width - fileTransMessageTitleLeft - fileTransMessageSizeTitleRight;
    }
    self.titleLabel.nim_left     = fileTransMessageTitleLeft;
    self.titleLabel.nim_top      = fileTransMessageTitleTop;
    
    self.sizeLabel.nim_right     = self.nim_width - fileTransMessageSizeTitleRight;
    self.sizeLabel.nim_bottom    = self.nim_height - fileTransMessageSizeTitleBottom;
    
    self.progressView.nim_top    = fileTransMessageProgressTop;
    self.progressView.nim_width  = self.nim_width - fileTransMessageProgressLeft - fileTransMessageProgressRight;
    self.progressView.nim_left   = fileTransMessageProgressLeft;
    
    CALayer *maskLayer = [CALayer layer];
    maskLayer.cornerRadius = 13.0;
    maskLayer.backgroundColor = [UIColor blackColor].CGColor;
    maskLayer.frame = self.bkgView.bounds;
    self.bkgView.layer.mask = maskLayer;
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

@end

