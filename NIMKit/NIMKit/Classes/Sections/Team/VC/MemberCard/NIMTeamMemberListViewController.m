//
//  NTESTeamMemberListViewController.m
//  NIM
//
//  Created by chris on 15/3/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamMemberListViewController.h"
#import "NIMCardHeaderCell.h"
#import "NIMTeamCardMemberItem.h"
#import "NIMTeamMemberCardViewController.h"
#import "NIMKitDependency.h"
#import "NIMKitProgressHUD.h"
#import "NIMGlobalMacro.h"
#import "NSString+NIMKit.h"

#define CollectionCellReuseId @"cell"
#define CollectionItemWidth  55
#define CollectionItemHeight 80
#define CollectionEdgeInsetLeftRight 20

#define CollectionEdgeInsetTopFirstLine 25
#define CollectionEdgeInsetTop 15

typedef void(^NIMTeamMemberListFetchDataBlock)(BOOL isCompletion);

@interface NIMTeamMemberListViewController ()<UICollectionViewDelegate,
                                              UICollectionViewDataSource,
                                              NIMCardHeaderCellDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, weak) id <NIMTeamMemberListDataSource> dataSource;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) NSInteger totalPageCount;
@property (nonatomic, strong) UIButton *nextBtn;
@property (nonatomic, strong) UIButton *lastBtn;
@end

@implementation NIMTeamMemberListViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithDataSource:(id<NIMTeamMemberListDataSource>)dataSource {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _dataSource = dataSource;
        _pageIndex = 0;
        extern NSString *kNIMTeamListDataTeamMembersChanged;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(teamMemberUpdate:) name:kNIMTeamListDataTeamMembersChanged object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadNextData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refreshPage];
    [_collectionView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)refreshPage {
    NSInteger itemCountPerPage = self.itemCountPerPage;
    NSInteger memberNumber = _dataSource.memberNumber;
    _totalPageCount = memberNumber / itemCountPerPage;
    
    if (memberNumber%itemCountPerPage != 0) {
        _totalPageCount++;
    }
    self.navigationItem.title = [NSString stringWithFormat:@"群成员(%d/%d页)".nim_localized, (int)_pageIndex+1, (int)_totalPageCount];
    _nextBtn.hidden = (_totalPageCount == 1 || _pageIndex == _totalPageCount - 1);
    _lastBtn.hidden = (_totalPageCount == 1 || _pageIndex == 0);
}

