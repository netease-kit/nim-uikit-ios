//
//  NTESGroupedDataCollection.m
//  NIM
//
//  Created by Xuhui on 15/3/2.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESGroupedDataCollection.h"

@interface Pair : NSObject

@property (nonatomic, strong) id first;
@property (nonatomic, strong) id second;

@end

@implementation Pair

- (instancetype)initWithFirst:(id)first second:(id)second {
    self = [super init];
    if(self) {
        _first = first;
        _second = second;
    }
    return self;
}

@end

@interface NTESGroupedDataCollection () {
    NSMutableOrderedSet *_specialGroupTtiles;
    NSMutableOrderedSet *_specialGroups;
    NSMutableOrderedSet *_groupTtiles;
    NSMutableOrderedSet *_groups;
}

@end

@implementation NTESGroupedDataCollection

- (instancetype)init
{
    self = [super init];
    if(self) {
        _specialGroupTtiles = [[NSMutableOrderedSet alloc] init];
        _specialGroups = [[NSMutableOrderedSet alloc] init];
        _groupTtiles = [[NSMutableOrderedSet alloc] init];
        _groups = [[NSMutableOrderedSet alloc] init];
    }
    return self;
}

- (NSArray *)sortedGroupTitles
{
    return [_groupTtiles array];
}

- (void)setMembers:(NSArray *)members
{
    NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
    NSString *me = [[NIMSDK sharedSDK].loginManager currentAccount];
    for (id<NTESGroupMemberProtocol>member in members) {
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
            [_groups addObject:[[Pair alloc] initWithFirst:groupTitle second:groupedMembers]];
        }
    }];
    [self sort];
}

- (void)addGroupMember:(id<NTESGroupMemberProtocol>)member
{
    NSString *groupTitle = [member groupTitle];
    NSInteger groupIndex = [_groupTtiles indexOfObject:groupTitle];
    Pair *pair = [_groups objectAtIndex:groupIndex];
    if(!pair) {
        NSMutableArray *members = [NSMutableArray array];
        pair = [[Pair alloc] initWithFirst:groupTitle second:members];
    }
    NSMutableArray *members = pair.second;
    [members addObject:member];
    [_groupTtiles addObject:groupTitle];
    [_groups addObject:pair];
    [self sort];
}

- (void)removeGroupMember:(id<NTESGroupMemberProtocol>)member{
    NSString *groupTitle = [member groupTitle];
    NSInteger groupIndex = [_groupTtiles indexOfObject:groupTitle];
    Pair *pair = [_groups objectAtIndex:groupIndex];
    [pair.second removeObject:member];
    if (![pair.second count]) {
        [_groups removeObject:pair];
    }
    [self sort];
}

- (void)addGroupAboveWithTitle:(NSString *)title members:(NSArray *)members {
    Pair *pair = [[Pair alloc] initWithFirst:title second:members];
    [_specialGroupTtiles addObject:title];
    [_specialGroups addObject:pair];
}

- (NSString *)titleOfGroup:(NSInteger)groupIndex
{
    if(groupIndex >= 0 && groupIndex < _specialGroupTtiles.count) {
        return [_specialGroupTtiles objectAtIndex:groupIndex];
    }
    groupIndex -= _specialGroupTtiles.count;
    if(groupIndex >= 0 && groupIndex < _groupTtiles.count) {
        return [_groupTtiles objectAtIndex:groupIndex];
    }
    return nil;
}

- (NSArray *)membersOfGroup:(NSInteger)groupIndex
{
    if(groupIndex >= 0 && groupIndex < _specialGroups.count) {
        Pair *pair = [_specialGroups objectAtIndex:groupIndex];
        return pair.second;
    }
    groupIndex -= _specialGroups.count;
    if(groupIndex >= 0 && groupIndex < _groups.count) {
        Pair *pair = [_groups objectAtIndex:groupIndex];
        return pair.second;
    }
    return nil;
}

- (id<NTESGroupMemberProtocol>)memberOfIndex:(NSIndexPath *)indexPath
{
    NSArray *members = nil;
    NSInteger groupIndex = indexPath.section;
    if(groupIndex >= 0 && groupIndex < _specialGroups.count) {
        Pair *pair = [_specialGroups objectAtIndex:groupIndex];
        members = pair.second;
    }
    groupIndex -= _specialGroups.count;
    if(groupIndex >= 0 && groupIndex < _groups.count) {
        Pair *pair = [_groups objectAtIndex:groupIndex];
        members = pair.second;
    }
    NSInteger memberIndex = indexPath.row;
    if(memberIndex < 0 || memberIndex >= members.count) return nil;
    return [members objectAtIndex:memberIndex];
}

- (id<NTESGroupMemberProtocol>)memberOfId:(NSString *)uid{
    for (Pair *pair in _groups) {
        NSArray *members = pair.second;
        for (id<NTESGroupMemberProtocol> member in members) {
            if ([[member memberId] isEqualToString:uid]) {
                return member;
            }
        }
    }
    return nil;
}

- (NSInteger)groupCount
{
    return _specialGroupTtiles.count + _groupTtiles.count;
}

- (NSInteger)memberCountOfGroup:(NSInteger)groupIndex
{
    NSArray *members = nil;
    if(groupIndex >= 0 && groupIndex < _specialGroups.count) {
        Pair *pair = [_specialGroups objectAtIndex:groupIndex];
        members = pair.second;
    }
    groupIndex -= _specialGroups.count;
    if(groupIndex >= 0 && groupIndex < _groups.count) {
        Pair *pair = [_groups objectAtIndex:groupIndex];
        members = pair.second;
    }
    return members.count;
}

- (void)sort
{
    [self sortGroupTitle];
    [self sortGroupMember];
}

- (void)sortGroupTitle
{
    [_groupTtiles sortUsingComparator:_groupTitleComparator];
    [_groups sortUsingComparator:^NSComparisonResult(Pair *pair1, Pair *pair2) {
        return _groupTitleComparator(pair1.first, pair2.first);
    }];
}

- (void)sortGroupMember
{
    [_groups enumerateObjectsUsingBlock:^(Pair *obj, NSUInteger idx, BOOL *stop) {
        NSMutableArray *groupedMembers = obj.second;
        [groupedMembers sortUsingComparator:^NSComparisonResult(id<NTESGroupMemberProtocol> member1, id<NTESGroupMemberProtocol> member2) {
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
