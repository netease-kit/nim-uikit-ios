//
//  NTESTimePickerView.m
//  NIM
//
//  Created by chris on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTimePickerView.h"
#import "UIView+NIM.h"
#import "NIMGlobalMacro.h"

@interface NIMTimePickerView()<UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic,strong) UIButton *bkgBtn;

@property (nonatomic,strong) UIPickerView *pickerView;

@property (nonatomic,copy) CompletionHandler handler;

@end

@implementation NIMTimePickerView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = NIMKit_UIColorFromRGBA(0x0, .5f);
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _bkgBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_bkgBtn addTarget:self action:@selector(onActionTouchBkgBtn:) forControlEvents:UIControlEventTouchUpInside];
        _bkgBtn.frame = self.bounds;
        _bkgBtn.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_bkgBtn];
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 250)];
        _pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _pickerView.backgroundColor = [UIColor whiteColor];
        _pickerView.delegate   = self;
        _pickerView.dataSource = self;
        [self addSubview:_pickerView];
    }
    return self;
}


- (void)refreshWithHour:(NSInteger)hour minute:(NSInteger)minute{
    [self.pickerView selectRow:hour inComponent:0 animated:YES];
    [self.pickerView selectRow:minute inComponent:2 animated:YES];
}

- (void)onActionTouchBkgBtn:(id)sender{
    NSInteger hour   = [self.pickerView selectedRowInComponent:0];
    NSInteger minute = [self.pickerView selectedRowInComponent:2];
    if ([self.delegate respondsToSelector:@selector(didSelectHour:minute:)]) {
        [self.delegate didSelectHour:hour minute:minute];
    }
    if (self.handler) {
        self.handler(hour,minute);
    }
    [self removeFromSuperview];
}


- (void)showInView:(UIView *)view onCompletion:(CompletionHandler) handler
{
    self.frame = view.bounds;
    [view addSubview:self];
    self.handler = handler;
}


- (void)layoutSubviews{
    [super layoutSubviews];
    self.pickerView.nim_bottom = self.nim_height;
    self.nim_centerX = self.nim_width * .5f;
}

#pragma mark - UIPickerViewDelegate
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    CGFloat alpha = 0.0f;
    switch (component) {
        case 0:
            alpha = .2f;
            break;
        case 1:
            alpha = .12f;
            break;
        case 2:
            alpha = .2f;
            break;
        case 3:
            alpha = .12f;
            break;
        default:
            break;
    }
    return pickerView.nim_width * alpha;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    switch (component) {
        case 0:         //小时
            return [NSString stringWithFormat:@"%02zd",row];
        case 1:         //小时说明文字
            return @"时";
        case 2:
            return [NSString stringWithFormat:@"%02zd",row];
        case 3:
            return @"分";
        default:
            return @"";
    }
    
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 4;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    switch (component) {
        case 0:
            return 24;//小时
        case 1:
            return 1; //小时说明文字
        case 2:
            return 60;//分钟
        case 3:
            return 1; //分钟说明文字
        default:
            return 0;
    }
}

@end
