//
//  NTESUserInfoSettingViewController.m
//  NIM
//
//  Created by chris on 15/9/17.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESUserInfoSettingViewController.h"
#import "NIMCommonTableData.h"
#import "NIMCommonTableDelegate.h"
#import "NTESNickNameSettingViewController.h"
#import "NTESGenderSettingViewController.h"
#import "NTESBirthSettingViewController.h"
#import "NTESMobileSettingViewController.h"
#import "NTESEmailSettingViewController.h"
#import "NTESSignSettingViewController.h"
#import "NTESUserUtil.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"
#import "UIActionSheet+NTESBlock.h"
#import "UIImage+NTES.h"
#import "NTESFileLocationHelper.h"
#import "SDWebImageManager.h"
#import "NTESRedPacketManager.h"

@interface NTESUserInfoSettingViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate,NIMUserManagerDelegate>

@property (nonatomic,strong) NIMCommonTableDelegate *delegator;

@property (nonatomic,copy)   NSArray *data;

@end

@implementation NTESUserInfoSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"个人信息";
    [self buildData];
    __weak typeof(self) wself = self;
    self.delegator = [[NIMCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;
    
    [[NIMSDK sharedSDK].userManager addDelegate:self];
}

- (void)dealloc{
    [[NIMSDK sharedSDK].userManager removeDelegate:self];
}

- (void)buildData{
    NIMUser *me = [[NIMSDK sharedSDK].userManager userInfo:[[NIMSDK sharedSDK].loginManager currentAccount]];
    NSArray *data = @[
                      @{
                          HeaderTitle:@"",
                          RowContent :@[
                                  @{
                                      ExtraInfo     : me.userId ? me.userId : [NSNull null],
                                      CellClass     : @"NTESSettingPortraitCell",
                                      RowHeight     : @(100),
                                      CellAction    : @"onTouchPortrait:",
                                      ShowAccessory : @(YES)
                                      },
                                  ],
                          FooterTitle:@""
                          },
                      @{
                          HeaderTitle:@"",
                          RowContent :@[
                                  @{
                                      Title      : @"昵称",
                                      DetailTitle: me.userInfo.nickName.length ? me.userInfo.nickName : @"未设置",
                                      CellAction : @"onTouchNickSetting:",
                                      RowHeight     : @(50),
                                      ShowAccessory : @(YES),
                                      },
                                  @{
                                      Title      : @"性别",
                                      DetailTitle: [NTESUserUtil genderString:me.userInfo.gender],
                                      CellAction : @"onTouchGenderSetting:",
                                      RowHeight     : @(50),
                                      ShowAccessory : @(YES)
                                      },
                                  @{
                                      Title       : @"生日",
                                      DetailTitle : me.userInfo.birth.length ? me.userInfo.birth : @"未设置",
                                      CellAction  : @"onTouchBirthSetting:",
                                      RowHeight     : @(50),
                                      ShowAccessory : @(YES)
                                      },
                                  @{
                                      Title      :@"手机",
                                      DetailTitle:me.userInfo.mobile.length ? me.userInfo.mobile : @"未设置",
                                      CellAction :@"onTouchTelSetting:",
                                      RowHeight     : @(50),
                                      ShowAccessory : @(YES)
                                      },
                                  @{
                                      Title      :@"邮箱",
                                      DetailTitle:me.userInfo.email.length ? me.userInfo.email : @"未设置",
                                      CellAction :@"onTouchEmailSetting:",
                                      RowHeight     : @(50),
                                      ShowAccessory : @(YES)
                                      },
                                  @{
                                      Title      :@"签名",
                                      DetailTitle:me.userInfo.sign.length ? me.userInfo.sign : @"未设置",
                                      CellAction :@"onTouchSignSetting:",
                                      RowHeight     : @(50),
                                      ShowAccessory : @(YES)
                                      },
                                  ],
                          FooterTitle:@""
                          },
                      ];
    self.data = [NIMCommonTableSection sectionsWithData:data];
}


- (void)refresh{
    [self buildData];
    [self.tableView reloadData];
}

- (void)onTouchPortrait:(id)sender{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"设置头像" delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"从相册", nil];
        [sheet showInView:self.view completionHandler:^(NSInteger index) {
            switch (index) {
                case 0:
                    [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
                    break;
                case 1:
                    [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
                    break;
                default:
                    break;
            }
        }];
    }else{
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"设置头像" delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"从相册", nil];
        [sheet showInView:self.view completionHandler:^(NSInteger index) {
            switch (index) {
                case 0:
                    [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
                    break;
                default:
                    break;
            }
        }];
    }
}

- (void)showImagePicker:(UIImagePickerControllerSourceType)type{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate      = self;
    picker.sourceType    = type;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)onTouchNickSetting:(id)sender{
    NTESNickNameSettingViewController *vc = [[NTESNickNameSettingViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTouchGenderSetting:(id)sender{
    NTESGenderSettingViewController *vc = [[NTESGenderSettingViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTouchBirthSetting:(id)sender{
    NTESBirthSettingViewController *vc = [[NTESBirthSettingViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTouchTelSetting:(id)sender{
    NTESMobileSettingViewController *vc = [[NTESMobileSettingViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTouchEmailSetting:(id)sender{
    NTESEmailSettingViewController *vc = [[NTESEmailSettingViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTouchSignSetting:(id)sender{
    NTESSignSettingViewController *vc = [[NTESSignSettingViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        [self uploadImage:image];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - NIMUserManagerDelagate
- (void)onUserInfoChanged:(NIMUser *)user
{
    if ([user.userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
        [self refresh];
    }
}


#pragma mark - Private
- (void)uploadImage:(UIImage *)image{
    UIImage *imageForAvatarUpload = [image imageForAvatarUpload];
    NSString *fileName = [NTESFileLocationHelper genFilenameWithExt:@"jpg"];
    NSString *filePath = [[NTESFileLocationHelper getAppDocumentPath] stringByAppendingPathComponent:fileName];
    NSData *data = UIImageJPEGRepresentation(imageForAvatarUpload, 1.0);
    BOOL success = data && [data writeToFile:filePath atomically:YES];
    __weak typeof(self) wself = self;
    if (success) {
        [SVProgressHUD show];
        [[NIMSDK sharedSDK].resourceManager upload:filePath progress:nil completion:^(NSString *urlString, NSError *error) {
            [SVProgressHUD dismiss];
            if (!error && wself) {
                [[NIMSDK sharedSDK].userManager updateMyUserInfo:@{@(NIMUserInfoUpdateTagAvatar):urlString} completion:^(NSError *error) {
                    if (!error) {
                        [[NTESRedPacketManager sharedManager] updateUserInfo];
                        [[SDWebImageManager sharedManager] saveImageToCache:imageForAvatarUpload forURL:[NSURL URLWithString:urlString]];
                        [wself refresh];
                    }else{
                        [wself.view makeToast:@"设置头像失败，请重试"
                                     duration:2
                                     position:CSToastPositionCenter];
                    }
                }];
            }else{
                [wself.view makeToast:@"图片上传失败，请重试"
                             duration:2
                             position:CSToastPositionCenter];
            }
        }];
    }else{
        [self.view makeToast:@"图片保存失败，请重试"
                    duration:2
                    position:CSToastPositionCenter];
    }
}

#pragma mark - 旋转处理 (iOS7)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

@end
