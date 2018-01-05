//
//  NIMTeamSwitchTableViewCell.h
//  NIM
//
//  Created by amao on 5/29/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NIMTeamSwitchProtocol <NSObject>
- (void)onStateChanged:(BOOL)on;
@end

@interface NIMTeamSwitchTableViewCell : UITableViewCell
@property (strong, nonatomic) UISwitch *switcher;
@property (weak, nonatomic) id<NIMTeamSwitchProtocol> switchDelegate;

@end
