//
//  NIMSessionMessageContentView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMKitEvent.h"
@class NIMKitBubbleStyleObject;

@protocol NIMMessageContentViewDelegate <NSObject>

- (void)onCatchEvent:(NIMKitEvent *)event;

@end

@class NIMMessageModel;

@interface NIMSessionMessageContentView : UIControl

@property (nonatomic,strong,readonly)  NIMMessageModel   *model;

@property (nonatomic,strong) UIImageView * bubbleImageView;

@property (nonatomic,weak) id<NIMMessageContentViewDelegate> delegate;

/**
 *  contentView初始化方法
 *
 *  @return content实例
 */
- (instancetype)initSessionMessageContentView;

/**
 *  刷新方法
 *
 *  @param data 刷新数据
 */
- (void)refresh:(NIMMessageModel*)data;


/**
 *  手指从contentView内部抬起
 */
- (void)onTouchUpInside:(id)sender;


/**
 *  手指从contentView外部抬起
 */
- (void)onTouchUpOutside:(id)sender;

/**
 *  手指按下contentView
 */
- (void)onTouchDown:(id)sender;


/**
 *  聊天气泡图
 *
 *  @param state    目前的按压状态
 *  @param outgoing 是否是发出去的消息
 *
 */
- (UIImage *)chatBubbleImageForState:(UIControlState)state outgoing:(BOOL)outgoing;

@end

