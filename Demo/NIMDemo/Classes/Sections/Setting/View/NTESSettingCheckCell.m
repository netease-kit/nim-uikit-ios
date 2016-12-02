//
//  NTESSettingCheckCell.m
//  NIM
//
//  Created by chris on 15/9/17.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESSettingCheckCell.h"
#import "NIMCommonTableData.h"
#import "UIView+NTES.h"

@interface NTESSettingCheckCell()

@property (nonatomic,strong) UIButton *checkBox;

@end

@implementation NTESSettingCheckCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _checkBox = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backgroundImage = [UIImage imageNamed:@"icon_checkbox_background"];
        _checkBox.size = backgroundImage.size;
        [_checkBox setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        [_checkBox setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
        [_checkBox setBackgroundImage:backgroundImage forState:UIControlStateSelected];
        [_checkBox setImage:[UIImage imageNamed:@"icon_checkbox_unselected"] forState:UIControlStateNormal];
        [_checkBox setImage:[UIImage imageNamed:@"icon_checkbox_selected"] forState:UIControlStateSelected];
        [_checkBox setImage:[UIImage imageNamed:@"icon_checkbox_selected"] forState:UIControlStateHighlighted];
        [self addSubview:_checkBox];
        
    }
    return self;
}

- (void)refreshData:(NIMCommonTableRow *)rowData tableView:(UITableView *)tableView{
    self.textLabel.text    = rowData.title;
    self.checkBox.selected = [rowData.extraInfo boolValue];
    [self.checkBox removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    NSString *actionName   = rowData.cellActionName;
    if (actionName.length) {
        SEL sel = NSSelectorFromString(actionName);
        [self.checkBox addTarget:tableView.viewController action:sel forControlEvents:UIControlEventTouchUpInside];
    }
}


- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat right         = 15.f;
    self.checkBox.right   = self.width - right;
    self.checkBox.centerY = self.height * .5f;
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    
}

@end
