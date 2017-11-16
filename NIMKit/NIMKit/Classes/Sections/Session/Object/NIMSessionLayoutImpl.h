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

@property (nonatomic,strong)  UITableView *tableView;

@property (nonatomic,strong)  NIMInputView *inputView;

- (instancetype)initWithSession:(NIMSession *)session
                         config:(id<NIMSessionConfig>)sessionConfig;

@end
