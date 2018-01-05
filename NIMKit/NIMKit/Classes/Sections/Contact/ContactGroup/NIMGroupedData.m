//
//  NIMGroupedData.m
//  NIMKit
//
//  Created by emily on 2017/7/26.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMGroupedData.h"

@interface NIMKitPair : NSObject

@property (nonatomic, strong) id first;
@property (nonatomic, strong) id second;

@end

@implementation NIMKitPair

- (instancetype)initWithFirst:(id)first second:(id)second {
    self = [super init];
    if(self) {
        _first = first;
        _second = second;
    }
    return self;
}

@end

@interface NIMGroupedData ()

@property(nonatomic, strong) NSMutableOrderedSet *groupTtiles;
@property(nonatomic, strong) NSMutableOrderedSet *groups;
@property (nonatomic, copy) NSComparator groupTitleComparator;
@property (nonatomic, copy) NSComparator groupMemberComparator;


@end

@implementation NIMGroupedData

- (instancetype)init {
    if (self = [super init]) {
        _members = @[].mutableCopy;
        _specialMembers = @[].mutableCopy;
        _groupTtiles = [[NSMutableOrderedSet alloc] init];
        _groups = [[NSMutableOrderedSet alloc] init];
        _groupTitleComparator = ^NSComparisonResult(NSString *title1, NSString *title2) {
            return [title1 localizedCompare:title2];
        };
        _groupMemberComparator = ^NSComparisonResult(NSString *key1, NSString *key2) {
            return [key1 localizedCompare:key2];
        };
    }
    return self;
}

- (void)setMembers:(NSArray *)members {
    NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
    NSString *me = [[NIMSDK sharedSDK].loginManager currentAccount];
    for (id<NIMGroupMemberProtocol>member in members) {
        if ([[member memberId] isEqualToString:me]) {
            continue;
        }
        NSString *groupTitle = [member groupTitle];
        NSMutableArray *groupedMembers = [tmp objectForKey:groupTitle];
        if(!groupedMembers) {
            groupedMembers = [NSMutableArray array];
        }
        [groupedMembers addObject:member];
        [tmp setObject:groupedMembers forKey:groupTitle];
    }
    [_groupTtiles removeAllObjects];
    [_groups removeAllObjects];
    
    [tmp enumerateKeysAndObjectsUsingBlock:^(NSString *groupTitle, NSMutableArray *groupedMembers, BOOL *stop) {
        if (groupTitle.length) {
            unichar character = [groupTitle characterAtIndex:0];
            if (character >= 'A' && character <= 'Z') {
                [_groupTtiles addObject:groupTitle];
            }else{
                [_groupTtiles addObject:@"#"];
            }
            [_groups addObject:[[NIMKitPair alloc] initWithFirst:groupTitle second:groupedMembers]];
        }
    }];
    [self sortGroup];
}

- (void)setSpecialMembers:(NSArray *)specialMembers {
    if (specialMembers.count > 0) {
        _specialMembers = specialMembers;
        [_groups insertObject:[[NIMKitPair alloc] initWithFirst:@"$" second:specialMembers] atIndex:0];
        [self sortGroupMember];
        [_groupTtiles insertObject:@"$" atIndex:0];
    }
}

#pragma mark - Getter

- (NSArray *)sectionTitles {
    return [_groupTtiles array];
}

- (NSDictionary *)contentDic {
    NSDictionary *dic = @{}.mutableCopy;
    for (int i = 0; i < _groups.count; ++i) {
        NSArray *tempArr = [self membersOfGroup:i];
        NSString *title = [self titleofGroup:i];
        [tempArr enumerateObjectsUsingBlock:^(id<NIMGroupMemberProtocol>member, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableArray *arr = [dic valueForKey:title];
            if (!arr) {
                arr = @[].mutableCopy;
                [dic setValue:arr forKey:title];
            }
            [arr addObject:member];
        }];
    }
    return dic;
}

#pragma mark - Private

- (NSString *)titleofGroup:(NSInteger)groupIndex {
    if(groupIndex >= 0 && groupIndex < _groupTtiles.count) {
        return [_groupTtiles objectAtIndex:groupIndex];
    }
    return nil;
}

- (NSArray *)membersOfGroup:(NSInteger)groupIndex
{
    if(groupIndex >= 0 && groupIndex < _groups.count) {
        NIMKitPair *pair = [_groups objectAtIndex:groupIndex];
        return pair.second;
    }
    return nil;
}

- (void)sortGroup
{
    [self sortGroupTitle];
    [self sortGroupMember];
}

- (void)sortGroupTitle
{
    [_groupTtiles sortUsingComparator:_groupTitleComparator];
    [_groups sortUsingComparator:^NSComparisonResult(NIMKitPair *pair1, NIMKitPair *pair2) {
        return _groupTitleComparator(pair1.first, pair2.first);
    }];
}

- (void)sortGroupMember
{
    [_groups enumerateObjectsUsingBlock:^(NIMKitPair *obj, NSUInteger idx, BOOL *stop) {
        NSMutableArray *groupedMembers = obj.second;
        [groupedMembers sortUsingComparator:^NSComparisonResult(id<NIMGroupMemberProtocol> member1, id<NIMGroupMemberProtocol> member2) {
            return _groupMemberComparator([member1 sortKey], [member2 sortKey]);
        }];
    }];
}

- (void)setGroupTitleComparator:(NSComparator)groupTitleComparator
{
    _groupTitleComparator = groupTitleComparator;
    [self sortGroupTitle];
}

- (void)setGroupMemberComparator:(NSComparator)groupMemberComparator
{
    _groupMemberComparator = groupMemberComparator;
    [self sortGroupMember];
}

@end
