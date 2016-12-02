//
//  NTESCustomNotificationDB.m
//  NIM
//
//  Created by chris on 15/5/26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESCustomNotificationDB.h"
#import "FMDB.h"
#import "NTESFileLocationHelper.h"
#import "NTESCustomNotificationObject.h"

typedef NS_ENUM(NSInteger, CustomNotificationStatus){
    CustomNotificationStatusNone    = 0,
    CustomNotificationStatusRead    = 1,
    CustomNotificationStatusDeleted = 2,
};

@interface NTESCustomNotificationDB ()
@property (nonatomic,strong)  FMDatabase *db;
@end


@implementation NTESCustomNotificationDB

- (instancetype)init
{
    if (self = [super init])
    {
        [self openDatabase];
    }
    return self;
}


- (NSInteger)unreadCount
{
    __block NSInteger count = 0;
    io_sync_safe(^{
        count = _unreadCount;
    });
    return count;
}

- (NSArray *)fetchNotifications:(NTESCustomNotificationObject *)notification
                          limit:(NSInteger)limit{
    __block NSArray *result = nil;
    
    NSString *sql = nil;
    if (notification)
    {
        sql = [NSString stringWithFormat:@"select * from notifications where timetag < %f and status != ? order by timetag desc limit ?",
               notification.timestamp] ;
    }
    else
    {
        sql = @"select * from notifications where status != ? order by timetag desc limit ?";
    }
    io_sync_safe(^{
        NSMutableArray *array = [NSMutableArray array];
        FMResultSet *rs = [self.db executeQuery:sql,@(CustomNotificationStatusDeleted),@(limit)];
        while ([rs next])
        {
            NTESCustomNotificationObject *notification = [[NTESCustomNotificationObject alloc] init];
            notification.serial         = (NSInteger)[rs intForColumn:@"serial"];
            notification.timestamp      = [rs doubleForColumn:@"timetag"];
            notification.sender         = [rs stringForColumn:@"sender"];
            notification.receiver       = [rs stringForColumn:@"receiver"];
            notification.content        = [rs stringForColumn:@"content"];
            [array addObject:notification];
        }
        [rs close];
        result = array;
    });
    
    return result;

}

- (BOOL)saveNotification:(NTESCustomNotificationObject *)notification{
    __block BOOL result = NO;
    io_sync_safe(^{
        if (notification)
        {
            CustomNotificationStatus status = notification.needBadge? CustomNotificationStatusNone : CustomNotificationStatusRead;
            NSString *sql = @"insert into notifications(timetag,sender,receiver,content,status)  \
            values(?,?,?,?,?)";
            if (![self.db executeUpdate:sql,
                  @(notification.timestamp),
                  notification.sender,
                  notification.receiver,
                  notification.content,
                  @(status)])
            {
                DDLogError(@"update failed %@ error %@",notification,self.db.lastError);
            }
            else
            {
                notification.serial = (NSInteger)[self.db lastInsertRowId];
                if (notification.needBadge) {
                    self.unreadCount++;
                }
                result = YES;
            }
        }
    });
    return result;

}

- (void)deleteNotification:(NTESCustomNotificationObject *)notification{
    NSString *sql = @"update notifications set status  = ? where serial = ?";
    io_async(^{
        if (![self.db executeUpdate:sql,@(CustomNotificationStatusDeleted),@(notification.serial)])
        {
            DDLogError(@"delete notifications failed");
        }
        [self queryUnreadCount];
    });
}


- (void)deleteAllNotification{
    NSString *sql = @"update notifications set status  = ? where status < ? or status > ?";
    io_async(^{
        if (![self.db executeUpdate:sql,@(CustomNotificationStatusDeleted),@(CustomNotificationStatusDeleted),@(CustomNotificationStatusDeleted)])
        {
            DDLogError(@"delete notifications failed");
        }
        [self queryUnreadCount];
    });
}


- (void)markAllNotificationsAsRead{
    NSString *sql = @"update notifications set status  = ? where status = ?";
    io_sync_safe(^{
        if (![self.db executeUpdate:sql,@(CustomNotificationStatusRead),@(CustomNotificationStatusNone)])
        {
            DDLogError(@"mark notifications read failed");
        }
        [self queryUnreadCount];
    });
}

- (void)queryUnreadCount{
    NSInteger count = 0;
    NSString *sql = @"select count(serial) from notifications where status = ?";
    FMResultSet *rs = [_db executeQuery:sql,@(CustomNotificationStatusNone)];
    if ([rs next])
    {
        count = (NSInteger)[rs intForColumnIndex:0];
    }
    [rs close];
    
    if (count != _unreadCount)
    {
        self.unreadCount = count;
    }
}


#pragma mark - Misc
- (void)openDatabase
{
    NSString *filepath = [[NTESFileLocationHelper userDirectory] stringByAppendingString:@"notification.db"];
    FMDatabase *db = [FMDatabase databaseWithPath:filepath];
    if ([db open])
    {
        _db = db;
        NSArray *sqls = @[@"create table if not exists notifications(serial integer primary key, \
                          timetag integer,sender text,receiver text,content text,status integer)",
                          @"create index if not exists readindex on notifications(status)",
                          @"create index if not exists timetagindex on notifications(timetag)"];
        for (NSString *sql in sqls)
        {
            if (![_db executeUpdate:sql])
            {
                DDLogError(@"error: execute sql %@ failed error %@",sql,_db.lastError);
            }
        }
        [self queryUnreadCount];
    }
    else
    {
        DDLogError(@"error open database failed %@",filepath);
    }
}

static const void * const NTESDispatchIOSpecificKey = &NTESDispatchIOSpecificKey;
dispatch_queue_t NTESDispatchIOQueue()
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("nim.demo.io.queue", 0);
        dispatch_queue_set_specific(queue, NTESDispatchIOSpecificKey, (void *)NTESDispatchIOSpecificKey, NULL);
    });
    return queue;
}


typedef void(^dispatch_block)(void);
void io_sync_safe(dispatch_block block)
{
    if (dispatch_get_specific(NTESDispatchIOSpecificKey))
    {
        block();
    }
    else
    {
        dispatch_sync(NTESDispatchIOQueue(), ^() {
            block();
        });
    }
}


void io_async(dispatch_block block){
    dispatch_async(NTESDispatchIOQueue(), ^() {
        block();
    });
}


@end
