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

#define CollectionCellReuseId @"cell"
#define CollectionItemWidth  55
#define CollectionItemHeight 80
#define CollectionEdgeInsetLeftRight 20

#define CollectionEdgeInsetTopFirstLine 25
#define CollectionEdgeInsetTop 15

@interface NIMTeamMemberListViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,NIMTeamCardHeaderCellDelegate, NIMTeamMemberCardActionDelegate>

@property (nonatomic,strong) NIMTeam *team;

@property (nonatomic,strong) UICollectionView *collectionView;

@property (nonatomic,copy)   NSMutableArray *data;

@property (nonatomic,strong) NIMTeamMember *myTeamCard;

@end

@implementation NIMTeamMemberListViewController

- (instancetype)initTeam:(NIMTeam*)team
                 members:(NSArray*)members{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _team = team;
        _data = [[NSMutableArray alloc] init];
        for (NIMTeamMember *member in members) {
            NIMTeamCardMemberItem *item = [[NIMTeamCardMemberItem alloc] initWithMember:member];
            [_data addObject:item];
            if([member.userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
                _myTeamCard = member;
            }
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"群成员";
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    flowLayout.minimumInteritemSpacing = CollectionEdgeInsetLeftRight;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.collectionView.backgroundColor = [UIColor colorWithRed:236.0/255.0 green:241.0/255.0 blue:245.0/255.0 alpha:1];
    self.collectionView.delegate   = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[NIMTeamCardHeaderCell class] forCellWithReuseIdentifier:CollectionCellReuseId];
    [self.view addSubview:self.collectionView];
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, CollectionEdgeInsetLeftRight, self.collectionView.contentInset.bottom, CollectionEdgeInsetLeftRight);
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger lastTotal = self.collectionItemNumber * section;
    NSInteger remain    = self.data.count - lastTotal;
    return remain < self.collectionItemNumber ? remain:self.collectionItemNumber;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    NSInteger sections = self.data.count / self.collectionItemNumber;
    return self.data.count % self.collectionItemNumber ? sections + 1 : sections;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NIMTeamCardHeaderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellReuseId forIndexPath:indexPath];
    cell.delegate = self;
    id<NIMKitCardHeaderData> data = [self dataAtIndexPath:indexPath];
    [cell refreshData:data];
    return cell;
}

- (id<NIMKitCardHeaderData>)dataAtIndexPath:(NSIndexPath*)indexpath{
    NSInteger index = indexpath.section * self.collectionItemNumber;
    index += indexpath.row;
    return self.data[index];
}

- (NSIndexPath *)indexPathForData:(NIMTeamCardMemberItem *)data{
    NSInteger index   = [self.data indexOfObject:data];
    NSInteger section = index / self.collectionItemNumber;
    NSInteger row     = index % self.collectionItemNumber;
    return [NSIndexPath indexPathForRow:row inSection:section];
    
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
    NSInteger index = indexpath.section * self.collectionItemNumber;
    index += indexpath.row;
    NIMTeamMemberCardViewController *vc = [[NIMTeamMemberCardViewController alloc] init];
    vc.delegate = self;
    
    NIMTeamCardMemberItem *member = self.data[index];
    NIMTeamCardMemberItem *viewer = [[NIMTeamCardMemberItem alloc] initWithMember:self.myTeamCard];
    vc.member = member;
    vc.viewer = viewer;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TeamMemberCardActionDelegate

- (void)onTeamMemberKicked:(NIMTeamCardMemberItem *)member {
    [self.data removeObject:member];
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

- (NSInteger)collectionItemNumber{
    CGFloat minSpace = 20.f; //防止计算到最后出现左右贴边的情况
    return (int)((self.collectionView.frame.size.width - minSpace)/ (CollectionItemWidth + CollectionEdgeInsetLeftRight));
}



@end
