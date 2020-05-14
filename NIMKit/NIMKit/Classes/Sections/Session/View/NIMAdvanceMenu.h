//
//  NIMAdvanceMenu.h
//  NIMKit
//
//  Created by He on 2020/3/26.
//  Copyright © 2020 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMSessionConfig.h"
#import "NIMInputProtocol.h"

@class NIMMessage;

NS_ASSUME_NONNULL_BEGIN

@interface NIMAdvanceMenu : UIView

@property (nonatomic,strong) id<NIMSessionConfig> config;
@property (nonatomic,weak)  id<NIMInputActionDelegate> actionDelegate;

- (instancetype)initWithFrame:(CGRect)frame
                     emotions:(nullable NSArray *)quickEmotions;

- (void)showWithMessage:(NIMMessage *)message;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
