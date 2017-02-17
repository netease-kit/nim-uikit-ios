//
//  NTESSettingPushNotifySwitcherCell.m
//  NIM
//
//  Created by chris on 15/6/26.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NIMKitSwitcherCell.h"
#import "NIMCommonTableData.h"
#import "UIView+NIM.h"


@interface NIMKitSwitcherCell ()

@end

@implementation NIMKitSwitcherCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self addSubview:_switcher];
    }
    return self;
}


- (void)refreshData:(NIMCommonTableRow *)rowData tableView:(UITableView *)tableView{
    self.textLabel.text       = rowData.title;
    self.detailTextLabel.text = rowData.detailTitle;
    NSString *actionName      = rowData.cellActionName;
    [self.switcher setOn:[rowData.extraInfo boolValue] animated:NO];
    [self.switcher removeTarget:self.nim_viewController action:NULL forControlEvents:UIControlEventValueChanged];
    if (actionName.length) {
        SEL sel = NSSelectorFromString(actionName);
        [self.switcher addTarget:tableView.nim_viewController action:sel forControlEvents:UIControlEventValueChanged];
    }
}



#define SwitcherRight 15
- (void)layoutSubviews{
    [super layoutSubviews];
    self.switcher.nim_right   = self.nim_width - SwitcherRight;
    self.switcher.nim_centerY = self.nim_height * .5f;
}

@end
