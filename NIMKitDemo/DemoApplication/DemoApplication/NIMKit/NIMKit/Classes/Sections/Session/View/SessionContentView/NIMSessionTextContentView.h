//
//  NIMSessionTextContentView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionMessageContentView.h"
@class NIMAttributedLabel;

@interface NIMSessionTextContentView : NIMSessionMessageContentView

@property (nonatomic, strong) NIMAttributedLabel *textLabel;

@end
