//
//  NTESCreateTeamAnnouncement.m
//  NIM
//
//  Created by Xuhui on 15/3/31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMCreateTeamAnnouncement.h"
#import "UIView+NIM.h"
#import "NIMGlobalMacro.h"
#import "NIMKitKeyboardInfo.h"

@interface NIMCreateTeamAnnouncement () <UITextFieldDelegate, UITextViewDelegate>
@property (strong, nonatomic) UITextField *titleTextField;
@property (strong, nonatomic) UITextView *contentTextView;

@property (nonatomic,strong) UIScrollView *scrollView;

@end

@implementation NIMCreateTeamAnnouncement

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"新建群公告";
    self.view.backgroundColor = NIMKit_UIColorFromRGB(0xe4e7ec);
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 42, self.view.nim_width, 51)];
    titleView.backgroundColor = [UIColor whiteColor];
    titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.scrollView addSubview:titleView];
    
    CGFloat padding = 20.f;
    CGFloat contentWidth = self.view.nim_width - padding;
    self.titleTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 11, contentWidth, 30)];
    self.titleTextField.placeholder = @"标题";
    self.titleTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.titleTextField.font = [UIFont systemFontOfSize:17.f];
    self.titleTextField.textColor = [UIColor grayColor];
    self.titleTextField.text  = self.defaultTitle;
    self.titleTextField.delegate = self;
    [titleView addSubview:self.titleTextField];
    
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 134, self.view.nim_width, 140)];
    contentView.backgroundColor = [UIColor whiteColor];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.scrollView addSubview:contentView];
    
    self.contentTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, 17, contentWidth, 106)];
    self.contentTextView.textColor = [UIColor blackColor];
    self.contentTextView.font = [UIFont systemFontOfSize:17.f];
    self.contentTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentTextView.delegate = self;
    self.contentTextView.text = self.defaultContent;

    [contentView addSubview:self.contentTextView];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(onSave:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:NIMKitKeyboardWillChangeFrameNotification object:nil];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)keyboardWillChangeFrame:(NSNotification*)notification{
    NSDictionary* userInfo = [notification userInfo];
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    CGFloat keyBordOriginY = keyboardFrame.origin.y;
    BOOL iOS7 = ([[[UIDevice currentDevice] systemVersion] doubleValue] < 8.0);
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    if (iOS7 && (orientation == UIDeviceOrientationLandscapeLeft
                 || orientation == UIDeviceOrientationLandscapeRight)) {
        keyBordOriginY = keyboardFrame.origin.x + keyboardFrame.size.width;
    }
    self.scrollView.nim_height = keyBordOriginY - self.navigationController.navigationBar.nim_bottom;
    self.scrollView.nim_width  = self.view.nim_width;
    self.scrollView.contentSize = CGSizeMake(self.view.nim_width, self.contentTextView.superview.nim_bottom);
    self.scrollView.nim_top = 0;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.titleTextField endEditing:YES];
    [self.contentTextView endEditing:YES];
}

- (void)onSave:(id)sender {
    [self.titleTextField endEditing:YES];
    [self.contentTextView endEditing:YES];
    NSString *title = [self.titleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.navigationController popViewControllerAnimated:YES];
    if([self.delegate respondsToSelector:@selector(createTeamAnnouncementCompleteWithTitle:content:)]) {
        [self.delegate createTeamAnnouncementCompleteWithTitle:title content:content];
    }
}


- (BOOL)shouldAutorotate{
    return NO;
}

#pragma mark - 旋转处理 (iOS8 or above)
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.view endEditing:YES];
}


@end
