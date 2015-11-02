//
//  NIMCellConfig.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NIMSessionMessageContentView;
@class NIMMessageModel;

@protocol NIMCellLayoutConfig <NSObject>

@optional

/**
 * @return 返回message的内容大小
 */
- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)width;


/**
 *  需要构造的cellContent类名
 */
- (NSString *)cellContent:(NIMMessageModel *)model;

/**
 *  cell气泡距离整个cell的内间距
 */
- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model;

/**
 *  cell内容距离气泡的内间距
 */
- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model;


/**
 *  是否显示头像
 */
- (BOOL)shouldShowAvatar:(NIMMessageModel *)model;

/**
 *  是否显示姓名
 */
- (BOOL)shouldShowNickName:(NIMMessageModel *)model;


/**
 *  格式化消息文本
 *  @discussion ，仅当cellContent为NIMSessionNotificationContentView时会调用.如果是NIMSessionNotificationContentView的子类,需要继承refresh:方法。
 */
- (NSString *)formatedMessage:(NIMMessageModel *)model;

@end