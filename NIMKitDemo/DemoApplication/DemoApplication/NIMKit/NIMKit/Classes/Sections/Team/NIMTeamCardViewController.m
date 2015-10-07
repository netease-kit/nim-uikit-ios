//
//  NTESTeamCardViewController.m
//  NIM
//
//  Created by chris on 15/3/4.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamCardViewController.h"
#import "UIView+NIM.h"
#import "NIMCardMemberItem.h"
#import "NIMTeamCardOperationItem.h"
#import "NIMContactSelectViewController.h"
#import "NIMContactDataItem.h"
#import "NIMTeamCardRowItem.h"
#import "NIMGlobalMacro.h"
#import "NIMKitColorButtonCell.h"
#import "NIMGroupedUsrInfo.h"
#import "NIMTeamSwitchTableViewCell.h"

#define CollectionItemWidth  55 * NIMKit_UIScreenWidth / 320
#define CollectionItemHeight 80 * NIMKit_UIScreenWidth / 320
#define CollectionItemNumber 4
#define CollectionEdgeInsetLeftRight (NIMKit_UIScreenWidth - CollectionItemWidth * CollectionItemNumber) / (CollectionItemNumber + 1)
#define CollectionEdgeInsetTopFirstLine 25
#define CollectionEdgeInsetTop 15
#define CollectionCellReuseId   @"collectionCell"
#define TableCellReuseId        @"tableCell"
#define TableButtonCellReuseId  @"tableButtonCell"
#define TableSwitchReuseId      @"tableSwitchReuseId"

#define TableSepTag 10001

@interface NIMTeamCardViewController ()<NIMContactSelectDelegate,NIMTeamSwitchProtocol>

@property (nonatomic,strong) UICollectionView *collectionView;

@property (nonatomic,strong) NSMutableArray *headerData; //表头collectionView数据

@property (nonatomic,strong) NSArray *bodyData;   //表身数据

@end

@implementation NIMTeamCardViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _headerData = [[NSMutableArray alloc] init];
        _bodyData   = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshTitle];
    self.tableView = [[UITableView alloc] initWithFrame:self.navigationController.view.bounds style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = NIMKit_UIColorFromRGB(0xecf1f5);
    [self.view addSubview:self.tableView];
}

#pragma mark - Data
- (NSArray*)buildBodyData{
//override
    return nil;
}

- (id<NTESCardBodyData>)bodyDataAtIndexPath:(NSIndexPath*)indexpath{
    NSArray *sectionData = self.bodyData[indexpath.section];
    return sectionData[indexpath.row];
}

- (void)reloadMembers:(NSArray*)members{
    self.headerData = [members mutableCopy];
    [self refreshWithMembers:self.headerData];
}

- (void)addMembers:(NSArray*)members{
    NSInteger opeatorCount = 0;
    for (id<NIMKitCardHeaderData> data in self.headerData.reverseObjectEnumerator.allObjects) {
        if ([data respondsToSelector:@selector(opera)]) {
            opeatorCount++;
        }else{
            break;
        }
    }
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.headerData.count - opeatorCount, members.count)];
    [self.headerData insertObjects:members atIndexes:indexSet];
    [self refreshWithMembers:self.headerData];
}

- (void)removeMembers:(NSArray*)members{
    for (id object in members) {
        if ([object isKindOfClass:[NSString class]]) {
            for (id<NIMKitCardHeaderData> data in self.headerData) {
                if ([data respondsToSelector:@selector(memberId)] && [data.memberId isEqualToString:object]) {
                    [self.headerData removeObject:data];
                    break;
                }
            }
        }else{
            [self.headerData removeObject:object];
        }
    }
    [self refreshWithMembers:self.headerData];
}

- (NSArray*)headerUserIds{
    NSMutableArray * uids = [[NSMutableArray alloc] init];
    for (id<NIMKitCardHeaderData> data in self.headerData) {
        if ([data respondsToSelector:@selector(memberId)] && data.memberId.length) {
            [uids addObject:data.memberId];
        }
    }
    return uids;
}


