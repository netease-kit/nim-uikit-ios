//
//  NTESBirthPickerView.m
//  NIM
//
//  Created by chris on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESBirthPickerView.h"
#import "UIView+NTES.h"

#define NTESBrithMinYear 1900
#define NTESBrithMAXYear 2015

@interface NTESBirthPickerView()<UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic,strong) UIButton *bkgBtn;

@property (nonatomic,strong) UIPickerView *pickerView;

@property (nonatomic,copy) CompletionHandler handler;

@property (nonatomic,strong) NSDateFormatter *formateter;

@property (nonatomic,strong) NSCalendar *calendar;

@end

@implementation NTESBirthPickerView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorFromRGBA(0x0, .5f);
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _bkgBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_bkgBtn addTarget:self action:@selector(onActionTouchBkgBtn:) forControlEvents:UIControlEventTouchUpInside];
        _bkgBtn.frame = self.bounds;
        _bkgBtn.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_bkgBtn];
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 250)];
        _pickerView.backgroundColor = [UIColor whiteColor];
        _pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _pickerView.delegate   = self;
        _pickerView.dataSource = self;
        [self addSubview:_pickerView];
        
        _formateter = [[NSDateFormatter alloc] init];
        [_formateter setDateFormat:@"yyyy-MM-dd"];
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    }
    return self;
}


- (void)refreshWithBrith:(NSString *)birth{
    if (![self isVaildBirth:birth]) {
        birth = @"1990-01-01";
    }
    if ([birth isKindOfClass:[NSString class]]) {
        NSDate* date = [self.formateter dateFromString:birth];
        if (date) {
            NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
            NSInteger year  = components.year - NTESBrithMinYear > 0? components.year - NTESBrithMinYear : 0;
            NSInteger month = components.month - 1 > 0? components.month - 1 : 0;
            NSInteger day   = components.day - 1 > 0? components.day - 1 : 0;
            [self.pickerView selectRow:year inComponent:0 animated:NO];
            [self.pickerView selectRow:month inComponent:2 animated:NO];
            [self.pickerView selectRow:day inComponent:4 animated:NO];
        }
    }

}

- (void)onActionTouchBkgBtn:(id)sender{
    NSString *birth = [self formateDate:self.year month:self.month day:self.day];
    if ([self.delegate respondsToSelector:@selector(didSelectBirth:)]) {
        [self.delegate didSelectBirth:birth];
    }
    if (self.handler) {
        self.handler(birth);
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
    self.pickerView.bottom = self.height;
    self.centerX = self.width * .5f;
}

#pragma mark - UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    [pickerView reloadComponent:4];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    CGFloat alpha = 0.0f;
    switch (component) {
        case 0:
            alpha = .22f;
            break;
        case 1:
            alpha = .12f;
            break;
        case 2:
            alpha = .14f;
            break;
        case 3:
            alpha = .12f;
            break;
        case 4:
            alpha = .14f;
            break;
        case 5:
            alpha = .12f;
            break;
        default:
            break;
    }
    return pickerView.width * alpha;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    switch (component) {
        case 0:         //年
            return [NSString stringWithFormat:@"%zd",row+NTESBrithMinYear];
        case 1:         //小时说明文字
            return @"年";
        case 2:
            return [NSString stringWithFormat:@"%zd",row+1];
        case 3:
            return @"月";
        case 4:
            return [NSString stringWithFormat:@"%zd",row+1];
        case 5:
            return @"日";
        default:
            return @"";
    }
    
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 6;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    switch (component) {
        case 0:
            return NTESBrithMAXYear - NTESBrithMinYear + 1;//年
        case 1:
            return 1; //年说明文字
        case 2:
            return 12;//月
        case 3:
            return 1; //月说明文字
        case 4:
            return [self daysInMonth:self.month year:self.year];
        case 5:
            return 1; //日说明文字
        default:
            return 0;
    }
}


#pragma mark - Private
- (NSInteger)year{
    return NTESBrithMinYear + [self.pickerView selectedRowInComponent:0];
}

- (NSInteger)month{
    return [self.pickerView selectedRowInComponent:2] + 1;
}

- (NSInteger)day{
    return [self.pickerView selectedRowInComponent:4] + 1;
}

- (NSInteger)daysInMonth:(NSInteger)month year:(NSInteger)year{
    NSString *formatedDate = [self formateDate:year month:month day:1];
    NSDate* date = [self.formateter dateFromString:formatedDate];
    NSRange range = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    NSUInteger numberOfDaysInMonth = range.length;
    return numberOfDaysInMonth;
}

- (NSString *)formateDate:(NSInteger)year month:(NSInteger)month day:(NSInteger)day{
    return [NSString stringWithFormat:@"%zd-%02zd-%02zd",year,month,day];
}

- (BOOL)isVaildBirth:(NSString *)birth{
    if ([birth isKindOfClass:[NSString class]]) {
        NSDate* date = [self.formateter dateFromString:birth];
        if (date) {
            NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
            NSInteger year  = components.year;
            return year >= NTESBrithMinYear && year <= NTESBrithMAXYear;
        }
    }
    return NO;
}

@end
