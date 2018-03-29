//
//  NIMKitKeyboardInfo.h
//  NIMKit
//
//  Created by chris on 2017/11/3.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NIMKitKeyboardInfo : NSObject

//是否可见
@property (nonatomic,assign,readonly) CGFloat isVisiable;

//键盘高度
@property (nonatomic,assign,readonly) CGFloat keyboardHeight;

+ (instancetype)instance;


UIKIT_EXTERN NSNotificationName const NIMKitKeyboardWillChangeFrameNotification;
UIKIT_EXTERN NSNotificationName const NIMKitKeyboardWillHideNotification;


@end
