//
//  SnapchatAttachment.h
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESCustomAttachmentDefines.h"

@interface NTESSnapchatAttachment : NSObject<NIMCustomAttachment,NTESCustomAttachmentInfo>

@property (nonatomic,copy)  NSString    *md5;

@property (nonatomic,copy)  NSString    *url;

@property (nonatomic,assign) BOOL isFired; //是否焚毁

@property (nonatomic,strong) UIImage *showCoverImage;

- (void)setImage:(UIImage *)image;

- (void)setImageFilePath:(NSString *)path;

- (NSString *)filepath;


@end
