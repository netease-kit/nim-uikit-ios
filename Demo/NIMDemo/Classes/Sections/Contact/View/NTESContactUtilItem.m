//
//  ContactUtilItem.m
//  NIM
//
//  Created by chris on 15/2/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESContactUtilItem.h"

@implementation NTESContactUtilItem

- (NSString*)reuseId{
    return @"NTESContactUtilItem";
}

- (NSString*)cellName{
    return @"NTESContactUtilCell";
}

- (NSString*)title{
    return nil;
}

@end

@implementation NTESContactUtilMember

- (NSString *)avatarUrl{
    return nil;
}

- (CGFloat)uiHeight{
    return NTESContactUtilRowHeight;
}

- (NSString*)reuseId{
    return @"NTESContactUtilItem";
}

- (NSString*)cellName{
    return @"NTESContactUtilCell";
}

- (NSString *)groupTitle {
    return nil;
}

- (NSString *)memberId{
    return self.userId;
}

- (BOOL)showAccessoryView{
    return YES;
}

- (id)sortKey {
    return nil;
}

@end