//
//  NIMAvatarImageView.m
//  NIMKit
//
//  Created by chris on 15/2/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMAvatarImageView.h"
#import "UIView+NIM.h"
#import "objc/runtime.h"
#import "NIMKitDependency.h"
#import "NIMKit.h"
#import "NIMKitInfoFetchOption.h"

static char imageURLKey;


@interface NIMAvatarImageView()

@property (nonatomic,strong) UIImageView *imageView;

@end

@implementation NIMAvatarImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:_imageView];
    
    self.backgroundColor = [UIColor clearColor];
    [self setupRadius];
}


- (void)setupRadius
{
    switch ([NIMKit sharedKit].config.avatarType)
    {
        case NIMKitAvatarTypeNone:
            _cornerRadius = 0;
            break;
        case NIMKitAvatarTypeRounded:
            _cornerRadius = self.nim_width *.5f;
            break;
        case NIMKitAvatarTypeRadiusCorner:
            _cornerRadius = 6.f;
            break;
        default:
            break;
    }
}


- (void)setImage:(UIImage *)image
{
    if (_image != image)
    {
        _image = image;
        UIImage *fixedImage  = [self imageAddCornerWithRadius:_cornerRadius andSize:self.bounds.size];
        self.imageView.image = fixedImage;
    }
}

- (UIImage*)imageAddCornerWithRadius:(CGFloat)radius andSize:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGPathRef path = self.path;
    CGContextAddPath(ctx,path);
    CGContextClip(ctx);
    [self.image drawInRect:rect];
    CGContextDrawPath(ctx, kCGPathFillStroke);
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


- (CGPathRef)path
{
    return [[UIBezierPath bezierPathWithRoundedRect:self.bounds
                                       cornerRadius:self.cornerRadius] CGPath];
}





- (void)setAvatarBySession:(NIMSession *)session
{
    NIMKitInfo *info = nil;
    if (session.sessionType == NIMSessionTypeTeam)
    {
        info = [[NIMKit sharedKit] infoByTeam:session.sessionId option:nil];
    }
    else
    {
        NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
        option.session = session;
        info = [[NIMKit sharedKit] infoByUser:session.sessionId option:option];
    }
    NSURL *url = info.avatarUrlString ? [NSURL URLWithString:info.avatarUrlString] : nil;
    [self nim_setImageWithURL:url placeholderImage:info.avatarImage];
}

- (void)setAvatarByMessage:(NIMMessage *)message
{
    NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
    option.message = message;
    NSString *from = nil;
    if (message.messageType == NIMMessageTypeRobot)
    {
        NIMRobotObject *object = (NIMRobotObject *)message.messageObject;
        if (object.isFromRobot)
        {
            from = object.robotId;
        }
    }
    if (!from)
    {
        from = message.from;
    }
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:from option:option];
    NSURL *url = info.avatarUrlString ? [NSURL URLWithString:info.avatarUrlString] : nil;
    [self nim_setImageWithURL:url placeholderImage:info.avatarImage];
}

@end


@implementation NIMAvatarImageView (SDWebImageCache)

- (void)nim_setImageWithURL:(NSURL *)url {
    [self nim_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self nim_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self nim_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)nim_setImageWithURL:(NSURL *)url completed:(SDExternalCompletionBlock)completedBlock {
    [self nim_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDExternalCompletionBlock)completedBlock {
    [self nim_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDExternalCompletionBlock)completedBlock {
    [self nim_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDExternalCompletionBlock)completedBlock {
    NSString *validOperationKey = NSStringFromClass([self class]);
    [self sd_cancelImageLoadOperationWithKey:validOperationKey];
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (!(options & SDWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            [self nim_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:nil];
        });
    }
    
    if (url) {
        // check if activityView is enabled or not
        if ([self sd_showActivityIndicatorView]) {
            [self sd_addActivityIndicator];
        }
        
        __block NSURL *targetURL = url;
        __weak __typeof(self)wself = self;
        void(^loadBlock)(NSURL *URL)  =  ^(NSURL *URL) {
            __strong __typeof (wself) sself = wself;
            id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager loadImageWithURL:URL options:options progress:progressBlock completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                [sself sd_removeActivityIndicator];
                if (image && ![URL isEqual:url])
                {
                    [SDWebImageManager.sharedManager saveImageToCache:image forURL:url];
                }
                
                if (!sself) {
                    return;
                }
                dispatch_main_async_safe(^{
                    if (!sself) {
                        return;
                    }
                    
                    
                    if (image && (options & SDWebImageAvoidAutoSetImage) && completedBlock) {
                        completedBlock(image, error, cacheType, url);
                        return;
                    } else if (image) {
                        [sself nim_setImage:image imageData:data basedOnClassOrViaCustomSetImageBlock:nil];
                        [sself nim_setNeedsLayout];
                    } else {
                        if ((options & SDWebImageDelayPlaceholder)) {
                            [sself nim_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:nil];
                            [sself nim_setNeedsLayout];
                        }
                    }
                    if (completedBlock && finished) {
                        completedBlock(image, error, cacheType, url);
                    }
                });
            }];
            [sself sd_setImageLoadOperation:operation forKey:validOperationKey];
        };

        [SDWebImageManager.sharedManager cachedImageExistsForURL:url completion:^(BOOL isInCache) {
            if (!isInCache)
            {
                [[NIMSDK sharedSDK].resourceManager fetchNOSURLWithURL:[url absoluteString]
                                                            completion:^(NSError * _Nullable error, NSString * _Nullable urlString)
                 {
                     if (urlString && !error) {
                         targetURL = [NSURL URLWithString:urlString];
                     }
                     if (loadBlock)
                     {
                         dispatch_main_async_safe(^{
                             loadBlock(targetURL);
                         });
                     }
                 }];
            } else {
                if (loadBlock)
                {
                    loadBlock(targetURL);
                }
            }
        }];

    } else {
        dispatch_main_async_safe(^{
            [self sd_removeActivityIndicator];
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:@"SDWebImageErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
                completedBlock(nil, error, SDImageCacheTypeNone, url);
            }
        });
    }


}

- (void)nim_setImageWithPreviousCachedImageWithURL:(NSURL *)url andPlaceholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDExternalCompletionBlock)completedBlock {
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPreviousCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
    
    [self nim_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];
}

- (void)nim_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(SDSetImageBlock)setImageBlock {
    if (setImageBlock) {
        setImageBlock(image, imageData);
        return;
    }
    self.image = image;
}

- (void)nim_setNeedsLayout {
    [self setNeedsLayout];
}



- (NSURL *)nim_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
}


- (void)nim_cancelCurrentImageLoad {
    [self sd_cancelImageLoadOperationWithKey:@"UIImageViewImageLoad"];
}

- (void)nim_cancelCurrentAnimationImagesLoad {
    [self sd_cancelImageLoadOperationWithKey:@"UIImageViewAnimationImages"];
}


@end
