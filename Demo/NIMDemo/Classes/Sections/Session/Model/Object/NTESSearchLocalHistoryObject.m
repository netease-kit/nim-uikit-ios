//
//  NTESSearchLocalHistoryObject.m
//  NIM
//
//  Created by chris on 15/7/8.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESSearchLocalHistoryObject.h"
#import "NTESSearchCellLayoutConstant.h"

@implementation NTESSearchLocalHistoryObject

- (instancetype)initWithMessage:(NIMMessage *)message{
    self = [super init];
    if (self) {
        _message = message;
        [self calculateHistoryItemHeight];
    }
    return self;
}


- (void)calculateHistoryItemHeight{
    NSString *content = _message.text;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:SearchCellContentFontSize];
    label.text = content;
    CGSize  labelSize   = [label sizeThatFits:CGSizeMake(SearchCellContentMaxWidth * UISreenWidthScale, CGFLOAT_MAX)];
    CGFloat labelHeight = MAX(SearchCellContentMinHeight, labelSize.height);
    CGFloat height      = labelHeight + SearchCellContentTop + SearchCellContentBottom;
    _uiHeight = height;
}

@end
