//
//  NTESChatroomTextContentView.h
//  NIM
//
//  Created by chris on 16/1/13.
//  Copyright © 2016年 Netease. All rights reserved.
//


#import "NIMSessionMessageContentView.h"

@class M80AttributedLabel;

@interface NTESChatroomTextContentView : NIMSessionMessageContentView

@property (nonatomic, strong) M80AttributedLabel *textLabel;

@end
