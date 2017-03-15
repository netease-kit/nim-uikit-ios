//
//  NTESLoginViewController.m
//  NIMDemo
//
//  Created by ght on 15-1-26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESLoginViewController.h"
#import "NTESSessionViewController.h"
#import "NTESSessionUtil.h"
#import "NTESMainTabController.h"
#import "UIView+Toast.h"
#import "SVProgressHUD.h"
#import "NTESService.h"
#import "UIView+NTES.h"
#import "NSString+NTES.h"
#import "NTESLoginManager.h"
#import "NTESNotificationCenter.h"
#import "UIActionSheet+NTESBlock.h"
#import "NTESLogManager.h"
#import "NTESRegisterViewController.h"

@interface NTESLoginViewController ()<NTESRegisterViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIImageView *logo;
@end

@implementation NTESLoginViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];

    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


NTES_USE_CLEAR_BAR
- (void)viewDidLoad {
    [super viewDidLoad];
    self.usernameTextField.tintColor = [UIColor whiteColor];
    [self.usernameTextField setValue:UIColorFromRGBA(0xffffff, .6f) forKeyPath:@"_placeholderLabel.textColor"];
    self.passwordTextField.tintColor = [UIColor whiteColor];
    [self.passwordTextField setValue:UIColorFromRGBA(0xffffff, .6f) forKeyPath:@"_placeholderLabel.textColor"];
    UIButton *pwdClearButton = [self.passwordTextField valueForKey:@"_clearButton"];
    [pwdClearButton setImage:[UIImage imageNamed:@"login_icon_clear"] forState:UIControlStateNormal];
    UIButton *userNameClearButton = [self.usernameTextField valueForKey:@"_clearButton"];
    [userNameClearButton setImage:[UIImage imageNamed:@"login_icon_clear"] forState:UIControlStateNormal];
    
    [_registerButton setHidden:![[NIMSDK sharedSDK] isUsingDemoAppKey]];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self configNav];
    [self configStatusBar];
}



- (void)configNav{
    self.navigationItem.title = @"";
    UIButton *loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [loginBtn setTitle:@"完成" forState:UIControlStateNormal];
    loginBtn.titleLabel.font = [UIFont systemFontOfSize:15.f];
    [loginBtn setTitleColor:UIColorFromRGB(0x2294ff) forState:UIControlStateNormal];
    
    [loginBtn setBackgroundImage:[UIImage imageNamed:@"login_btn_done_normal"] forState:UIControlStateNormal];
    [loginBtn setBackgroundImage:[UIImage imageNamed:@"login_btn_done_pressed"] forState:UIControlStateHighlighted];
    [loginBtn addTarget:self action:@selector(onTouchLogin:) forControlEvents:UIControlEventTouchUpInside];
    UILongPressGestureRecognizer *longPressOnLoginBtn = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(prepareShowLog:)];
    [loginBtn addGestureRecognizer:longPressOnLoginBtn];
    
    [loginBtn sizeToFit];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loginBtn];
    
    NSShadow *shadow = [[NSShadow alloc]init];
    shadow.shadowOffset = CGSizeMake(0, 0);
    self.navigationController.navigationBar.titleTextAttributes =@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17],
                                                                   NSForegroundColorAttributeName:[UIColor whiteColor]};
}

- (void)configStatusBar{
    UIStatusBarStyle style = [self preferredStatusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:style
                                                animated:NO];
}



- (void)doLogin
{
    [_usernameTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
    
    NSString *username = [_usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *password = _passwordTextField.text;
    [SVProgressHUD show];
    
    NSString *loginAccount = username;
    NSString *loginToken   = [password tokenByPassword];
    
    //NIM SDK 只提供消息通道，并不依赖用户业务逻辑，开发者需要为每个APP用户指定一个NIM帐号，NIM只负责验证NIM的帐号即可(在服务器端集成)
    //用户APP的帐号体系和 NIM SDK 并没有直接关系
    //DEMO中使用 username 作为 NIM 的account ，md5(password) 作为 token
    //开发者需要根据自己的实际情况配置自身用户系统和 NIM 用户系统的关系
    
    
    [[[NIMSDK sharedSDK] loginManager] login:loginAccount
                                       token:loginToken
                                  completion:^(NSError *error) {
                                      [SVProgressHUD dismiss];
                                      if (error == nil)
                                      {
                                          LoginData *sdkData = [[LoginData alloc] init];
                                          sdkData.account   = loginAccount;
                                          sdkData.token     = loginToken;
                                          [[NTESLoginManager sharedManager] setCurrentLoginData:sdkData];
                                          
                                          [[NTESServiceManager sharedManager] start];
                                          NTESMainTabController * mainTab = [[NTESMainTabController alloc] initWithNibName:nil bundle:nil];
                                          [UIApplication sharedApplication].keyWindow.rootViewController = mainTab;
                                      }
                                      else
                                      {
                                          NSString *toast = [NSString stringWithFormat:@"登录失败 code: %zd",error.code];
                                          [self.view makeToast:toast duration:2.0 position:CSToastPositionCenter];
                                      }
                                  }];


}

- (IBAction)onTouchLogin:(id)sender {
    [self doLogin];
}

- (void)prepareShowLog:(UILongPressGestureRecognizer *)gesuture{
    if (gesuture.state == UIGestureRecognizerStateBegan) {
        __weak typeof(self) wself = self;
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"查看SDK日志",@"查看Demo日志", nil];
        [actionSheet showInView:self.view completionHandler:^(NSInteger index) {
            switch (index) {
                case 0:
                    [wself showSDKLog];
                    break;
                case 1:
                    [wself showDemoLog];
                    break;
                default:
                    break;
            }
        }];
    }
}




#pragma mark - Notification
- (void)keyboardWillShow:(NSNotification*)notification{
    NSDictionary* userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    CGFloat bottomSpacing = 10.f;
    UIView *inputView = self.passwordTextField.superview;
    if (inputView.bottom + bottomSpacing > CGRectGetMinY(keyboardFrame)) {
        CGFloat delta = inputView.bottom + bottomSpacing - CGRectGetMinY(keyboardFrame);
        inputView.bottom -= delta;
    }
    if (self.logo.bottom > self.navigationController.navigationBar.bottom) {
        self.logo.bottom = self.navigationController.navigationBar.bottom;
        self.logo.alpha  = 0;
        self.navigationItem.title = @"登录";
    }
    [UIView commitAnimations];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        [self doLogin];
        return NO;
    }
    return YES;
}

- (void)textFieldDidChange:(NSNotification*)notification{
    if ([self.usernameTextField.text length] && [self.passwordTextField.text length])
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else{
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if ([self.usernameTextField.text length] && [self.passwordTextField.text length])
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else{
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

#pragma mark - NTESRegisterViewControllerDelegate
- (void)registDidComplete:(NSString *)account password:(NSString *)password{
    if (account.length) {
        self.usernameTextField.text = account;
        self.passwordTextField.text = password;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

#pragma mark - Private
- (void)showSDKLog{
    UIViewController *vc = [[NTESLogManager sharedManager] sdkLogViewController];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav
                       animated:YES
                     completion:nil];
}

- (void)showDemoLog{
    UIViewController *logViewController = [[NTESLogManager sharedManager] demoLogViewController];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:logViewController];
    [self presentViewController:nav
                       animated:YES
                     completion:nil];
}

- (IBAction)onTouchRegister:(id)sender
{
    NTESRegisterViewController *vc = [NTESRegisterViewController new];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [_usernameTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
