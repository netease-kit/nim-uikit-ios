/// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

@objcMembers
public class IMKitConfigCenter: NSObject {
  public static let shared = IMKitConfigCenter()

  override private init() {
    super.init()
  }

  /// 是否展示群聊
  public var enableTeam = true {
    didSet {
      if enableTeam == false {
        IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth = false
      }
    }
  }

  /// 验证消息是否展示群聊入群申请、入群邀请
  public var enableTeamJoinAgreeModelAuth = false

  /// 是否展示 @ 效果
  public var enableAtMessage = true

  /// 是否开启【收藏】功能
  public var enableCollectionMessage = true

  /// 是否开启【标记】功能
  public var enablePinMessage = true

  /// 是否显示消息【置顶】、【取消置顶】入口
  public var enableTopMessage = true

  /// 是否开启订阅在线状态
  public var enableOnlineStatus = true

  /// 好友能否进行音视频通话
  public var enableOnlyFriendCall = true

  /// 解散、离开群聊是否同步删除会话
  public var enableDismissTeamDeleteConversation = true

  /// 是否开启数字人支持
  public var enableAIUser = true

  /// 是否开启 AI 聊天助手
  public var enableAIChatHelper = true

  /// 是否使用换行消息功能
  public var enableRichTextMessage = true

  /// 是否插入反垃圾提示消息
  public var enableAntiSpamTipMessage = true

  /// 是否开启流式消息
  public var enableAIStream = true

  /// 撤回消息后是否插入提示消息【此消息已撤回】
  public var enableInsertLocalMsgWhenRevoke = true

  /// 是否使用云端搜索消息，默认使用本地搜索
  public var enableCloudMessageSearch = (UserDefaults.standard.value(forKey: keyEnableCloudMessageSearch) as? Bool) ?? false

  /// 最近转发的会话 id 列表最大长度
  public var recentForwardListMaxCount = 5

  /// 群聊中允许添加的管理员人数
  public var teamManagerMaxCount = 10

  // MARK: - 消息翻译配置

  /// 自动翻译开启时间戳（毫秒）。
  /// 0 = 关闭，非零 = 开启，且值为开关打开时刻的时间戳。
  /// 仅对 createTime > autoTranslationEnableTime 的文本消息自动翻译。
  public var autoTranslationEnableTime: TimeInterval = 0

  /// 翻译目标语言代码（ISO 639-1 / 云信扩展格式），默认英文。
  public var translationTargetLanguage: String = "en"
}
