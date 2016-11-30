//
//  NIMSessionLayout.h
//  NIMKit
//
//  Created by chris on 2016/11/8.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMSessionConfigurator.h"
#import "NIMSessionPrivateProtocol.h"

@interface NIMSessionLayoutImpl : NSObject<NIMSessionLayout>

- (instancetype)initWithSession:(NIMSession *)session
                      tableView:(UITableView *)tableView
                         config:(id<NIMSessionConfig>)sessionConfig;

@end
