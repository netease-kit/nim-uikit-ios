//
//  TeamAnnouncementListViewController.h
//  NIM
//
//  Created by Xuhui on 15/3/31.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

@protocol NIMTeamAnnouncementListVCDelegate <NSObject>

- (void)didUpdateAnnouncement:(NSString *)content
                   completion:(void (^)(NSError *error))completion;

@end

@interface  NIMTeamAnnouncementListOption : NSObject

@property (nonatomic, assign) BOOL canCreateAnnouncement;

@property (nonatomic, copy) NSString *announcement;

@property (nonatomic, copy) NSString *nick;

@end

@interface NIMTeamAnnouncementListViewController : UIViewController

@property (nonatomic, weak) id <NIMTeamAnnouncementListVCDelegate> delegate;

- (instancetype)initWithOption:(NIMTeamAnnouncementListOption *)option;

@end
