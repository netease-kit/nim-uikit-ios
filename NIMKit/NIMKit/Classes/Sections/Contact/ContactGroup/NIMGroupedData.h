//
//  NIMGroupedData.h
//  NIMKit
//
//  Created by emily on 2017/7/26.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NIMContactDefines.h"


@interface NIMGroupedData : NSObject

@property(nonatomic, strong) NSArray *members;

@property(nonatomic, strong) NSArray *specialMembers;
//联系人title
@property(nonatomic, readonly) NSArray *sectionTitles;
//联系人姓名
@property(nonatomic, readonly) NSDictionary *contentDic;

@end
