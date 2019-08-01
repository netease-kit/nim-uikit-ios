//
//  NIMTeamCardHeaderView.h
//  NIMKit
//
//  Created by Netease on 2019/6/10.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NIMTeamCardHeaderViewDelegate <NSObject>

- (void)onTouchAvatar:(id)sender;

@end

@interface NIMTeamCardHeaderViewModel : NSObject

@property (nonatomic, strong) NSString *avatarUrl;

@property (nonatomic, copy) NSString *teamName;

@property (nonatomic, copy) NSString *teamId;

@property (nonatomic, assign) NSTimeInterval createTime;

@property (nonatomic, strong) id exObj;

- (instancetype)initWithTeam:(NIMTeam *)team;

- (instancetype)initWithSuperTeam:(NIMTeam *)team;

@end

@interface NIMTeamCardHeaderView : UIView

@property (nonatomic, weak) id<NIMTeamCardHeaderViewDelegate> delegate;

@property (nonatomic, strong) NIMTeamCardHeaderViewModel *dataModel;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
