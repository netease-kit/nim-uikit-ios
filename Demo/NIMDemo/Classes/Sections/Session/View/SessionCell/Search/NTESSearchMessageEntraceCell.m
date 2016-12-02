//
//  NTESSearchMessageEntraceCell.m
//  NIM
//
//  Created by chris on 15/7/8.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESSearchMessageEntraceCell.h"
#import "UIView+NTES.h"

@interface NTESSearchMessageEntraceCell()

@end

@implementation NTESSearchMessageEntraceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.textColor = [UIColor blueColor];
    }
    return self;
}

- (void)refresh:(NTESSearchLocalHistoryObject *)object{
    self.textLabel.text = object.content;
    [self.textLabel sizeToFit];
}


#define TextLabelLeft 20.f
- (void)layoutSubviews{
    [super layoutSubviews];
    self.textLabel.left    = TextLabelLeft;
    self.textLabel.centerY = self.height * .5f;
}

@end
