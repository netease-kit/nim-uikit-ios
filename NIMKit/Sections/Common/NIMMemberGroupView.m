//
//  NIMMemberGroupView.m
//  NIMKit
//
//  Created by chris on 15/10/15.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import "NIMMemberGroupView.h"
#import "NIMTeamCardHeaderCell.h"
#import "UIView+NIM.h"
#import "NIMTeamCardOperationItem.h"
#import "NIMCardMemberItem.h"

#define CollectionItemWidth  58
#define CollectionItemHeight 80
#define CollectionMinLeft    20 //防止计算后有左右贴边的情况
#define CollectionEdgeInsetTopFirstLine 25
#define CollectionEdgeInsetTop          15
#define CollectionCellReuseId           @"collectionCell"

#pragma mark - NIMMemebrGroupData

@interface NIMMemebrGroupData : NSObject

@property (nonatomic,strong)   id data;

@property (nonatomic,assign) NIMKitCardHeaderOpeator operator;

@end

@implementation NIMMemebrGroupData

@end


#pragma mark - NIMMemberGroupView

@interface NIMMemberGroupView()<UICollectionViewDataSource,UICollectionViewDelegate,NIMTeamCardHeaderCellDelegate>

@property (nonatomic,strong)    NSMutableArray *uids;

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

- (void)refreshUids:(NSArray *)uids operators:(NIMKitCardHeaderOpeator)operators{
    _uids = [uids mutableCopy];
    _showAddOperator    = (operators & CardHeaderOpeatorAdd) != 0;
    _showRemoveOperator = (operators & CardHeaderOpeatorRemove) != 0;
    [self makeData];
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
    NIMTeamCardHeaderCell *cell;
    NIMMemebrGroupData *data = [self dataAtIndexPath:indexPath];
    if (data.operator == CardHeaderOpeatorAdd || data.operator == CardHeaderOpeatorRemove) {
        cell = [self buildOperatorCell:data.operator indexPath:indexPath];
    }else{
        cell = [self buildUserCell:data.data indexPath:indexPath];
    }
    cell.delegate = self;
    return cell;
}

- (NIMMemebrGroupData *)dataAtIndexPath:(NSIndexPath*)indexpath{
    NSInteger index = indexpath.section * self.collectionItemNumber;
    index += indexpath.row;
    return self.data[index];
}

#pragma mark - NIMTeamCardHeaderCellDelegate
- (void)cellDidSelected:(NIMTeamCardHeaderCell *)cell{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NIMMemebrGroupData *groupData = [self dataAtIndexPath:indexPath];
    if (groupData.operator == CardHeaderOpeatorNone && [self.delegate respondsToSelector:@selector(didSelectMemberId:)]) {
        [self.delegate didSelectMemberId:groupData.data];
    }else if ([self.delegate respondsToSelector:@selector(didSelectOperator:)]){
        [self.delegate didSelectOperator:groupData.operator];
    }
}

- (void)cellShouldBeRemoved:(NIMTeamCardHeaderCell*)cell{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NIMMemebrGroupData *groupData = [self dataAtIndexPath:indexPath];
    if (groupData.operator == CardHeaderOpeatorNone && [self.delegate respondsToSelector:@selector(didSelectRemoveButtonWithMemberId:)]) {
        [self.delegate didSelectRemoveButtonWithMemberId:groupData.data];
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
        [_collectionView registerClass:[NIMTeamCardHeaderCell class] forCellWithReuseIdentifier:CollectionCellReuseId];
    }
    return _collectionView;
}

- (CGFloat)collectionEdgeInsetLeftRight{
    return CollectionMinLeft;
}

#pragma mark - Private

- (void)makeData{
    self.data = [[NSMutableArray alloc] init];
    for (NSString *uid in self.uids) {
        NIMMemebrGroupData *groupData = [[NIMMemebrGroupData alloc] init];
        groupData.operator = CardHeaderOpeatorNone;
        groupData.data = uid;
        [self.data addObject:groupData];
    }
    if (self.showAddOperator) {
        NIMMemebrGroupData *groupData = [[NIMMemebrGroupData alloc] init];
        groupData.operator = CardHeaderOpeatorAdd;
        [self.data addObject:groupData];
    }
    if (self.showRemoveOperator) {
        NIMMemebrGroupData *groupData = [[NIMMemebrGroupData alloc] init];
        groupData.operator = CardHeaderOpeatorRemove;
        [self.data addObject:groupData];
    }
}

- (NIMTeamCardHeaderCell *)buildUserCell:(NSString *)uid indexPath:(NSIndexPath *)indexPath{
    NIMTeamCardHeaderCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellReuseId forIndexPath:indexPath];
    NIMMemebrGroupData *data = [self dataAtIndexPath:indexPath];
    NIMUserCardMemberItem *item = [[NIMUserCardMemberItem alloc] initWithUserId:data.data];
    [cell refreshData:item];
    cell.removeBtn.hidden = !self.enableRemove;
    return cell;
}


- (NIMTeamCardHeaderCell *)buildOperatorCell:(NIMKitCardHeaderOpeator)operator indexPath:(NSIndexPath *)indexPath{
    NIMTeamCardHeaderCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:CollectionCellReuseId forIndexPath:indexPath];
    NIMTeamCardOperationItem *item = [[NIMTeamCardOperationItem alloc] initWithOperation:operator];
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
