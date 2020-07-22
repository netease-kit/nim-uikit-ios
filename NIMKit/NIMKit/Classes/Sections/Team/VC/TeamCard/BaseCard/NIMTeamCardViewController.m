//
//  NIMTeamCardViewController.m
//  NIMKit
//
//  Created by Netease on 2019/6/11.
//  Copyright © 2019 NetEase. All rights reserved.
//  

#import "NIMTeamCardViewController.h"
#import "NIMKitUtil.h"
#import "UIView+NIM.h"
#import "NIMKitColorButtonCell.h"
#import "NIMTeamMemberListCell.h"
#import "NIMKitDependency.h"
#import "NIMTeamCardSelectedViewController.h"

#define TableCellReuseId        @"tableCell"
#define TableButtonCellReuseId  @"tableButtonCell"
#define TableMemberCellReuseId  @"tableMemberCell"
#define TableSwitchReuseId      @"tableSwitchCell"
#define TableSepTag 10001

@interface NIMTeamCardViewController () <UITableViewDataSource,
                                         UITableViewDelegate,
                                         UIImagePickerControllerDelegate,
                                         UINavigationControllerDelegate>
@property (nonatomic, copy) NIMTeamCardPickerHandle pickerSelectedBlock;
@end

@implementation NIMTeamCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableHeaderView = [self didGetHeaderView];
    [self.view addSubview:self.tableView];
}

#pragma mark - Public
- (void)showImagePicker:(UIImagePickerControllerSourceType)type
             completion:(NIMTeamCardPickerHandle)completion {
    _pickerSelectedBlock = [completion copy];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate      = self;
    picker.sourceType    = type;
    picker.allowsEditing = YES;
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

- (UIAlertController *)makeAlertSheetWithTitle:(NSString *)title
                                       actions:(NSArray <UIAlertAction *>*)actions {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [actions enumerateObjectsUsingBlock:^(UIAlertAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [alert addAction:obj];
    }];
    
    [alert addAction:[self makeCancelAction]];
    return alert;
}

- (UIAlertAction *)makeCancelAction {
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消".nim_localized
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    return cancel;
}

- (void)showAlert:(UIAlertController *)alert {
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToastMsg:(NSString *)msg {
    if (msg) {
        [self.view makeToast:msg
                    duration:2.0
                    position:CSToastPositionCenter];
    }
}

#pragma mark - Private
- (id<NTESCardBodyData>)bodyDataAtIndexPath:(NSIndexPath*)indexpath{
    NSArray *sectionData = self.datas[indexpath.section];
    return sectionData[indexpath.row];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    return bodyData.rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.datas.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *sectionData = self.datas[section];
    return sectionData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    UITableViewCell * cell;
    NIMKitTeamCardRowItemType type = bodyData.type;
    switch (type) {
        case TeamCardRowItemTypeCommon:
            cell = [self builidCommonCell:bodyData indexPath:indexPath];
            break;
        case TeamCardRowItemTypeRedButton:
            cell = [self builidRedButtonCell:bodyData];
            break;
        case TeamCardRowItemTypeBlueButton:
            cell = [self builidBlueButtonCell:bodyData ];
            break;
        case TeamCardRowItemTypeTeamMember:
            cell = [self builidTeamMemberCell:bodyData];
            break;
        case TeamCardRowItemTypeSwitch:
            cell = [self buildTeamSwitchCell:bodyData indexPath:indexPath];
            break;
        case TeamCardRowItemTypeSelected:
            cell = [self builidCommonCell:bodyData indexPath:indexPath];
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0.0f;
    }
    return 20.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    return view;
}

- (UITableViewCell*)builidCommonCell:(id<NTESCardBodyData>) bodyData indexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableCellReuseId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TableCellReuseId];
        CGFloat left = 15.f;
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(left, cell.nim_height-1, cell.nim_width, 1.f)];
        sep.backgroundColor = NIMKit_UIColorFromRGB(0xebebeb);
        [sep setTag:TableSepTag];
        [cell addSubview:sep];
        sep.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    
    UIView *sep = [cell viewWithTag:TableSepTag];
    sep.hidden = (indexPath.row + 1 == [self.tableView numberOfRowsInSection:indexPath.section]);
    
    cell.textLabel.text = bodyData.title;
    if ([bodyData respondsToSelector:@selector(subTitle)]) {
        cell.detailTextLabel.text = bodyData.subTitle;
    }
    
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if ([bodyData respondsToSelector:@selector(disableUserInteraction)] && bodyData.disableUserInteraction) {
        cell.userInteractionEnabled = NO;
    } else {
        cell.userInteractionEnabled = YES;
    }
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        return;
    }
    if (bodyData.type == TeamCardRowItemTypeSelected) {
        NIMTeamCardSelectedViewController *vc = [NIMTeamCardSelectedViewController instanceWithTitle:bodyData.title
                                                                               items:bodyData.optionItems
                                                                              result:^(id<NIMKitSelectCardData>  _Nonnull item) {
              if (bodyData.selectedBlock) {
                  bodyData.selectedBlock(item);
              }
          }];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        if ([bodyData respondsToSelector:@selector(action)]) {
            if (bodyData.action) {
                NIMKit_SuppressPerformSelectorLeakWarning([self performSelector:bodyData.action]);
            }
        }
    }
}

