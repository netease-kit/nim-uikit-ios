//
//  NTESDemoRegisterTask.h
//  NIM
//
//  Created by amao on 1/20/16.
//  Copyright © 2016 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESDemoServiceTask.h"

typedef void(^NTESRegisterHandler)(NSError *error,NSString *errorMsg);

@interface NTESRegisterData : NSObject
@property (nonatomic,copy)      NSString    *account;

@property (nonatomic,copy)      NSString    *token;

@property (nonatomic,copy)      NSString    *nickname;
@end

@interface NTESDemoRegisterTask : NSObject<NTESDemoServiceTask>
@property (nonatomic,strong)    NTESRegisterData        *data;
@property (nonatomic,copy)      NTESRegisterHandler     handler;
@end
