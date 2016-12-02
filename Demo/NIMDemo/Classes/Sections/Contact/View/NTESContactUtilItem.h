//
//  NTESContactUtilItem.h
//  NIM
//
//  Created by chris on 15/2/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESContactDefines.h"
#import "NTESGroupedContacts.h"

@interface NTESContactUtilItem : NSObject<NTESContactItemCollection>

@property (nonatomic,copy) NSArray *members;

@end

@interface NTESContactUtilMember : NSObject<NTESContactItem, NTESGroupMemberProtocol>

@property (nonatomic,copy) NSString *nick;

@property (nonatomic,copy) NSString *badge;

@property (nonatomic,copy) UIImage *icon;

@property (nonatomic,copy) NSString *vcName;

@property (nonatomic,copy) NSString *userId;

@property (nonatomic,copy) NSString *selName;

@end
