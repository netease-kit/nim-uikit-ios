//
//  NIMContactSelectViewController.m
//  NIMKit
//
//  Created by chris on 15/9/14.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMContactSelectViewController.h"
#import "NIMContactSelectTabView.h"
#import "NIMContactPickedView.h"
#import "NIMGroupedUsrInfo.h"
#import "NIMGroupedData.h"
#import "NIMContactDataCell.h"
#import "UIView+NIM.h"
#import "NIMKit.h"
#import "NIMKitDependency.h"
#import "NIMGlobalMacro.h"

@interface NIMContactSelectViewController ()<UITableViewDataSource, UITableViewDelegate, NIMContactPickedViewDelegate>{
    NSMutableArray *_selectecContacts;
}
@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NIMContactSelectTabView *selectIndicatorView;

@property (nonatomic, assign) NSInteger maxSelectCount;

@property(nonatomic, strong) NSDictionary *contentDic;

@property(nonatomic, strong) NSArray *sectionTitles;

@end

@implementation NIMContactSelectViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        _maxSelectCount = NSIntegerMax;
    }
    return self;
}

- (instancetype)initWithConfig:(id<NIMContactSelectConfig>) config{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.config = config;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = NIMKit_UIColorFromRGB(0x383836);
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    [self.view addSubview:self.selectIndicatorView];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self setUpNav];
    
    self.selectIndicatorView.pickedView.delegate = self;
    [self.selectIndicatorView.doneButton addTarget:self action:@selector(onDoneBtnClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpNav
{
    self.navigationItem.title = [self.config respondsToSelector:@selector(title)] ? [self.config title] : @"选择联系人".nim_localized;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelBtnClick:)];
    if ([self.config respondsToSelector:@selector(showSelectDetail)] && self.config.showSelectDetail) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:label];
        [label setText:self.detailTitle];
        [label sizeToFit];
    }
}

- (void)refreshDetailTitle
{
    UILabel *label = (UILabel *)self.navigationItem.rightBarButtonItem.customView;
    [label setText:self.detailTitle];
    [label sizeToFit];
}

- (NSString *)detailTitle
{
    NSString *detail = @"";
    if ([self.config respondsToSelector:@selector(maxSelectedNum)])
    {
        detail = [NSString stringWithFormat:@"%zd/%zd",_selectecContacts.count,_maxSelectCount];
    }
    else
    {
        detail = [NSString stringWithFormat:@"已选%zd人".nim_localized,_selectecContacts.count];
    }
    return detail;
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *))
    {
        safeAreaInsets = self.view.safeAreaInsets;
    }
    
    self.selectIndicatorView.nim_width = self.view.nim_width;
    self.tableView.nim_height = self.view.nim_height - self.selectIndicatorView.nim_height - safeAreaInsets.bottom;
    self.selectIndicatorView.nim_bottom = self.view.nim_height - safeAreaInsets.bottom;
}

- (void)show{
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [vc presentViewController:[[UINavigationController alloc] initWithRootViewController:self] animated:YES completion:nil];
}

- (void)setConfig:(id<NIMContactSelectConfig>)config{
    _config = config;
    if ([config respondsToSelector:@selector(maxSelectedNum)]) {
        _maxSelectCount = [config maxSelectedNum];
        _contentDic = @{}.mutableCopy;
        _sectionTitles = @[].mutableCopy;
    }
    [self makeData];
}

- (void)onCancelBtnClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^() {
        if (self.cancelBlock) {
            self.cancelBlock();
            self.cancelBlock = nil;
        }
        if([_delegate respondsToSelector:@selector(didCancelledSelect)]) {
            [_delegate didCancelledSelect];
        }
    }];
}

