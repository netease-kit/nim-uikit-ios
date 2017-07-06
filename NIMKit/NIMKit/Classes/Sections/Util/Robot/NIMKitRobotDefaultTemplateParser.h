//
//  NIMKitRobotDefaultTemplateParser.h
//  NIMKit
//
//  Created by chris on 2017/6/25.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIMKitRobotTemplateParserProtocol.h"
#import "NIMKitRobotTemplate.h"

@class NIMMessage;

@interface NIMKitRobotDefaultTemplateParser : NSObject<NIMKitRobotTemplateParser>

- (void)clean;

- (NIMKitRobotTemplate *)robotTemplate:(NIMMessage *)message;

@end
