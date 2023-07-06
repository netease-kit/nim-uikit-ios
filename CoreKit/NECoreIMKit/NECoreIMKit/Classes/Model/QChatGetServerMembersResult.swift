
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

public struct QChatGetServerMembersResult {
  public var memberArray = [ServerMemeber]()
  /**
   * 是否还有下一页数据
   */
  public var hasMore: Bool?
  /**
   * 下一页的起始时间戳
   */
  public var nextTimetag: TimeInterval?

  /// 成员信息
  /// - Parameter memberData: 成员信息结果
  init(memberData: NIMQChatGetServerMembersResult?) {
    guard let memberArray = memberData?.memberArray else { return }

    for member in memberArray {
      let itemModel = ServerMemeber(member)
      self.memberArray.append(itemModel)
    }
  }

  /// 分页成员信息
  /// - Parameter membersResult: 成员信息结果
  init(membersResult: NIMQChatGetServerMemberListByPageResult?) {
    guard let memberArray = membersResult?.memberArray else { return }
    for member in memberArray {
      let itemModel = ServerMemeber(member)
      self.memberArray.append(itemModel)
    }
    hasMore = membersResult?.hasMore
    nextTimetag = membersResult?.nextTimetag
  }
}
