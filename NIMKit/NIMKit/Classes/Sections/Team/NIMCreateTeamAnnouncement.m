//
//  NTESCreateTeamAnnouncement.m
//  NIM
//
//  Created by Xuhui on 15/3/31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMCreateTeamAnnouncement.h"
#import "UIView+NIM.h"

@interface NIMCreateTeamAnnouncement () <UITextFieldDelegate, UITextViewDelegate>
@property (strong, nonatomic) UITextField *titleTextField;
@property (strong, nonatomic) UITextView *contentTextView;

@end

@implementation NIMCreateTeamAnnouncement

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"新建群公告";
    self.view.backgroundColor = NIMKit_UIColorFromRGB(0xe4e7ec);
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 42, self.view.nim_width, 51)];
    titleView.backgroundColor = [UIColor whiteColor];
    titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:titleView];
    
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
    [self.view addSubview:contentView];
    
    self.contentTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, 17, contentWidth, 106)];
    self.contentTextView.textColor = [UIColor blackColor];
    self.contentTextView.font = [UIFont systemFontOfSize:17.f];
    self.contentTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentTextView.delegate = self;
    self.contentTextView.text = self.defaultContent;

    [contentView addSubview:self.contentTextView];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(onSave:)];
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
    if(title.length <= 0 || content.length  <= 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"标题或者内容不能为空" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
    if([self.delegate respondsToSelector:@selector(createTeamAnnouncementCompleteWithTitle:content:)]) {
        [self.delegate createTeamAnnouncementCompleteWithTitle:title content:content];
    }
}


@end
