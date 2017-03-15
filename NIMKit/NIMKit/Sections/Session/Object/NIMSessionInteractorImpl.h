//
//  NIMSessionInteractor.h
//  NIMKit
//
//  Created by chris on 2016/11/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMSessionPrivateProtocol.h"
#import "NIMSessionConfigurateProtocol.h"

@interface NIMSessionInteractorImpl : NSObject<NIMSessionInteractor>

- (instancetype)initWithSession:(NIMSession *)session
                         config:(id<NIMSessionConfig>)sessionConfig;

@property(nonatomic,weak) id<NIMSessionInteractorDelegate> delegate;

@property(nonatomic,strong) id<NIMSessionDataSource> dataSource;

@property(nonatomic,strong) id<NIMSessionLayout>     layout;

@end
