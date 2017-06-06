//
//  NTESTeamMeetingMutesCell.h
//  NIM
//
//  Created by chris on 2017/5/9.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESTeamMeetingMuteCell : UITableViewCell

@property (nonatomic,strong) NIMTeam *team;

- (void)refresh:(NSString *)userId muted:(BOOL)muted;

@end
