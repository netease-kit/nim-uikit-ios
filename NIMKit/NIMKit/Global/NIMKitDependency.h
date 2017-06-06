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

#if __has_include(<SDWebImageCompat/SDWebImageCompat.h>)
#import <SDWebImageCompat/SDWebImageCompat.h>
#else
#import "SDWebImageCompat.h"
#endif


#if __has_include(<SDWebImage/SDWebImage.h>)
#import <SDWebImage/SDWebImage.h>
#else
#import "SDWebImageManager.h"
#import "UIView+WebCacheOperation.h"
#endif


#if __has_include(<Toast/Toast.h>)
#import <Toast/Toast.h>
#else
#import "UIView+Toast.h"
#endif


#if __has_include(<SVProgressHUD/SVProgressHUD.h>)
#import <SVProgressHUD/SVProgressHUD.h>
#else
#import "SVProgressHUD.h"
#endif

#if __has_include(<TZImagePickerController/TZImagePickerController.h>)
#import <TZImagePickerController/TZImagePickerController.h>
#else
#import "TZImagePickerController.h"
#endif


#endif /* NIMKitDependency_h */
