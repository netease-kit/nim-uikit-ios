//
//  NIMInputToolBar.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NIMInputTextView;
@interface NIMInputToolBar : UIView

@property (nonatomic,strong) UIButton    *voiceBtn;

@property (nonatomic,strong) UIButton    *emoticonBtn;

@property (nonatomic,strong) UIButton    *moreMediaBtn;

@property (nonatomic,strong) UIButton    *recordButton;

@property (nonatomic,strong) UIImageView *inputTextBkgImage;

@property (nonatomic,strong) NIMInputTextView *inputTextView;

- (void)setInputBarItemTypes:(NSArray<NSNumber *> *)types;

- (void)resetInputTextView;

@end
