//
//  NIMBaseSessionContentConfig.h
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMGlobalMacro.h"

@protocol NIMSessionContentConfig <NSObject>
@required

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message;

- (NSString *)cellContent:(NIMMessage *)message;

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message;


@optional
- (BOOL)enableBackgroundBubbleView:(NIMMessage *)message;

@end

@interface NIMSessionContentConfigFactory : NSObject
+ (instancetype)sharedFacotry;
- (id<NIMSessionContentConfig>)configBy:(NIMMessage *)message;
- (id<NIMSessionContentConfig>)replyConfigBy:(NIMMessage *)message;

@end
