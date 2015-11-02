//
//  NIMUIConfig.h
//  NIMKit
//
//  Created by amao on 8/19/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

//UI常量

#import <Foundation/Foundation.h>

@interface NIMUIConfig : NSObject
//输入框上部高度
+ (CGFloat)topInputViewHeight;

//输入框下部高度(内容区域)
+ (CGFloat)bottomInputViewHeight;

//默认消息条数
+ (NSInteger)messageLimit;

//会话列表中时间打点间隔
+ (NSTimeInterval)messageTimeInterval;
@end
