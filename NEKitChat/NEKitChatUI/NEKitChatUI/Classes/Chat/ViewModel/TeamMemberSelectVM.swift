
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NIMSDK
import NEKitChat

public class TeamMemberSelectVM {
    public var chatRepo: ChatRepo = ChatRepo()
    
    func fetchTeamMembers(sessionId: String, _ completion: @escaping (Error?, ChatTeamInfoModel?) -> Void ) {
        chatRepo.fetchTeamInfo(sessionId, completion)
    }
}
