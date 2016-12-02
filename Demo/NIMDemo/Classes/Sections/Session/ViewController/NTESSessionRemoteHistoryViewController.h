//
//  NTESSessionRemoteHistoryViewController.h
//  NIM
//
//  Created by chris on 15/4/22.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMSessionConfig.h"
#import "NTESSessionConfig.h"
#import "NTESSessionViewController.h"

@protocol NTESRemoteSessionDelegate <NSObject>

- (void)fetchRemoteDataError:(NSError *)error;

@end


@interface NTESSessionRemoteHistoryViewController : NTESSessionViewController

@end




@interface NTESRemoteSessionConfig : NTESSessionConfig

@property (nonatomic,weak) id<NTESRemoteSessionDelegate> delegate;

- (instancetype)initWithSession:(NIMSession *)session;

@end



@interface NIMRemoteMessageDataProvider : NSObject<NIMKitMessageProvider>

@property (nonatomic,strong) NIMSession *session;

@property (nonatomic,assign) NSInteger limit;

@property (nonatomic,weak) id<NTESRemoteSessionDelegate> delegate;

- (instancetype)initWithSession:(NIMSession *)session limit:(NSInteger)limit;

@end