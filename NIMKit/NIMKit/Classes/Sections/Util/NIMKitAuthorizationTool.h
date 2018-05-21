//
//  NIMKitAuthorizationTool.h
//  NIMKit
//
//  Created by chris on 2017/10/20.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NIMKitAuthorizationStatus) {
    NIMKitAuthorizationStatusAuthorized,        // 已授权
    NIMKitAuthorizationStatusDenied,            // 拒绝
    NIMKitAuthorizationStatusRestricted,        // 应用没有相关权限，且当前用户无法改变这个权限，比如:家长控制
    NIMKitAuthorizationStatusNotSupport         // 硬件等不支持
};

@interface NIMKitAuthorizationTool : NSObject

+ (void)requestPhotoLibraryAuthorization:(void(^)(NIMKitAuthorizationStatus status))callback;

+ (void)requestCameraAuthorization:(void(^)(NIMKitAuthorizationStatus status))callback;

+ (void)requestAddressBookAuthorization:(void (^)(NIMKitAuthorizationStatus))callback;

@end
