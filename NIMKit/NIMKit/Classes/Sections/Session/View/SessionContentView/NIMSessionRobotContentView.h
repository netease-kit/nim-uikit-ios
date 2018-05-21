//
//  NIMSessionRobotContentView.h
//  NIMKit
//
//  Created by chris on 2017/6/27.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMSessionMessageContentView.h"

@interface NIMSessionRobotContentView : NIMSessionMessageContentView

// 参与 cell 行高的接口
- (void)setupRobot:(NIMMessageModel *)data;

+ (CGFloat)itemSpacing;

@end
