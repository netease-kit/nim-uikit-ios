//
//  NTESTeamMemberListViewController.m
//  NIM
//
//  Created by chris on 15/3/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMTeamMemberListViewController.h"
#import "NIMTeamCardHeaderCell.h"
#import "NIMCardMemberItem.h"
#import "NIMTeamMemberCardViewController.h"
#import "NIMKitDependency.h"
#import "NIMKitProgressHUD.h"

#define CollectionCellReuseId @"cell"
#define CollectionItemWidth  55
#define CollectionItemHeight 80
#define CollectionEdgeInsetLeftRight 20

#define CollectionEdgeInsetTopFirstLine 25
#define CollectionEdgeInsetTop 15

typedef void(^NIMTeamMemberListFetchDataBlock)(BOOL isCompletion);

@interface NIMTeamMemberListViewController ()<UICollectionViewDelegate,
                                              UICollectionViewDataSource,
                                              NIMTeamCardHeaderCellDelegate,
                                              NIMTeamMemberCardActionDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, weak) id <NIMTeamMemberListDataSource> dataSource;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) NSInteger totalPageCount;
@property (nonatomic, assign) NSInteger currentOffset;
@property (nonatomic, strong) UIButton *nextBtn;
@property (nonatomic, strong) UIButton *lastBtn;
@end

@implementation NIMTeamMemberListViewController

- (instancetype)initWithDataSource:(id<NIMTeamMemberListDataSource>)dataSource {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _dataSource = dataSource;
        _pageIndex = 0;
        _currentOffset = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadNextData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)refreshPage {
    NSInteger totalPage = _dataSource.memberNumber % self.itemCountPerPage == 0 ? _dataSource.memberNumber / self.itemCountPerPage : _dataSource.memberNumber / self.itemCountPerPage + 1;
    self.navigationItem.title = [NSString stringWithFormat:@"群成员(%ld/%ld页)", _pageIndex+1, totalPage];
}

- (void)setupUI {
    _nextBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _nextBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    [_nextBtn setTitle:@"下一页" forState:UIControlStateNormal];
    [_nextBtn addTarget:self action:@selector(nextPageAction:) forControlEvents:UIControlEventTouchUpInside];
    _lastBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _lastBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    [_lastBtn setTitle:@"上一页" forState:UIControlStateNormal];
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
    option.offset = _currentOffset;
    option.count = itemCountPerPage;
    option.isRefresh = NO;
    __weak typeof(self) weakSelf = self;
    [NIMKitProgressHUD show];
    [_dataSource fetchTeamMembersWithOption:option completion:^(NSError * _Nullable error, NSString * _Nullable msg) {
        [NIMKitProgressHUD dismiss];
        if (error) {
            [weakSelf.view makeToast:msg duration:2 position:CSToastPositionCenter];
        } else {
            NSInteger totalCount = weakSelf.dataSource.datas.count;
            if (totalCount == 0) {
                weakSelf.pageIndex = 0;
                weakSelf.totalPageCount = 0;
                weakSelf.currentOffset = 0;
            } else {
                weakSelf.totalPageCount = (totalCount%itemCountPerPage == 0) ? totalCount/itemCountPerPage: totalCount/itemCountPerPage + 1;
                if (weakSelf.pageIndex > weakSelf.totalPageCount - 1) {
                    weakSelf.pageIndex = weakSelf.totalPageCount - 1;
                }
                weakSelf.currentOffset = weakSelf.dataSource.datas.count;
            }
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
    if (targetPage*itemCountPerPage + itemCountPerPage > _dataSource.datas.count) { //需要加载新数据
        [self loadNextData];
    } else {
        [self refreshPage];
        [_collectionView reloadData];
    }
    _lastBtn.hidden = (_pageIndex == 0);
}

- (void)lastPageAction:(id)sender {
    if (_pageIndex == 0) {
        return;
    }
    _pageIndex--;
    [self refreshPage];
    [_collectionView reloadData];
    _lastBtn.hidden = (_pageIndex == 0);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger count = 0;
    if (_pageIndex == _totalPageCount - 1) {
        count = _dataSource.datas.count - _pageIndex * self.itemCountPerPage;
    } else if (_pageIndex < _totalPageCount - 1) {
        count = self.itemCountPerPage;
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NIMTeamCardHeaderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellReuseId forIndexPath:indexPath];
    cell.delegate = self;
    NSInteger index = _pageIndex * self.itemCountPerPage + indexPath.row;
    id<NIMKitCardHeaderData> data = _dataSource.datas[index];
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

#pragma mark - NIMTeamCardHeaderCellDelegate
- (void)cellDidSelected:(NIMTeamCardHeaderCell*)cell{
    NSIndexPath *indexpath = [self.collectionView indexPathForCell:cell];
    NSInteger index = _pageIndex * self.itemCountPerPage + indexpath.row;
    NIMTeamCardMemberItem *member = _dataSource.datas[index];
    NIMTeamMemberCardViewController *vc = [[NIMTeamMemberCardViewController alloc] initWithMember:member
                                                                                       dataSource:_dataSource];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TeamMemberCardActionDelegate
- (void)onTeamMemberKicked:(NIMTeamCardMemberItem *)member {
    [_dataSource.datas removeObject:member];
    [_collectionView reloadData];
}

- (void)onTeamMemberInfoChaneged:(NIMTeamCardMemberItem *)member {
    [_collectionView reloadData];
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
        [_collectionView registerClass:[NIMTeamCardHeaderCell class] forCellWithReuseIdentifier:CollectionCellReuseId];
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
