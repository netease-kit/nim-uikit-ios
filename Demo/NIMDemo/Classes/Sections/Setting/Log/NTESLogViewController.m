//
//  NTESLogViewController.m
//  NIM
//
//  Created by Xuhui on 15/4/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESLogViewController.h"
#import "NTESLogManager.h"

@interface NTESLogViewController ()<NSLayoutManagerDelegate>
@property (strong, nonatomic) IBOutlet UITextView *logTextView;
@property (copy,nonatomic) NSString *path;
@property (copy,nonatomic) NSString *content;
@end

@implementation NTESLogViewController


- (instancetype)initWithFilepath:(NSString *)path
{
    if (self = [self initWithNibName:@"NTESLogViewController" bundle:nil])
    {
        self.path = path;
    }
    return self;
}


- (instancetype)initWithContent:(NSString *)content
{
    if (self = [self initWithNibName:@"NTESLogViewController" bundle:nil])
    {
        self.content = content;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStyleDone target:self action:@selector(onDismiss:)];
    
    NSString *content = nil;
    if (_path)
    {
        NSData *data = [NSData dataWithContentsOfFile:_path];
        content = [[NSString alloc] initWithData:data
                                        encoding:NSUTF8StringEncoding];
        if (content == nil)
        {
            content = [[NSString alloc] initWithData:data
                                            encoding:NSASCIIStringEncoding];
        }
    }
    else if(_content)
    {
        content = _content;
    }
    
    _logTextView.text = content;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if ([_logTextView.text length])
    {
        [_logTextView scrollRangeToVisible:NSMakeRange([_logTextView.text length], 0)];
    }
    
}


- (void)onDismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
