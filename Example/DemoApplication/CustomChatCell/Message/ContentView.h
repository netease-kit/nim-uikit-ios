//
//  ContentView.h
//  DemoApplication
//
//  Created by chris on 15/11/1.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "NIMKit.h"
#import "NIMSessionMessageContentView.h"

@interface ContentView : NIMSessionMessageContentView

@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) UILabel *subTitleLabel;

@end
