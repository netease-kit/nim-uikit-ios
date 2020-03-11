//
//  NIMInputEmoticonTabView.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMInputEmoticonTabView.h"
#import "NIMInputEmoticonManager.h"
#import "UIView+NIM.h"
#import "UIImage+NIMKit.h"
#import "NIMGlobalMacro.h"

const NSInteger NIMInputEmoticonTabViewHeight = 35;
const NSInteger NIMInputEmoticonSendButtonWidth = 50;

const CGFloat NIMInputLineBoarder = .5f;

@interface NIMInputEmoticonTabView()

@property (nonatomic,strong) NSMutableArray * tabs;

@property (nonatomic,strong) NSMutableArray * seps;

@end

#define sepColor NIMKit_UIColorFromRGB(0x8A8E93)

@implementation NIMInputEmoticonTabView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:CGRectMake(0, 0, frame.size.width, NIMInputEmoticonTabViewHeight)];
    if (self) {
        _tabs = [[NSMutableArray alloc] init];
        _seps = [[NSMutableArray alloc] init];
        
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendButton setTitle:@"发送".nim_localized forState:UIControlStateNormal];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:13.f];
        [_sendButton setBackgroundColor:NIMKit_UIColorFromRGB(0x0079FF)];
        
        _sendButton.nim_height = NIMInputEmoticonTabViewHeight;
        _sendButton.nim_width = NIMInputEmoticonSendButtonWidth;
        [self addSubview:_sendButton];
        
        self.layer.borderColor = sepColor.CGColor;
        self.layer.borderWidth = NIMInputLineBoarder;
        
    }
    return self;
}


- (void)loadCatalogs:(NSArray*)emoticonCatalogs
{
    for (UIView *subView in [_tabs arrayByAddingObjectsFromArray:_seps]) {
        [subView removeFromSuperview];
    }
    [_tabs removeAllObjects];
    [_seps removeAllObjects];
    for (NIMInputEmoticonCatalog * catelog in emoticonCatalogs) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage nim_emoticonInKit:catelog.icon] forState:UIControlStateNormal];
        [button setImage:[UIImage nim_emoticonInKit:catelog.iconPressed] forState:UIControlStateHighlighted];
        [button setImage:[UIImage nim_emoticonInKit:catelog.iconPressed] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(onTouchTab:) forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        [self addSubview:button];
        [_tabs addObject:button];
        
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, 0, NIMInputLineBoarder, NIMInputEmoticonTabViewHeight)];
        sep.backgroundColor = sepColor;
        [_seps addObject:sep];
        [self addSubview:sep];
    }
}

- (void)onTouchTab:(id)sender{
    NSInteger index = [self.tabs indexOfObject:sender];
    [self selectTabIndex:index];
    if ([self.delegate respondsToSelector:@selector(tabView:didSelectTabIndex:)]) {
        [self.delegate tabView:self didSelectTabIndex:index];
    }
}


- (void)selectTabIndex:(NSInteger)index{
    for (NSInteger i = 0; i < self.tabs.count ; i++) {
        UIButton *btn = self.tabs[i];
        btn.selected = i == index;
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat spacing = 10;
    CGFloat left    = spacing;
    for (NSInteger index = 0; index < self.tabs.count ; index++) {
        UIButton *button = self.tabs[index];
        button.nim_left = left;
        button.nim_centerY = self.nim_height * .5f;
        
        UIView *sep = self.seps[index];
        sep.nim_left = (int)(button.nim_right + spacing);
        left = (int)(sep.nim_right + spacing);
    }
    _sendButton.nim_right = (int)self.nim_width;
}


@end

