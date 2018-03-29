//
//  NIMKitAuthorizationTool.m
//  NIMKit
//
//  Created by chris on 2017/10/20.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMKitAuthorizationTool.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <ContactsUI/ContactsUI.h>

@implementation NIMKitAuthorizationTool

+ (void)requestPhotoLibraryAuthorization:(void(^)(NIMKitAuthorizationStatus status))callback
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
        if (authStatus == ALAuthorizationStatusNotDetermined) { // 未授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    [self executeCallback:callback status:NIMKitAuthorizationStatusAuthorized];
                } else if (status == PHAuthorizationStatusDenied) {
                    [self executeCallback:callback status:NIMKitAuthorizationStatusDenied];
                } else if (status == PHAuthorizationStatusRestricted) {
                    [self executeCallback:callback status:NIMKitAuthorizationStatusRestricted];
                }
            }];
        }
        else if (authStatus == ALAuthorizationStatusAuthorized) {
            [self executeCallback:callback status:NIMKitAuthorizationStatusAuthorized];
        } else if (authStatus == ALAuthorizationStatusDenied) {
            [self executeCallback:callback status:NIMKitAuthorizationStatusDenied];
        } else if (authStatus == ALAuthorizationStatusRestricted) {
            [self executeCallback:callback status:NIMKitAuthorizationStatusRestricted];
        }
    } else {
        [self executeCallback:callback status:NIMKitAuthorizationStatusNotSupport];
    }
}

+ (void)requestCameraAuthorization:(void(^)(NIMKitAuthorizationStatus status))callback
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self executeCallback:callback status:NIMKitAuthorizationStatusAuthorized];
                } else {
                    [self executeCallback:callback status:NIMKitAuthorizationStatusDenied];
                }
            }];
        } else if (authStatus == AVAuthorizationStatusAuthorized) {
            [self executeCallback:callback status:NIMKitAuthorizationStatusAuthorized];
        } else if (authStatus == AVAuthorizationStatusDenied) {
            [self executeCallback:callback status:NIMKitAuthorizationStatusDenied];
        } else if (authStatus == AVAuthorizationStatusRestricted) {
            [self executeCallback:callback status:NIMKitAuthorizationStatusRestricted];
        }
    } else {
        [self executeCallback:callback status:NIMKitAuthorizationStatusNotSupport];
    }
}

+ (void)requestAddressBookAuthorization:(void (^)(NIMKitAuthorizationStatus))callback
{
    ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
    if (authStatus == kABAuthorizationStatusNotDetermined) {
        __block ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (addressBook == NULL) {
            [self executeCallback:callback status:NIMKitAuthorizationStatusNotSupport];
            return;
        }
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [self executeCallback:callback status:NIMKitAuthorizationStatusAuthorized];
            } else {
                [self executeCallback:callback status:NIMKitAuthorizationStatusDenied];
            }
            if (addressBook) {
                CFRelease(addressBook);
                addressBook = NULL;
            }
        });
        return;
    } else if (authStatus == kABAuthorizationStatusAuthorized) {
        [self executeCallback:callback status:NIMKitAuthorizationStatusAuthorized];
    } else if (authStatus == kABAuthorizationStatusDenied) {
        [self executeCallback:callback status:NIMKitAuthorizationStatusDenied];
    } else if (authStatus == kABAuthorizationStatusRestricted) {
        [self executeCallback:callback status:NIMKitAuthorizationStatusRestricted];
    }
}


#pragma mark - callback
+ (void)executeCallback:(void (^)(NIMKitAuthorizationStatus))callback status:(NIMKitAuthorizationStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (callback) {
            callback(status);
        }
    });
}

@end