- (id<NIMKitCardHeaderData>)headerDataAtIndexPath:(NSIndexPath*)indexpath{
    NSInteger index = indexpath.section * CollectionItemNumber;
    index += indexpath.row;
    return self.headerData[index];
}

#pragma mark - Refresh
- (void)refreshWithMembers:(NSArray*)members{
    self.headerData = [members mutableCopy];
    [self setUpTableView];
    [self refreshTableBody];
}

- (void)refreshTableHeader{
    [self setupTableHeader];
    [self.collectionView reloadData];
}

- (void)refreshTableBody{
    self.bodyData = [self buildBodyData];
    [self.tableView reloadData];
}

- (void)refreshTitle{
    self.navigationItem.title = self.title;
}

#pragma mark - View
- (NSString*)title{
    return @"";
}

- (void)setUpTableView{
    [self setupTableHeader];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.delegate        = self;
    self.tableView.dataSource      = self;
}

- (void)setupTableHeader{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionView = [[UICollectionView alloc] initWithFrame:[self caculateHeaderFrame] collectionViewLayout:flowLayout];
    self.collectionView.backgroundColor = [UIColor colorWithRed:236.0/255.0 green:241.0/255.0 blue:245.0/255.0 alpha:1];
    self.collectionView.delegate   = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[NIMTeamCardHeaderCell class] forCellWithReuseIdentifier:CollectionCellReuseId];
    self.tableView.tableHeaderView = self.collectionView;
}

- (CGRect)caculateHeaderFrame{
    NSInteger sectionNumber = [self numberOfSectionsInCollectionView:self.collectionView];
    CGFloat height = CollectionItemHeight * sectionNumber + CollectionEdgeInsetTop * (sectionNumber-1) + CollectionEdgeInsetTopFirstLine * 2;
    return CGRectMake(0,0,self.view.nim_width, height);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.bodyData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *sectionData = self.bodyData[section];
    return sectionData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    return bodyData.rowHeight;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    id<NTESCardBodyData> bodyData = [self bodyDataAtIndexPath:indexPath];
    UITableViewCell * cell;
    NIMKitTeamCardRowItemType type = bodyData.type;
    switch (type) {
        case TeamCardRowItemTypeCommon:
            cell = [self builidCommonCell:bodyData indexPath:indexPath];
            break;
        case TeamCardRowItemTypeRedButton:
            cell = [self builidRedButtonCell:bodyData indexPath:indexPath];
            break;
        case TeamCardRowItemTypeBlueButton:
            cell = [self builidBlueButtonCell:bodyData indexPath:indexPath];
            break;
        case TeamCardRowItemTypeSwitch:
            cell = [self buildTeamSwitchCell:bodyData indexPath:indexPath];
            break;
        default:
            break;
    }
    return cell;
}

- (UITableViewCell*)builidCommonCell:(id<NTESCardBodyData>) bodyData indexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableCellReuseId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TableCellReuseId];
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
    if ([bodyData respondsToSelector:@selector(subTitle)]) {
        cell.detailTextLabel.text = bodyData.subTitle;
    }
    
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;

}

- (UITableViewCell*)builidRedButtonCell:(id<NTESCardBodyData>) bodyData indexPath:(NSIndexPath *)indexPath{
    NIMKitColorButtonCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableButtonCellReuseId];
    if (!cell) {
        cell = [[NIMKitColorButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableButtonCellReuseId];
    }
    cell.button.style = NIMKitColorButtonCellStyleRed;
    [cell.button setTitle:bodyData.title forState:UIControlStateNormal];
    return cell;
}


