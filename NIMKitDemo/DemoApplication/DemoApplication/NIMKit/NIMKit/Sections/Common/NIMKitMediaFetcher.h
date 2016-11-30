//
//  NIMKitMediaFetcher.h
//  NIMKit
//
//  Created by chris on 2016/11/12.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class NIMMessage;

typedef void(^NIMKitLibraryFetchResult)(NSString *path, PHAssetMediaType type);

typedef void(^NIMKitCameraFetchResult)(NSString *path, UIImage *image);

@interface NIMKitMediaFetcher : NSObject

@property (nonatomic,assign) NSInteger limit;

@property (nonatomic,strong) NSArray *mediaTypes; //kUTTypeMovie,kUTTypeImage

- (void)fetchPhotoFromLibrary:(NIMKitLibraryFetchResult)result;

- (void)fetchMediaFromCamera:(NIMKitCameraFetchResult)result;

@end
