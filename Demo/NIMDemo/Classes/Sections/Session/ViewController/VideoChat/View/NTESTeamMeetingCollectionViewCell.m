//
//  NTESTeamMeetingCollectionViewCell.m
//  NIM
//
//  Created by chris on 2017/5/2.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESTeamMeetingCollectionViewCell.h"
#import "NTESGLView.h"
#import "NIMAvatarImageView.h"
#import "UIView+NTES.h"
#import "UIImage+GIF.h"
#import "NIMKitInfoFetchOption.h"

@interface NTESTeamMeetingCollectionViewCell()

@property (nonatomic,strong) NTESGLView *glView;

@property (nonatomic,strong) UIView *cameraView;

@property (nonatomic,strong) NIMAvatarImageView *avatarImageView;

@property (nonatomic,strong) UILabel *tipLabel;

@property (nonatomic,strong) UILabel *nameLabel;

@property (nonatomic,strong) UIProgressView *progressView;

@property (nonatomic,strong) UIImageView *connectingImageView;

@end

@implementation NTESTeamMeetingCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.contentView.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void)refrehWithConnecting:(NSString *)user
{
    [self refreshWithDefaultAvatar:user];
    self.connectingImageView.hidden  = NO;
    [self.connectingImageView startAnimating];
    
}

- (void)refreshWithDefaultAvatar:(NSString *)user
{
    self.glView.hidden = YES;
    self.cameraView.hidden = YES;
    self.avatarImageView.hidden = NO;
    self.progressView.hidden = YES;
    self.connectingImageView.hidden  = YES;
    [self.connectingImageView stopAnimating];
    
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.session = [NIMSession session:self.team.teamId type:NIMSessionTypeTeam];
    
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:user option:option];
    
    UIImage *placeHolder = [UIImage imageNamed:@"icon_meeting_default_avatar"];
    [self.avatarImageView nim_setImageWithURL:[NSURL URLWithString:info.avatarUrlString] placeholderImage:placeHolder];
    self.nameLabel.text = info.showName;
    [self.nameLabel sizeToFit];
    self.nameLabel.width = self.width;
}

- (void)refreshWithTimeout:(NSString *)user
{
    self.tipLabel.text = @"未接通";
    self.tipLabel.hidden = NO;
    [self.tipLabel sizeToFit];
    self.connectingImageView.hidden  = YES;
    [self.connectingImageView stopAnimating];
    [self setNeedsLayout];
}

- (void)refreshWithUserJoin:(NSString *)user
{
    self.tipLabel.hidden = YES;
    self.connectingImageView.hidden  = YES;
    [self.connectingImageView stopAnimating];
}

- (void)refreshWithUserLeft:(NSString *)user
{
    self.tipLabel.text = @"已挂断";
    self.tipLabel.hidden = NO;
    [self.tipLabel sizeToFit];
    self.connectingImageView.hidden  = YES;
    [self.connectingImageView stopAnimating];
    self.progressView.hidden = YES;
    [self setNeedsLayout];
}

- (void)refreshWidthYUV:(NSData *)yuvData
                  width:(NSUInteger)width
                 height:(NSUInteger)height
{
    self.glView.hidden = NO;
    self.avatarImageView.hidden = YES;
    self.cameraView.hidden = YES;
    
    self.connectingImageView.hidden  = YES;
    [self.connectingImageView stopAnimating];
    
    [self.glView render:yuvData width:width height:height];
}

- (void)refreshWidthCameraPreview:(UIView *)preview
{
    self.cameraView.hidden = NO;
    self.glView.hidden = YES;
    self.avatarImageView.hidden = YES;
    preview.frame = self.cameraView.bounds;
    [self.cameraView addSubview:preview];
}

- (void)refreshWidthVolume:(UInt16)volume
{
    self.progressView.hidden = NO;
    NSInteger volumeMax = 480;
    volume = MIN(volume, volumeMax);
    CGFloat vo = (CGFloat)volume / (CGFloat)volumeMax;
    [self.progressView setProgress:vo animated:YES];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.tipLabel.centerX = self.contentView.width  * .5f;
    self.tipLabel.centerY = self.contentView.height * .5f;
    self.connectingImageView.centerX = self.contentView.width  * .5f;
    self.connectingImageView.centerY = self.contentView.height * .5f;
    self.nameLabel.bottom = self.contentView.height;
    self.nameLabel.centerX = self.contentView.width * .5f;
    self.progressView.bottom = self.contentView.height;
}


- (NTESGLView *)glView
{
    if (!_glView) {
        _glView = [[NTESGLView alloc] initWithFrame:self.contentView.bounds];
        _glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_glView];
    }
    return _glView;
}


- (UIView *)cameraView
{
    if (!_cameraView) {
        _cameraView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        _cameraView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_cameraView];
    }
    return _cameraView;
}

- (NIMAvatarImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [[NIMAvatarImageView alloc] initWithFrame:self.contentView.bounds];
        _avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _avatarImageView.clipPath = NO;
        [self.contentView addSubview:_avatarImageView];
    }
    return _avatarImageView;
}

- (UILabel *)tipLabel
{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        _tipLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tipLabel.font = [UIFont fontWithName:@"PingFang-SC-Regular" size:15];
        _tipLabel.shadowColor = UIColorFromRGBA(0x0, 0.3);
        _tipLabel.shadowOffset = CGSizeMake(2, 2);
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.hidden = YES;
        [self.contentView addSubview:_tipLabel];
    }
    return _tipLabel;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        _nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _nameLabel.backgroundColor = UIColorFromRGBA(0x0, .3f);
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.font = [UIFont fontWithName:@"PingFang-SC-Regular" size:12];
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.width, 1)];
        _progressView.progressTintColor = UIColorFromRGB(0x168cf6);
        _progressView.trackTintColor = [UIColor clearColor];
        _progressView.hidden = YES;
        [self.contentView addSubview:_progressView];
    }
    return _progressView;
}


- (UIImageView *)connectingImageView
{
    if (!_connectingImageView) {
        NSData *data = [NSData dataWithContentsOfFile:@"icon_meeting_connecting"];
        UIImage *image = [UIImage sd_animatedGIFWithData:data];
        _connectingImageView = [[UIImageView alloc] initWithImage:image];
        _connectingImageView.hidden = YES;
        [self.contentView addSubview:_connectingImageView];
    }
    return _connectingImageView;
}

@end


@interface NTESTeamMeetingCollectionSeparatorView()

@property (nonatomic,assign) NSInteger divid;

@property (nonatomic,copy)   NSArray *seps;

@end


@implementation NTESTeamMeetingCollectionSeparatorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _divid = 2;
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (NSInteger index = 0; index < _divid * 2; index++)
        {
            UIView *sep = [[UIView alloc] initWithFrame:CGRectZero];
            sep.backgroundColor = [UIColor blackColor];
            [array addObject:sep];
            [self addSubview:sep];
        }
        _seps = [NSArray arrayWithArray:array];
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat thin = .5f;
    CGFloat spacing = self.width / (self.divid + 1);
    CGFloat left = spacing;
    for (NSInteger index = 0; index < self.divid; index++)
    {
        UIView *sep = self.seps[index];
        sep.frame = CGRectMake(left, 0, thin, self.height);
        left += spacing;
    }
    
    NSInteger top = spacing;
    for (NSInteger index = self.divid; index < self.seps.count; index++)
    {
        UIView *sep = self.seps[index];
        sep.frame = CGRectMake(0, top, self.width, thin);
        top += spacing;
    }
}

@end