- (void)setupUI {
    _nextBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _nextBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    [_nextBtn setTitle:@"下一页".nim_localized forState:UIControlStateNormal];
    [_nextBtn addTarget:self action:@selector(nextPageAction:) forControlEvents:UIControlEventTouchUpInside];
    _nextBtn.frame = CGRectMake(0, 0, 40, 40);
    _nextBtn.hidden = YES;
    _lastBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _lastBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];

    [_lastBtn setTitle:@"上一页".nim_localized forState:UIControlStateNormal];
    _lastBtn.frame = CGRectMake(0, 0, 40, 40);
    _lastBtn.hidden = YES;
    [_lastBtn addTarget:self action:@selector(lastPageAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *nextBtnItem =[[UIBarButtonItem alloc] initWithCustomView:_nextBtn];
    UIBarButtonItem *lastBtnItem = [[UIBarButtonItem alloc] initWithCustomView:_lastBtn];
    self.navigationItem.rightBarButtonItems = @[nextBtnItem, lastBtnItem];
    [self.view addSubview:self.collectionView];
}

- (void)loadNextData {
    NSInteger itemCountPerPage = [self itemCountPerPage];
    NIMMembersFetchOption *option = [[NIMMembersFetchOption alloc] init];
    option.offset = _pageIndex*itemCountPerPage;
    option.count = itemCountPerPage;
    option.isRefresh = NO;
    __weak typeof(self) weakSelf = self;
    [NIMKitProgressHUD show];
    [_dataSource fetchTeamMembersWithOption:option completion:^(NSError * _Nullable error, NSString * _Nullable msg) {
        [NIMKitProgressHUD dismiss];
        if (error) {
            [weakSelf.view makeToast:msg duration:2 position:CSToastPositionCenter];
        } else {
            [weakSelf refreshPage];
            [weakSelf.collectionView reloadData];
        }
    }];
}

#pragma mark - Actions
- (void)nextPageAction:(id)sender {
    NSInteger targetPage = _pageIndex+1;
    NSInteger itemCountPerPage = [self itemCountPerPage];
    _pageIndex++;
    if (targetPage*itemCountPerPage + itemCountPerPage > _dataSource.members.count) { //需要加载新数据
        [self loadNextData];
    } else {
        [self refreshPage];
        [_collectionView reloadData];
    }
}

- (void)lastPageAction:(id)sender {
    if (_pageIndex == 0) {
        return;
    }
    _pageIndex--;
    [self refreshPage];
    [_collectionView reloadData];
}

- (void)teamMemberUpdate:(NSNotification *)note {
    [self refreshPage];
    [_collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger count = 0;
    if (_pageIndex == _totalPageCount - 1) {
        count = _dataSource.members.count - _pageIndex * self.itemCountPerPage;
    } else if (_pageIndex < _totalPageCount - 1) {
        count = self.itemCountPerPage;
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NIMCardHeaderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellReuseId forIndexPath:indexPath];
    cell.delegate = self;
    NSInteger index = _pageIndex * self.itemCountPerPage + indexPath.row;
    id<NIMKitCardHeaderData> data = _dataSource.members[index];
    [cell refreshData:data];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(CollectionItemWidth, CollectionItemHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if (section == 0) {
        return UIEdgeInsetsMake(CollectionEdgeInsetTopFirstLine, 0, 0, 0);
    }
    return UIEdgeInsetsMake(CollectionEdgeInsetTop, 0, 0, 0);
}

#pragma mark - NIMCardHeaderCellDelegate
- (void)cellDidSelected:(NIMCardHeaderCell*)cell{
    NSIndexPath *indexpath = [self.collectionView indexPathForCell:cell];
    NSInteger index = _pageIndex * self.itemCountPerPage + indexpath.row;
    NIMTeamCardMemberItem *member = _dataSource.members[index];
    NIMTeamMemberCardViewController *vc = [[NIMTeamMemberCardViewController alloc] initWithMember:member.userId
                                                                                       dataSource:_dataSource];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 旋转处理 (iOS8 or above)
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = CollectionEdgeInsetLeftRight;
    [self.collectionView setCollectionViewLayout:flowLayout animated:YES];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context)
     {
         [self.collectionView reloadData];
     } completion:nil];
}

#pragma mark - Private
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
        flowLayout.minimumInteritemSpacing = CollectionEdgeInsetLeftRight;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _collectionView.backgroundColor = [UIColor colorWithRed:236.0/255.0 green:241.0/255.0 blue:245.0/255.0 alpha:1];
        _collectionView.delegate   = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[NIMCardHeaderCell class] forCellWithReuseIdentifier:CollectionCellReuseId];
        _collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top,
                                                        CollectionEdgeInsetLeftRight,
                                                        _collectionView.contentInset.bottom,
                                                        CollectionEdgeInsetLeftRight);
    }
    return _collectionView;
}

- (NSInteger)itemCountPerPage {
    CGFloat minSpace = 20.f; //防止计算到最后出现左右贴边的情况
    NSInteger lines = (self.collectionView.frame.size.width - minSpace)/ (CollectionItemWidth + CollectionEdgeInsetLeftRight);
    NSInteger rows = (self.collectionView.frame.size.height - minSpace)/(CollectionItemHeight + CollectionEdgeInsetLeftRight);
    return rows * lines;
}

@end
