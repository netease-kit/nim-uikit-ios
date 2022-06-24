
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NEKitCoreIM

public enum roundedType {
    case none
    case top
    case bottom
    case all
}

public struct RoleModel {
    public var role: ChannelRole?
    public var member: MemberRole?
    public var title: String?
    public var corner: roundedType?
    public var isPlacehold: Bool = false
}

public struct QChatRoles {
    public var roles: [RoleModel] = [RoleModel]()
    public var timeTag: TimeInterval?
    public var pageSize: Int = 5

}
