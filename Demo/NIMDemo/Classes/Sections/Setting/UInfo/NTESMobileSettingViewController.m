//
//  NTESTelSettingViewController.m
//  NIM
//
//  Created by chris on 15/9/17.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESMobileSettingViewController.h"
#import "NIMCommonTableDelegate.h"
#import "NIMCommonTableData.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"

@interface NTESMobileSettingViewController ()

@property (nonatomic,strong) NIMCommonTableDelegate *delegator;

@property (nonatomic,copy  ) NSArray                 *data;

@property (nonatomic,assign) NSInteger               inputLimit;

@property (nonatomic,copy)   NSString                *mobile;

@end

@implementation NTESMobileSettingViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _inputLimit = 13;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNav];
    NSString *userId = [[NIMSDK sharedSDK].loginManager currentAccount];
    self.mobile = [[NIMSDK sharedSDK].userManager userInfo:userId].userInfo.mobile;
    self.mobile = self.mobile?self.mobile : @"";
    __weak typeof(self) wself = self;
    [self buildData];
    self.delegator = [[NIMCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = UIColorFromRGB(0xe3e6ea);
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;
    [self.tableView reloadData];
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        for (UIView *subView in cell.subviews) {
            if ([subView isKindOfClass:[UITextField class]]) {
                [subView becomeFirstResponder];
                break;
            }
        }
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setUpNav{
    self.navigationItem.title = @"手机号码";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
}

- (void)onDone:(id)sender{
    [self.view endEditing:YES];
    if (self.mobile.length > self.inputLimit) {
        [self.view makeToast:@"手机号码过长" duration:2.0 position:CSToastPositionCenter];
        return;
    }
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].userManager updateMyUserInfo:@{@(NIMUserInfoUpdateTagMobile) : self.mobile} completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            UINavigationController *nav = wself.navigationController;
            [nav popViewControllerAnimated:YES];
            [nav.view makeToast:@"手机设置成功" duration:2.0 position:CSToastPositionCenter];
        }else{
            [wself.view makeToast:@"手机设置失败，请重试" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)buildData{
    NSArray *data = @[
                      @{
                          HeaderTitle:@"",
                          RowContent :@[
                                  @{
                                      ExtraInfo     : self.mobile,
                                      CellClass     : @"NTESTextSettingCell",
                                      RowHeight     : @(50),
                                      },
                                  ],
                          },
                      ];
    self.data = [NIMCommonTableSection sectionsWithData:data];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    // 如果是删除键
    if ([string length] == 0 && range.length > 0)
    {
        return YES;
    }
    NSString *genString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (self.inputLimit && genString.length > self.inputLimit) {
        return NO;
    }
    return YES;
}


- (void)onTextFieldChanged:(NSNotification *)notification{
    UITextField *textField = notification.object;
    self.mobile = textField.text;
}


#pragma mark - 旋转处理 (iOS7)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}



@end
