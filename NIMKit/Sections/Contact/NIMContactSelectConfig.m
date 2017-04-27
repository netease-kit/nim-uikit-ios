//
//  NIMContactSelectConfig.m
//  NIMKit
//
//  Created by chris on 15/9/14.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMContactSelectConfig.h"

@implementation NIMContactFriendSelectConfig : NSObject

- (NIMContactSelectType)selectType{
    return NIMContactSelectTypeFriend;
}


- (BOOL)isMutiSelected{
    return self.needMutiSelected;
}

- (NSString *)title{
    return @"选择联系人";
}


- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)selectedOverFlowTip{
    return @"选择超限";
}


@end

@implementation NIMContactTeamMemberSelectConfig : NSObject

- (NIMContactSelectType)selectType{
    return NIMContactSelectTypeTeamMember;
}


- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)title{
    return @"选择联系人";
}


- (NSString *)selectedOverFlowTip{
    return @"选择超限";
}

@end

@implementation NIMContactTeamSelectConfig : NSObject

- (NIMContactSelectType)selectType{
    return NIMContactSelectTypeTeam;
}



- (NSString *)title{
    return @"选择群组";
}

- (NSInteger)maxSelectedNum{
    if (self.needMutiSelected) {
        return NSIntegerMax;
    }else{
        return 1;
    }
}

- (NSString *)selectedOverFlowTip{
    return @"选择超限";
}


@end