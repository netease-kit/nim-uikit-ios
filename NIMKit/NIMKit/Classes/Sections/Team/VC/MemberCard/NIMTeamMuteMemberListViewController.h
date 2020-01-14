//
//  NIMTeamMuteMemberListViewController.h
//  NIMKit
//
//  Created by Genning-Work on 2019/12/13.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMTeamMemberListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface NIMTeamMuteMemberListViewController : UIViewController

- (instancetype)initWithDataSource:(id<NIMTeamMemberListDataSource>)dataSource;

@end

NS_ASSUME_NONNULL_END
