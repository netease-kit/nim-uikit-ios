//
//  NIMKitCustomConfigReader.h
//  NIMKit
//
//  Created by chris on 2016/11/1.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMSDK.h"

@class NIMMessage;
@class NIMMessageModel;

@class NIMKitBubbleConfig;
@class NIMKitGlobalConfig;
@class NIMKitBubbleStyle;

@interface NIMKitUIConfig : NSObject

+ (instancetype)sharedConfig;

- (NSArray *)defaultMediaItems;

- (CGFloat)maxNotificationTipPadding;

- (NIMKitGlobalConfig *)globalConfig;

- (NIMKitBubbleConfig *)bubbleConfig:(NIMMessage *)message;

- (NIMKitBubbleConfig *)unsupportConfig:(NIMMessage *)message;

@end


@interface NIMKitGlobalConfig : NSObject

@property (nonatomic,assign) NSTimeInterval messageInterval;

@property (nonatomic,assign) NSInteger messageLimit;

@property (nonatomic,assign) NSTimeInterval recordMaxDuration;

@property (nonatomic,assign) NSInteger maxLength;

@property (nonatomic,copy)   NSString *placeholder;

@property (nonatomic,assign) CGFloat topInputViewHeight;

@property (nonatomic,assign) CGFloat bottomInputViewHeight;

@end

@interface NIMKitBubbleConfig : NSObject

@property (nonatomic,assign)  UIEdgeInsets contentInset;

@property (nonatomic,copy)    NSString *textColor;

@property (nonatomic,assign)  CGFloat  textFontSize;

@property (nonatomic,assign)  BOOL  showAvatar;


- (UIColor *)contentTextColor;

- (UIFont  *)contentTextFont;

- (UIImage *)bubbleImage:(UIControlState)state;

- (UIEdgeInsets)bubbleInsets:(UIControlState)state;


@end

