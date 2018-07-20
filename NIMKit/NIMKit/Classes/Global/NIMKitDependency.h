//
//  NIMKitDependency.h
//  NIMKit
//
//  Created by chris on 2017/5/3.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#ifndef NIMKitDependency_h
#define NIMKitDependency_h


#if __has_include(<M80AttributedLabel/M80AttributedLabel.h>)
#import <M80AttributedLabel/M80AttributedLabel.h>
#else
#import "M80AttributedLabel.h"
#endif

#if __has_include(<SDWebImage/SDWebImageCompat.h>)
#import <SDWebImage/SDWebImageCompat.h>
#else
#import "SDWebImageCompat.h"
#endif


#if __has_include(<SDWebImage/SDWebImageManager.h>)
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCacheOperation.h>
#import <SDWebImage/UIView+WebCache.h>
#else
#import "SDWebImageManager.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCache.h"
#endif


#if __has_include(<Toast/UIView+Toast.h>)
#import <Toast/UIView+Toast.h>
#else
#import "UIView+Toast.h"
#endif


#if __has_include(<TZImagePickerController/TZImagePickerController.h>)
#import <TZImagePickerController/TZImagePickerController.h>
#else
#import "TZImagePickerController.h"
#endif

#endif /* NIMKitDependency_h */
