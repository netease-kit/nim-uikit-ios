//
//  NTESVideoChatNetStateView.h
//  NIM
//
//  Created by chris on 15/5/20.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESVideoChatNetStatusView : UIView

- (void)refreshWithNetState:(NIMNetCallNetStatus)status;

@end