- (UITableViewCell*)builidBlueButtonCell:(id<NTESCardBodyData>) bodyData indexPath:(NSIndexPath *)indexPath{
    NIMKitColorButtonCell * cell = [self.tableView dequeueReusableCellWithIdentifier:TableButtonCellReuseId];
    if (!cell) {
        cell = [[NIMKitColorButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TableButtonCellReuseId];
    }
    cell.button.style = NIMKitColorButtonCellStyleBlue;
    [cell.button setTitle:bodyData.title forState:UIControlStateNormal];
    return cell;
}

- (UITableViewCell *)buildTeamSwitchCell:(id<NTESCardBodyData>)bodyData indexPath:(NSIndexPath *)indexPath
{
    NIMTeamSwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableSwitchReuseId];
    if (!cell) {
        cell = [[NIMTeamSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NIMTeamSwitchTableViewCell"];
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
    cell.switchDelegate = self;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *scections = self.bodyData[indexPath.section];
    id<NTESCardBodyData> bodyData = scections[indexPath.row];
    if ([bodyData respondsToSelector:@selector(actionDisabled)] && bodyData.actionDisabled) {
        return;
    }
    if ([bodyData respondsToSelector:@selector(action)]) {
        if (bodyData.action) {
            NIMKit_SuppressPerformSelectorLeakWarning([self performSelector:bodyData.action]);
        }
    }
}



#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger lastTotal = CollectionItemNumber * section;
    NSInteger remain    = self.headerData.count - lastTotal;
    return remain < CollectionItemNumber ? remain:CollectionItemNumber;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    NSInteger sections = self.headerData.count / CollectionItemNumber;
    return self.headerData.count % CollectionItemNumber ? sections + 1 : sections;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NIMTeamCardHeaderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellReuseId forIndexPath:indexPath];
    cell.delegate = self;
    id<NIMKitCardHeaderData> data = [self headerDataAtIndexPath:indexPath];
    [cell refreshData:data];
    BOOL showRemoveBtn = data.opera == CardHeaderOpeatorNone && self.currentOpera == CardHeaderOpeatorRemove && ![data.memberId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount];
    cell.removeBtn.hidden = !showRemoveBtn;
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(CollectionItemWidth, CollectionItemHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (section == 0) {
        return UIEdgeInsetsMake(CollectionEdgeInsetTopFirstLine, CollectionEdgeInsetLeftRight, 0, CollectionEdgeInsetLeftRight);
    }
    return UIEdgeInsetsMake(CollectionEdgeInsetTop, CollectionEdgeInsetLeftRight, 0, CollectionEdgeInsetLeftRight);
}

#pragma mark - TeamCardHeaderCellDelegate
- (void)cellDidSelected:(NIMTeamCardHeaderCell*)cell{
    id<NIMKitCardHeaderData> data = cell.data;
    if ([data respondsToSelector:@selector(opera)]) {
        switch (data.opera) {
            case CardHeaderOpeatorAdd:{
                self.currentOpera = CardHeaderOpeatorAdd;
                NSMutableArray *users = [[NSMutableArray alloc] init];
                NSString *currentUserID = [[[NIMSDK sharedSDK] loginManager] currentAccount];
                [users addObject:currentUserID];
                [users addObjectsFromArray:self.headerUserIds];
                NIMContactFriendSelectConfig *config = [[NIMContactFriendSelectConfig alloc] init];
                config.filterIds = users;
                config.needMutiSelected = YES;
                NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
                vc.delegate = self;
                [vc show];
                break;
            }
            case CardHeaderOpeatorRemove:{
                self.currentOpera = self.currentOpera==CardHeaderOpeatorRemove? CardHeaderOpeatorNone : CardHeaderOpeatorRemove;
                [self refreshTableHeader];
                break;
            }
            default:
                break;
        }
    }
}


- (void)cellShouldBeRemoved:(NIMTeamCardHeaderCell *)cell{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    id<NIMKitCardHeaderData> headerData = [self headerDataAtIndexPath:indexPath];
    [self didFinishedSelect:@[headerData.memberId]];
}

#pragma mark - TeamSwitchProtocol
- (void)onStateChanged:(BOOL)on
{
  //override
}

#pragma mark - ContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts{
    //override
}

- (void)didCancelledSelect{
    //override
}


@end
