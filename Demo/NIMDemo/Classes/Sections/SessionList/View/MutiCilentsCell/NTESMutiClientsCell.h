//
//  NTESMutiClientsCell.h
//  NIM
//
//  Created by chris on 15/7/22.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESMutiClientsCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UIButton *kickBtn;

- (void)refreshWidthCilent:(NIMLoginClient *)client;

@end
