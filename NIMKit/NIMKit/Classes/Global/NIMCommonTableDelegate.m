//
//  NTESCommonTableDelegate.m
//  NIM
//
//  Created by chris on 15/6/29.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMCommonTableDelegate.h"
#import "NIMCommonTableData.h"
#import "NIMCommonTableViewCell.h"
#import "UIView+NIM.h"
#import "NIMGlobalMacro.h"

#define SepViewTag 10001

static NSString *DefaultTableCell = @"UITableViewCell";

@interface NIMCommonTableDelegate()

@property (nonatomic,copy) NSArray *(^NTESDataReceiver)(void);

@end

@implementation NIMCommonTableDelegate

- (instancetype) initWithTableData:(NSArray *(^)(void))data{
    self = [super init];
    if (self) {
        _NTESDataReceiver = data;
        _defaultSeparatorLeftEdge = SepLineLeft;
    }
    return self;
}

- (NSArray *)data{
    return self.NTESDataReceiver();
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NIMCommonTableSection *tableSection = self.data[section];
    return tableSection.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NIMCommonTableSection *tableSection = self.data[indexPath.section];
    NIMCommonTableRow     *tableRow     = tableSection.rows[indexPath.row];
    NSString *identity = tableRow.cellClassName.length ? tableRow.cellClassName : DefaultTableCell;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (!cell) {
        Class clazz = NSClassFromString(identity);
        cell = [[clazz alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identity];
        UIView *sep = [[UIView alloc] initWithFrame:CGRectZero];
        sep.tag = SepViewTag;
        sep.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        sep.backgroundColor = [UIColor lightGrayColor];
        [cell addSubview:sep];
    }
    if (![cell respondsToSelector:@selector(refreshData:tableView:)]) {
        UITableViewCell *defaultCell = (UITableViewCell *)cell;
        [self refreshData:tableRow cell:defaultCell];
    }else{
        [(id<NIMCommonTableViewCell>)cell refreshData:tableRow tableView:tableView];
    }
    cell.accessoryType = tableRow.showAccessory ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NIMCommonTableSection *tableSection = self.data[indexPath.section];
    NIMCommonTableRow     *tableRow     = tableSection.rows[indexPath.row];
    return tableRow.uiRowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NIMCommonTableSection *tableSection = self.data[indexPath.section];
    NIMCommonTableRow     *tableRow     = tableSection.rows[indexPath.row];
    if (!tableRow.forbidSelect) {
        UIViewController *vc = tableView.nim_viewController;
        NSString *actionName = tableRow.cellActionName;
        if (actionName.length) {
            SEL sel = NSSelectorFromString(actionName);
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            NIMKit_SuppressPerformSelectorLeakWarning([vc performSelector:sel withObject:cell]);
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    //这里的cell已经有了正确的bounds
    //不在cellForRow的地方设置分割线是因为在ios7下，0.5像素的view利用autoResizeMask调整布局有问题，会导致显示不出来，ios6,ios8均正常。
    //具体问题类似http://stackoverflow.com/questions/30663733/add-a-0-5-point-height-subview-to-uinavigationbar-not-show-in-ios7
    //这个回调里调整分割线的位置
    NIMCommonTableSection *tableSection = self.data[indexPath.section];
    NIMCommonTableRow     *tableRow     = tableSection.rows[indexPath.row];
    UIView *sep = [cell viewWithTag:SepViewTag];
    CGFloat sepHeight = .5f;
    CGFloat sepWidth;
    if (tableRow.sepLeftEdge) {
        sepWidth  = cell.nim_width - tableRow.sepLeftEdge;
    }else{
        NIMCommonTableSection *section = self.data[indexPath.section];
        if (indexPath.row == section.rows.count - 1) {
            //最后一行
            sepWidth = 0;
        }else{
            sepWidth = cell.nim_width - self.defaultSeparatorLeftEdge;
        }
    }
    sepWidth  = sepWidth > 0 ? sepWidth : 0;
    sep.frame = CGRectMake(cell.nim_width - sepWidth, cell.nim_height - sepHeight, sepWidth ,sepHeight);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NIMCommonTableSection *tableSection = self.data[section];
    return tableSection.headerTitle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 25.f;
    }
    NIMCommonTableSection *tableSection = self.data[section];
    return [tableSection.headerTitle sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13.f]}].height;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    NIMCommonTableSection *tableSection = self.data[section];
    return tableSection.footerTitle;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NIMCommonTableSection *tableSection = self.data[section];
    if (tableSection.headerTitle.length) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    NIMCommonTableSection *tableSection = self.data[section];
    if (tableSection.footerTitle.length) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

#pragma mark - Private
- (void)refreshData:(NIMCommonTableRow *)rowData cell:(UITableViewCell *)cell{
    cell.textLabel.text = rowData.title;
    cell.detailTextLabel.text = rowData.detailTitle;
}

@end
