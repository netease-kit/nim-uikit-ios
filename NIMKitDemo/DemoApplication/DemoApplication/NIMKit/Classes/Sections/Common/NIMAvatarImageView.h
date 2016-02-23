//
//  NIMAvatarImageView.h
//  NIMKit
//
//  Created by chris on 15/2/10.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMWebImageCompat.h"
#import "NIMWebImageManager.h"
#import "NIMSDK.h"

@interface NIMAvatarImageView : UIControl
@property (nonatomic,strong)    UIImage *image;
@property (nonatomic,assign)    BOOL    clipPath;

- (void)setAvatarBySession:(NIMSession *)session;
- (void)setAvatarByMessage:(NIMMessage *)message;
@end


@interface NIMAvatarImageView (SDWebImageCache)
- (NSURL *)nim_imageURL;

- (void)nim_setImageWithURL:(NSURL *)url;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(NIMWebImageOptions)options;
- (void)nim_setImageWithURL:(NSURL *)url completed:(NIMWebImageCompletionBlock)completedBlock;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(NIMWebImageCompletionBlock)completedBlock;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(NIMWebImageOptions)options completed:(NIMWebImageCompletionBlock)completedBlock;
- (void)nim_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(NIMWebImageOptions)options progress:(NIMWebImageDownloaderProgressBlock)progressBlock completed:(NIMWebImageCompletionBlock)completedBlock;
- (void)nim_setImageWithPreviousCachedImageWithURL:(NSURL *)url andPlaceholderImage:(UIImage *)placeholder options:(NIMWebImageOptions)options progress:(NIMWebImageDownloaderProgressBlock)progressBlock completed:(NIMWebImageCompletionBlock)completedBlock;
- (void)nim_cancelCurrentImageLoad;
- (void)nim_cancelCurrentAnimationImagesLoad;
@end