- (UITableViewCell*)builidRedButtonCell:(id<NTESCardBodyData>) bodyData{
    NIMKitColorButtonCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableButtonCellReuseId];
    if (!cell) {
        cell = [[NIMKitColorButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableButtonCellReuseId];
    }
    cell.button.style = NIMKitColorButtonCellStyleRed;
    [cell.button setTitle:bodyData.title forState:UIControlStateNormal];
    return cell;
}

- (UITableViewCell*)builidBlueButtonCell:(id<NTESCardBodyData>) bodyData{
    NIMKitColorButtonCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableButtonCellReuseId];
    if (!cell) {
        cell = [[NIMKitColorButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableButtonCellReuseId];
    }
    cell.button.style = NIMKitColorButtonCellStyleBlue;
    [cell.button setTitle:bodyData.title forState:UIControlStateNormal];
    return cell;
}

- (UITableViewCell*)builidTeamMemberCell:(id<NTESCardBodyData>) bodyData{
    NIMTeamMemberListCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableMemberCellReuseId];
    if (!cell) {
        cell = [[NIMTeamMemberListCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TableMemberCellReuseId];
    }
    
    cell.textLabel.text = bodyData.title;
    cell.detailTextLabel.text = bodyData.subTitle;
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [self didBuildTeamMemberCell:cell];

    return cell;
}

- (UITableViewCell *)buildTeamSwitchCell:(id<NTESCardBodyData>)bodyData indexPath:(NSIndexPath *)indexPath
{
    NIMTeamSwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableSwitchReuseId];
    if (!cell) {
        cell = [[NIMTeamSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableSwitchReuseId];
        CGFloat left   = 15.f;
        CGFloat height = 1.f;
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(left, cell.nim_height - height, cell.nim_width, height)];
        sep.backgroundColor = NIMKit_UIColorFromRGB(0xebebeb);
        [cell addSubview:sep];
        [sep setTag:TableSepTag];
        sep.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    
    UIView *sep = [cell viewWithTag:TableSepTag];
    sep.hidden = (indexPath.row + 1 == [self.tableView numberOfRowsInSection:indexPath.section]);
    
    cell.textLabel.text = bodyData.title;
    cell.switcher.on = bodyData.switchOn;
    cell.identify = bodyData.identify;
    
    [self didBuildTeamSwitchCell:cell];
    
    return cell;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    __weak typeof(self) weakSelf = self;
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.pickerSelectedBlock) {
            weakSelf.pickerSelectedBlock(image);
        }
        weakSelf.pickerSelectedBlock = nil;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Setter
- (void)setDatas:(NSArray<NSArray<NIMTeamCardRowItem *> *> *)datas {
    _datas = datas;
    [_tableView reloadData];
}

#pragma mark - 旋转处理 (iOS7)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - 旋转处理 (iOS8 or above)
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:nil];
}

#pragma mark - Getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

#pragma mark - virtual function
- (UIView *)didGetHeaderView { return [UIView new]; }

- (void)didBuildTeamMemberCell:(NIMTeamMemberListCell *)cell {}

- (void)didBuildTeamSwitchCell:(NIMTeamSwitchTableViewCell *)cell {}

- (void)reloadTableViewData {};

- (void)reloadTableHeaderData {};

- (void)reloadOtherData {};

@end