- (IBAction)onDoneBtnClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];    
    if (_selectecContacts.count) {
        if ([self.delegate respondsToSelector:@selector(didFinishedSelect:)]) {
            [self.delegate didFinishedSelect:_selectecContacts];
        }
        if (self.finshBlock) {
            self.finshBlock(_selectecContacts);
            self.finshBlock = nil;
        }
    }
    else {
        if([_delegate respondsToSelector:@selector(didCancelledSelect)]) {
            [_delegate didCancelledSelect];
        }
        if (self.cancelBlock) {
            self.cancelBlock();
            self.cancelBlock = nil;
        }
    }
}

- (void)makeData{
    NIMKit_WEAK_SELF(weakSelf);
    [self.config getContactData:^(NSDictionary *contentDic, NSArray *titles) {
        self.contentDic = contentDic;
        self.sectionTitles = titles;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    }];
    if ([self.config respondsToSelector:@selector(alreadySelectedMemberId)])
    {
        _selectecContacts = [[self.config alreadySelectedMemberId] mutableCopy];
    }
    
    _selectecContacts = _selectecContacts.count ? _selectecContacts : [NSMutableArray array];
    for (NSString *selectId in _selectecContacts) {
        NIMKitInfo *info;
        info = [self.config getInfoById:selectId];
        [self.selectIndicatorView.pickedView addMemberInfo:info];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *arr = [self.contentDic valueForKey:self.sectionTitles[section]];
    return arr.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.sectionTitles[0] isEqualToString:@"$"] && section == 0) {
        return @"机器人".nim_localized;
    }else {
        return self.sectionTitles[section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = self.sectionTitles[indexPath.section];
    NSMutableArray *arr = [self.contentDic valueForKey:title];
    id<NIMGroupMemberProtocol> contactItem = arr[indexPath.row];
    
    NIMContactDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectContactCellID"];
    if (cell == nil) {
        cell = [[NIMContactDataCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectContactCellID"];
    }
    cell.accessoryBtn.hidden = NO;
    cell.accessoryBtn.selected = [_selectecContacts containsObject:[contactItem memberId]];
    [cell refreshItem:contactItem];
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.sectionTitles mutableCopy];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSString *title = self.sectionTitles[indexPath.section];
    NSMutableArray *arr = [self.contentDic valueForKey:title];
    id<NIMGroupMemberProtocol> member = arr[indexPath.row];

    NSString *memberId = [(id<NIMGroupMemberProtocol>)member memberId];
    NIMContactDataCell *cell = (NIMContactDataCell *)[tableView cellForRowAtIndexPath:indexPath];
    NIMKitInfo *info;
    info = [self.config getInfoById:memberId];
    if([_selectecContacts containsObject:memberId]) {
        [_selectecContacts removeObject:memberId];
        cell.accessoryBtn.selected = NO;
        [self.selectIndicatorView.pickedView removeMemberInfo:info];
    } else if(_selectecContacts.count >= _maxSelectCount) {
        if ([self.config respondsToSelector:@selector(selectedOverFlowTip)]) {
            NSString *tip = [self.config selectedOverFlowTip];
            [self.view makeToast:tip duration:2.0 position:CSToastPositionCenter];
        }
        cell.accessoryBtn.selected = NO;
    } else {
        [_selectecContacts addObject:memberId];
        cell.accessoryBtn.selected = YES;
        [self.selectIndicatorView.pickedView addMemberInfo:info];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self refreshDetailTitle];
}

#pragma mark - ContactPickedViewDelegate

- (void)removeUser:(NSString *)userId {
    [_selectecContacts removeObject:userId];
    [_tableView reloadData];
    [self refreshDetailTitle];
}

#pragma mark - Private

- (NIMContactSelectTabView *)selectIndicatorView{
    if (_selectIndicatorView) {
        return _selectIndicatorView;
    }
    CGFloat tabHeight = 50.f;
    CGFloat tabWidth  = 320.f;
    _selectIndicatorView = [[NIMContactSelectTabView alloc] initWithFrame:CGRectMake(0, 0, tabWidth, tabHeight)];
    return _selectIndicatorView;
}

@end

