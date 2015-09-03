//
//  NIMInputTextView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NIMInputTextView : UITextView

@property (nonatomic, strong) NSString *placeHolder;

- (void)setCustomUI;

@end
