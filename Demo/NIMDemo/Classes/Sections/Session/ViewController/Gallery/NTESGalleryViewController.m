//
//  NTESGalleryViewController.m
//  NIMDemo
//
//  Created by ght on 15-2-3.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESGalleryViewController.h"
#import "UIImageView+WebCache.h"
#import "UIView+NTES.h"
#import "NTESSnapchatAttachment.h"
#import "NTESSessionUtil.h"
#import "UIView+Toast.h"

@implementation NTESGalleryItem
@end


@interface NTESGalleryViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *galleryImageView;
@property (nonatomic,strong)    NTESGalleryItem *currentItem;
@end

@implementation NTESGalleryViewController

- (instancetype)initWithItem:(NTESGalleryItem *)item
{
    if (self = [super initWithNibName:@"NTESGalleryViewController"
                               bundle:nil])
    {
        _currentItem = item;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    _galleryImageView.contentMode = UIViewContentModeScaleAspectFit;
    NSURL *url = [NSURL URLWithString:_currentItem.imageURL];
    [_galleryImageView sd_setImageWithURL:url
                         placeholderImage:[UIImage imageWithContentsOfFile:_currentItem.thumbPath]
                                  options:SDWebImageRetryFailed];
    
    if ([_currentItem.name length])
    {
        self.navigationItem.title = _currentItem.name;
    }    
}


@end




@interface SingleSnapView : UIImageView

@property (nonatomic,strong) UIProgressView *progressView;

@property (nonatomic,copy)   NIMCustomObject *messageObject;

- (instancetype)initWithFrame:(CGRect)frame messageObject:(NIMCustomObject *)object;

- (void)setProgress:(CGFloat)progress;

@end


@implementation  NTESGalleryViewController(SingleView)

+ (UIView *)alertSingleSnapViewWithMessage:(NIMMessage *)message baseView:(UIView *)view{
    NIMCustomObject *messageObject = (NIMCustomObject *)message.messageObject;
    if (![messageObject isKindOfClass:[NIMCustomObject class]] || ![messageObject.attachment isKindOfClass:[NTESSnapchatAttachment class]]) {
        return nil;
    }
    SingleSnapView *galleryImageView = [[SingleSnapView alloc] initWithFrame:[UIScreen mainScreen].bounds messageObject:messageObject];
    galleryImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    galleryImageView.backgroundColor = [UIColor blackColor];
    galleryImageView.contentMode  = UIViewContentModeScaleAspectFit;
    
    galleryImageView.userInteractionEnabled = NO;
    [view presentView:galleryImageView animated:YES complete:^{
        NTESSnapchatAttachment *attachment = (NTESSnapchatAttachment *)messageObject.attachment;
        if ([[NSFileManager defaultManager] fileExistsAtPath:attachment.filepath isDirectory:nil]) {
            galleryImageView.image = [UIImage imageWithContentsOfFile:attachment.filepath];
            galleryImageView.progress = 1.0;
        }else{
            [NTESGalleryViewController downloadImage:attachment.url imageView:galleryImageView];
        }
    }];
    return galleryImageView;
}

+ (void)downloadImage:(NSString *)url imageView:(SingleSnapView *)imageView{
    __weak typeof(imageView) wImageView = imageView;
    [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageCacheMemoryOnly progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        dispatch_async_main_safe(^{
            wImageView.progress = (CGFloat)receivedSize / expectedSize;
        });
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            [wImageView makeToast:@"下载图片失败"
                         duration:2
                         position:CSToastPositionCenter];
        }else{
            wImageView.progress = 1.0;
        }
    }];
}

@end


@implementation SingleSnapView

- (instancetype)initWithFrame:(CGRect)frame messageObject:(NIMCustomObject *)object{
    self = [super initWithFrame:frame];
    if (self) {
        _messageObject = object;
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
        CGFloat width = 200.f * UISreenWidthScale;
        _progressView.width = width;
        _progressView.hidden = YES;
        [self addSubview:_progressView];
        
    }
    return self;
}

- (void)setProgress:(CGFloat)progress{
    [self.progressView setProgress:progress];
    [self.progressView setHidden:progress>0.99];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.progressView.centerY = self.height *.5;
    self.progressView.centerX = self.width  *.5;
}


@end