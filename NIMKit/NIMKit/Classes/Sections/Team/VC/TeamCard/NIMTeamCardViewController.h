//
//  NIMTeamCardViewController.h
//  NIMKit
//
//  Created by Netease on 2019/6/11.
//  Copyright © 2019 NetEase. All rights reserved.
//  Basic class for team card

#import <UIKit/UIKit.h>
#import "NIMTeamCardRowItem.h"
#import "NIMTeamMemberListCell.h"
#import "NIMTeamSwitchTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, NIMTeamCardSwithCellType){
    NIMTeamCardSwithCellTypeTop = 1,
    NIMTeamCardSwithCellTypeNotify,
};

@protocol NIMTeamCardViewControllerDelegate <NSObject>

- (void)NIMTeamCardVCDidSetTop:(BOOL)on;

@end

typedef void(^NIMTeamCardPickerHandle)(UIImage *image);

@interface NIMTeamCardViewController : UIViewController

@property (nonatomic,weak) id <NIMTeamCardViewControllerDelegate> delegate;

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) NSArray <NSArray <NIMTeamCardRowItem *> *> *datas;

- (void)showImagePicker:(UIImagePickerControllerSourceType)type
             completion:(NIMTeamCardPickerHandle)completion;

- (UIAlertController *)makeAlertSheetWithTitle:(NSString *)title
                                       actions:(NSArray <UIAlertAction *>*)actions;

- (UIAlertAction *)makeCancelAction;

- (void)showAlert:(UIAlertController *)alert;

- (void)showToastMsg:(NSString *)msg;

- (NSMutableArray *)itemsWithListDic:(NSArray <NSDictionary *> *)listDic
                         selectValue:(NSInteger)selectValue;

/* --- need reload by child class ---- */

- (UIView *)didGetHeaderView;

- (void)didBuildTeamMemberCell:(NIMTeamMemberListCell *)cell;

@end


@interface NIMTeamCardViewControllerOption : NSObject

@property (nonatomic, assign) BOOL isTop;

@end

NS_ASSUME_NONNULL_END
