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
#import "UIImage+NIM.h"

const NSInteger InputEmoticonTabViewHeight = 35;
const NSInteger InputEmoticonSendButtonWidth = 50;

const CGFloat InputLineBoarder = .5f;

@interface NIMInputEmoticonTabView()

@property (nonatomic,strong) NSMutableArray * tabs;

@property (nonatomic,strong) NSMutableArray * seps;

@end


@implementation NIMInputEmoticonTabView
- (instancetype)initWithFrame:(CGRect)frame catalogs:(NSArray*)emoticonCatalogs{
    self = [super initWithFrame:CGRectMake(0, 0, frame.size.width, InputEmoticonTabViewHeight)];
    if (self) {
        _emoticonCatalogs = emoticonCatalogs;
        _tabs = [[NSMutableArray alloc] init];
        _seps = [[NSMutableArray alloc] init];
        UIColor *sepColor = NIMKit_UIColorFromRGB(0x8A8E93);
        for (NIMInputEmoticonCatalog * catelog in emoticonCatalogs) {
            UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setImage:[UIImage nim_fetchImage:catelog.icon] forState:UIControlStateNormal];
            [button setImage:[UIImage nim_fetchImage:catelog.iconPressed] forState:UIControlStateHighlighted];
            [button setImage:[UIImage nim_fetchImage:catelog.iconPressed] forState:UIControlStateSelected];
            [button addTarget:self action:@selector(onTouchTab:) forControlEvents:UIControlEventTouchUpInside];
            [button sizeToFit];
            [self addSubview:button];
            [_tabs addObject:button];
            
            UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, 0, InputLineBoarder, InputEmoticonTabViewHeight)];
            sep.backgroundColor = sepColor;
            [_seps addObject:sep];
            [self addSubview:sep];
        }
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:13.f];
        
        [_sendButton setBackgroundImage:[UIImage nim_imageInKit:@"icon_input_send_btn_normal"] forState:UIControlStateNormal];
        [_sendButton setBackgroundImage:[UIImage nim_imageInKit:@"icon_input_send_btn_pressed"] forState:UIControlStateHighlighted];
        
        _sendButton.nim_height = InputEmoticonTabViewHeight;
        _sendButton.nim_width = InputEmoticonSendButtonWidth;
        [self addSubview:_sendButton];
        
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.nim_width,InputLineBoarder)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        view.backgroundColor = sepColor;
        [self addSubview:view];
    }
    return self;
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
        sep.nim_left = button.nim_right + spacing;
        left = sep.nim_right + spacing;
    }
    _sendButton.nim_right = self.nim_width;
}


@end

