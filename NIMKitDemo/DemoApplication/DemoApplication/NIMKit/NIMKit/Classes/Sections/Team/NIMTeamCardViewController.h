//
//  NTESTeamCardViewController.h
//  NIM
//
//  Created by chris on 15/3/4.
//  Copyright (c) 2015年 Netease. All rights reserved.
//
#import "NIMCardDataSourceProtocol.h"
#import "NIMTeamCardHeaderCell.h"

@interface NIMTeamCardViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UITableViewDataSource,UITableViewDelegate,TeamCardHeaderCellDelegate>

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,assign) NIMKitCardHeaderOpeator currentOpera;

- (void)reloadMembers:(NSArray*)members;

- (void)addMembers:(NSArray*)members;

- (void)removeMembers:(NSArray*)members;

@end

@interface NIMTeamCardViewController (Override)

- (NSString*)title;

- (NSArray*)buildBodyData;

@end


@interface NIMTeamCardViewController (Refresh)

- (void)refreshTitle;
- (void)refreshWithMembers:(NSArray*)members;
- (void)refreshTableHeader;
- (void)refreshTableBody;

@end
