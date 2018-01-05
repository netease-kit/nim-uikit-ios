//
//  NIMSessionTextContentView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionMessageContentView.h"
@class M80AttributedLabel;

@interface NIMSessionTextContentView : NIMSessionMessageContentView

@property (nonatomic, strong) M80AttributedLabel *textLabel;

@end
