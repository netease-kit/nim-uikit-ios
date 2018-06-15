//
//  NIMSessionListViewController.h
//  NIMKit
//
//  Created by NetEase.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIMCellConfig.h"
#import <NIMSDK/NIMSDK.h>

@interface NIMSessionListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,NIMLoginManagerDelegate,NIMConversationManagerDelegate>
/**
 *  会话列表tableView
 */
@property (nonatomic,strong)   UITableView *tableView;

/**
 *  最近会话集合
 */
@property (nonatomic,strong) NSMutableArray * recentSessions;

/**
 *  删除会话时是不是也同时删除服务器会话 (防止漫游)
 */
@property (nonatomic,assign)   BOOL autoRemoveRemoteSession;


/**
 *  选中某一条最近会话时触发的事件回调
 *
 *  @param recent    最近会话
 *  @param indexPath 最近会话cell所在的位置
 *  @discussion      默认将进入会话界面
 */
- (void)onSelectedRecent:(NIMRecentSession *)recent
             atIndexPath:(NSIndexPath *)indexPath;

/**
 *  选中某一条最近会话的头像控件，触发的事件回调
 *
 *  @param recent    最近会话
 *  @param indexPath 最近会话cell所在的位置
 *  @discussion      默认将进入会话界面
 */
- (void)onSelectedAvatar:(NIMRecentSession *)recent
             atIndexPath:(NSIndexPath *)indexPath;


/**
 *  cell显示的会话名
 *
 *  @param recent 最近会话
 *
 *  @return 会话名
 *
 *  @discussion 默认实现为：点对点会话，显示聊天对象的昵称(没有昵称则显示账号)；群聊会话，显示群名称。
 */
- (NSString *)nameForRecentSession:(NIMRecentSession *)recent;

/**
 *  cell显示的最近会话具体内容
 *
 *  @param recent 最近会话
 *
 *  @return 具体内容名
 *
 *  @discussion 默认实现为：显示最近一条消息的内容，文本消息则显示文本信息，其他类型消息详见本类中 - (NSAttributedString *)messageContent:(NIMMessage *)lastMessage 方法的实现。
 */
- (NSAttributedString *)contentForRecentSession:(NIMRecentSession *)recent;


/**
 *  cell显示的最近会话时间戳
 *
 *  @param recent 最近会话
 *
 *  @return 时间戳格式化后的字符串
 *
 *  @discussion 默认实现为：最后一条消息的时间戳，具体时间戳消息格式详见NIMKitUtil中， + (NSString*)showTime:(NSTimeInterval) msglastTime showDetail:(BOOL)showDetail 方法的实现。
 */
- (NSString *)timestampDescriptionForRecentSession:(NIMRecentSession *)recent;

/**
 *  重新加载所有数据，调用时必须先调用父类方法
 */
- (void)refresh;

/**
 *  自定义最近会话排序，上层可以重写这个方法对最近会话重新排序
 */
- (NSMutableArray *)customSortRecents:(NSMutableArray *)recentSessions;

@end
