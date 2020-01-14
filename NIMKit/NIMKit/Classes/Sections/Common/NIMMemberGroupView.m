//
//  NIMMemberGroupView.m
//  NIMKit
//
//  Created by chris on 15/10/15.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import "NIMMemberGroupView.h"
#import "NIMCardHeaderCell.h"
#import "UIView+NIM.h"
#import "NIMCardOperationItem.h"
#import "NIMTeamCardMemberItem.h"

#define CollectionItemWidth  58
#define CollectionItemHeight 80
#define CollectionMinLeft    20 //防止计算后有左右贴边的情况
#define CollectionEdgeInsetTopFirstLine 25
#define CollectionEdgeInsetTop          15
#define CollectionCellReuseId           @"collectionCell"

#pragma mark - NIMMemebrGroupData

@implementation NIMMemebrGroupData

- (instancetype)init {
    if (self = [super init]) {
        _opera = CardHeaderOpeatorNone;
    }
    return self;
}

- (BOOL)isMyUserId {
    return [_userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount];
}

@end

#pragma mark - NIMMemberGroupView

@interface NIMMemberGroupView()<UICollectionViewDataSource,UICollectionViewDelegate,NIMCardHeaderCellDelegate>

@property (nonatomic,strong)    NSMutableArray *data;

@property (nonatomic,strong)    NSMutableDictionary *operatorTitle;

@end

@implementation NIMMemberGroupView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        [self addSubview:self.collectionView];
    }
    return self;
}

- (void)refreshDatas:(NSArray <NIMMemebrGroupData *> *)datas
           operators:(NIMKitCardHeaderOpeator)operators{
    _showAddOperator    = (operators & CardHeaderOpeatorAdd) != 0;
    _showRemoveOperator = (operators & CardHeaderOpeatorRemove) != 0;
    
    //normal item
    self.data = [[NSMutableArray alloc] initWithArray:datas];
    
    //add item
    if (self.showAddOperator) {
        NIMMemebrGroupData *groupData = [[NIMMemebrGroupData alloc] init];
        groupData.opera = CardHeaderOpeatorAdd;
        [self.data addObject:groupData];
    }
    
    //remove item
    if (self.showRemoveOperator) {
        NIMMemebrGroupData *groupData = [[NIMMemebrGroupData alloc] init];
        groupData.opera = CardHeaderOpeatorRemove;
        [self.data addObject:groupData];
    }
    [self.collectionView reloadData];
}

- (void)setTitle:(NSString *)title forOperator:(NIMKitCardHeaderOpeator)opera{
    if (!self.operatorTitle) {
        self.operatorTitle = [[NSMutableDictionary alloc] init];
    }
    self.operatorTitle[@(opera)] = title;
}

- (CGSize)sizeThatFits:(CGSize)size{
    CGFloat width = size.width;
    NSInteger sectionNumber = [self numberOfSections:width];
    CGFloat height = CollectionItemHeight * sectionNumber + CollectionEdgeInsetTop * (sectionNumber-1) + CollectionEdgeInsetTopFirstLine * 2;
    return CGSizeMake(width, height);
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.collectionView.contentInset = self.sectionInsets;
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
    NIMCardHeaderCell *cell;
    NIMMemebrGroupData *data = [self dataAtIndexPath:indexPath];
    if (data.opera == CardHeaderOpeatorAdd || data.opera == CardHeaderOpeatorRemove) {
        cell = [self buildOperatorCell:data.opera indexPath:indexPath];
    }else{
        cell = [self buildUserCell:data indexPath:indexPath];
    }
    cell.delegate = self;
    return cell;
}

- (NIMMemebrGroupData *)dataAtIndexPath:(NSIndexPath*)indexpath{
    NSInteger index = indexpath.section * self.collectionItemNumber;
    index += indexpath.row;
    return self.data[index];
}

#pragma mark - NIMCardHeaderCellDelegate
- (void)cellDidSelected:(NIMCardHeaderCell *)cell{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NIMMemebrGroupData *groupData = [self dataAtIndexPath:indexPath];
    if (groupData.opera == CardHeaderOpeatorNone && [self.delegate respondsToSelector:@selector(didSelectMemberId:)]) {
        [self.delegate didSelectMemberId:groupData.userId];
    }else if ([self.delegate respondsToSelector:@selector(didSelectOperator:)]){
        [self.delegate didSelectOperator:groupData.opera];
    }
}

- (void)cellShouldBeRemoved:(NIMCardHeaderCell*)cell{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NIMMemebrGroupData *groupData = [self dataAtIndexPath:indexPath];
    if (groupData.opera == CardHeaderOpeatorNone && [self.delegate respondsToSelector:@selector(didSelectRemoveButtonWithMemberId:)]) {
        [self.delegate didSelectRemoveButtonWithMemberId:groupData.userId];
    }
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

#pragma mark - Getter & Setter
- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = self.collectionEdgeInsetLeftRight;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor colorWithRed:236.0/255.0 green:241.0/255.0 blue:245.0/255.0 alpha:1];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.delegate   = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[NIMCardHeaderCell class] forCellWithReuseIdentifier:CollectionCellReuseId];
    }
    return _collectionView;
}

- (CGFloat)collectionEdgeInsetLeftRight{
    return CollectionMinLeft;
}

#pragma mark - Private
- (NIMCardHeaderCell *)buildUserCell:(NIMMemebrGroupData *)data indexPath:(NSIndexPath *)indexPath{
    NIMCardHeaderCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellReuseId forIndexPath:indexPath];
    NIMCardMemberItem *item = [[NIMCardMemberItem alloc] init];
    item.userId = data.userId;

    [cell refreshData:item];
    cell.removeBtn.hidden = (self.enableRemove ? item.isMyUserId : YES);
    return cell;
}

- (NIMCardHeaderCell *)buildOperatorCell:(NIMKitCardHeaderOpeator)operator indexPath:(NSIndexPath *)indexPath{
    NIMCardHeaderCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellReuseId forIndexPath:indexPath];
    NIMCardOperationItem *item = [[NIMCardOperationItem alloc] initWithOperation:operator];
    if (self.operatorTitle[@(operator)]) {
        item.title = self.operatorTitle[@(operator)];
    }
    [cell refreshData:item];
    cell.removeBtn.hidden = YES;
    return cell;
}

- (UIEdgeInsets)sectionInsets {
    CGFloat left = (self.collectionView.nim_width - ((CollectionItemWidth + self.collectionEdgeInsetLeftRight)) * self.collectionItemNumber - self.collectionEdgeInsetLeftRight) * 0.5;
    left = left > CollectionMinLeft ? left : CollectionMinLeft;
    return UIEdgeInsetsMake(self.collectionView.contentInset.top, left, self.collectionView.contentInset.bottom, left);
}

- (NSInteger)collectionItemNumber{
    return [self collectionItemNumber:self.collectionView.nim_width];
}

- (NSInteger)collectionItemNumber:(CGFloat)width{
    CGFloat minSpace = CollectionMinLeft; //防止计算到最后出现左右贴边的情况
    return (int)((width - minSpace)/ (CollectionItemWidth + self.collectionEdgeInsetLeftRight));
}

- (NSInteger)numberOfSections:(CGFloat)width{
    NSInteger collectionNumber = [self collectionItemNumber:width];
    NSInteger sections = self.data.count / collectionNumber;
    return self.data.count % collectionNumber ? sections + 1 : sections;
}

@end
