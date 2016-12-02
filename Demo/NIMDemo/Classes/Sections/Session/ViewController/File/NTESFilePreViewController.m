//
//  NTESFilePreViewController.m
//  NIM
//
//  Created by chris on 15/4/21.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESFilePreViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
@interface NTESFilePreViewController ()

@property(nonatomic,strong)NIMFileObject *fileObject;

@property(nonatomic,strong)UIDocumentInteractionController *interactionController;

@property(nonatomic,assign)BOOL isDownLoading;

@end

@implementation NTESFilePreViewController

- (instancetype)initWithFileObject:(NIMFileObject*)object{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _fileObject = object;
    }
    return self;
}

- (void)dealloc{
    [[NIMSDK sharedSDK].resourceManager cancelTask:_fileObject.path];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = self.fileObject.displayName;
    self.fileNameLabel.text   = self.fileObject.displayName;
    NSString *filePath = self.fileObject.path;
    self.progressView.hidden = YES;
    [self.actionBtn addTarget:self action:@selector(touchUpBtn) forControlEvents:UIControlEventTouchUpInside];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self.actionBtn setTitle:@"用其他应用程序打开" forState:UIControlStateNormal];
    }else{
        [self.actionBtn setTitle:@"下载文件" forState:UIControlStateNormal];
    }
}

- (void)touchUpBtn{
    NSString *filePath = self.fileObject.path;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self openWithOtherApp];
    }else{
        if (self.isDownLoading) {
            [[NIMSDK sharedSDK].resourceManager cancelTask:filePath];
            self.progressView.hidden   = YES;
            self.progressView.progress = 0.0;
            [self.actionBtn setTitle:@"下载文件" forState:UIControlStateNormal];
            self.isDownLoading         = NO;
        }else{
            [self downLoadFile];
        }
    }
}

#pragma mark - 文件下载

- (void)downLoadFile{
    NSString *url = self.fileObject.url;
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].resourceManager download:url filepath:self.fileObject.path progress:^(CGFloat progress) {
        wself.isDownLoading = YES;
        wself.progressView.hidden = NO;
        wself.progressView.progress = progress;
        [wself.actionBtn setTitle:@"取消下载" forState:UIControlStateNormal];
    } completion:^(NSError *error) {
        wself.isDownLoading = NO;
        wself.progressView.hidden = YES;
        if (!error) {
            [wself.actionBtn setTitle:@"用其他应用程序打开" forState:UIControlStateNormal];
        }else{
            wself.progressView.progress = 0.0f;
            [wself.actionBtn setTitle:@"下载失败，点击重新下载" forState:UIControlStateNormal];
        }
    }];
}


#pragma mark - 其他应用打开

- (void)openWithOtherApp{
    self.interactionController =
    [UIDocumentInteractionController
    interactionControllerWithURL:[NSURL fileURLWithPath:self.fileObject.path]];
    if (![self.interactionController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES])
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:@"未找到打开该应用的程序" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }
}

@end
