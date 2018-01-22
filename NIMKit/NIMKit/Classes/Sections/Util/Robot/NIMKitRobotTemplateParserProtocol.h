//
//  NIMKitRobotTemplateParserProtocol.h
//  NIMKit
//
//  Created by chris on 2017/6/25.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NIMKitRobotTemplateParser <NSObject>

- (BOOL)parse:(NSString *)templateText;

@end
