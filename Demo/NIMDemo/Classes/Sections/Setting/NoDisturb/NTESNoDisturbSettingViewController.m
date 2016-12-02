//
//  NTESNoDisturbSettingViewController.m
//  NIM
//
//  Created by chris on 15/7/7.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESNoDisturbSettingViewController.h"
#import "NIMCommonTableData.h"
#import "UIView+Toast.h"
#import "NIMCommonTableDelegate.h"
#import "NIMTimePickerView.h"
#import "UIView+Toast.h"

@interface NTESNoDisturbSettingViewController ()

@property (nonatomic,copy) NSArray *data;

@property (nonatomic,strong) NIMCommonTableDelegate *delegator;

@property (nonatomic,assign) BOOL isUpdate;

@end

@implementation NTESNoDisturbSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"免打扰设置";
    [self buildData];
    __weak typeof(self) wself = self;
    self.delegator = [[NIMCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;
}

- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (self.isUpdate && self.handler) {
        self.handler();
    }
}

- (void)buildData{
    NIMPushNotificationSetting *setting = [[NIMSDK sharedSDK].apnsManager currentSetting];
    BOOL enableNoDisturbing     = setting.noDisturbing;
    NSString *noDisturbingStart = [NSString stringWithFormat:@"%02zd:%02zd",setting.noDisturbingStartH,setting.noDisturbingStartM];
    NSString *noDisturbingEnd   = [NSString stringWithFormat:@"%02zd:%02zd",setting.noDisturbingEndH,setting.noDisturbingEndM];
    
    NSArray *data = @[
                      @{
                          HeaderTitle:@"",
                          RowContent :@[
                                  @{
                                      Title        : @"免打扰",
                                      CellClass    : @"NTESSettingSwitcherCell",
                                      CellAction   : @"onActionNoDisturbingSettingValueChange:",
                                      ExtraInfo    : @(enableNoDisturbing),
                                      ForbidSelect : @(YES)
                                      },
                                  @{
                                      Title       : @"从",
                                      DetailTitle : noDisturbingStart,
                                      CellClass   : @"NTESNoDisturbTimeCell",
                                      CellAction  : @"onActionSetNoDisturbingStart:",
                                      Disable     : @(!enableNoDisturbing),
                                      },
                                  @{
                                      Title      :@"至",
                                      DetailTitle:noDisturbingEnd,
                                      CellClass  :@"NTESNoDisturbTimeCell",
                                      CellAction :@"onActionSetNoDisturbingEnd:",
                                      Disable    :@(!enableNoDisturbing),
                                      },
                                  ],
                          FooterTitle:@"在设定的时间段内云信消息将不再提醒。"
                          },
                      ];
    self.data = [NIMCommonTableSection sectionsWithData:data];
}

- (void)refreshData{
    [self buildData];
    [self.tableView reloadData];
}


#pragma mark - Action
- (void)onActionNoDisturbingSettingValueChange:(id)sender {
    UISwitch *switcher = sender;
    NIMPushNotificationSetting *setting = [[NIMSDK sharedSDK].apnsManager currentSetting];
    setting.noDisturbing = switcher.on;
    [self updateAPNSSetting:setting];
}


- (void)onActionSetNoDisturbingStart:(id)sender{
    NIMTimePickerView *pickerView = [[NIMTimePickerView alloc] initWithFrame:self.view.bounds];
    NIMPushNotificationSetting *setting = [[NIMSDK sharedSDK].apnsManager currentSetting];
    [pickerView refreshWithHour:setting.noDisturbingStartH minute:setting.noDisturbingStartM];
    __weak typeof(self) wself = self;
    [pickerView showInView:self.view.window onCompletion:^(NSInteger hour, NSInteger minute) {
        NIMPushNotificationSetting *setting = [[NIMSDK sharedSDK].apnsManager currentSetting];
        if (hour == setting.noDisturbingEndH && minute == setting.noDisturbingEndM) {
            [wself.view makeToast:@"结束时间不能与开始时间一致" duration:2.0 position:CSToastPositionCenter];
            [wself refreshData];
        }else{
            setting.noDisturbingStartH = hour;
            setting.noDisturbingStartM = minute;
            [wself updateAPNSSetting:setting];
        }
    }];
}

- (void)onActionSetNoDisturbingEnd:(id)sender{
    NIMTimePickerView *pickerView = [[NIMTimePickerView alloc] initWithFrame:self.view.bounds];
    NIMPushNotificationSetting *setting = [[NIMSDK sharedSDK].apnsManager currentSetting];
    [pickerView refreshWithHour:setting.noDisturbingEndH minute:setting.noDisturbingEndM];
    __weak typeof(self) wself = self;
    [pickerView showInView:self.view.window onCompletion:^(NSInteger hour, NSInteger minute) {
        NIMPushNotificationSetting *setting = [[NIMSDK sharedSDK].apnsManager currentSetting];
        if (hour == setting.noDisturbingStartH && minute == setting.noDisturbingStartM) {
            [wself.view makeToast:@"结束时间不能与开始时间一致" duration:2.0 position:CSToastPositionCenter];
            [wself refreshData];
        }else{
            setting.noDisturbingEndH = hour;
            setting.noDisturbingEndM = minute;
            [wself updateAPNSSetting:setting];
        }

    }];
}



#pragma mark - Private

- (void)updateAPNSSetting:(NIMPushNotificationSetting *)setting{
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].apnsManager updateApnsSetting:setting completion:^(NSError *error) {
        wself.isUpdate = YES;
        if (error) {
            [wself.view makeToast:@"免打扰设置更新失败" duration:2.0 position:CSToastPositionCenter];
        }
        [wself refreshData];
    }];
}

#pragma mark - 旋转处理 (iOS7)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

@end
