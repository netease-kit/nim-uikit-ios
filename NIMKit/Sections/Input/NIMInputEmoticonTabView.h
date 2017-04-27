//
//  NIMInputEmoticonTabView.h
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NIMInputEmoticonTabView;

@protocol NIMInputEmoticonTabDelegate <NSObject>

- (void)tabView:(NIMInputEmoticonTabView *)tabView didSelectTabIndex:(NSInteger) index;

@end

@interface NIMInputEmoticonTabView : UIControl

@property (nonatomic,strong) UIButton * sendButton;

@property (nonatomic,weak)   id<NIMInputEmoticonTabDelegate>  delegate;

- (void)selectTabIndex:(NSInteger)index;

- (void)loadCatalogs:(NSArray*)emoticonCatalogs;

@end






