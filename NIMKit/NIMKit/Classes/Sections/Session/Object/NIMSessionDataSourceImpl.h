//
//  NIMSessionTableData.h
//  NIMKit
//
//  Created by chris on 2016/11/7.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMSessionConfigurateProtocol.h"
#import "NIMSessionPrivateProtocol.h"
#import "NIMSessionConfig.h"

@interface NIMSessionDataSourceImpl : NSObject<NIMSessionDataSource>

- (instancetype)initWithSession:(NIMSession *)session
                         config:(id<NIMSessionConfig>)sessionConfig;

@end
