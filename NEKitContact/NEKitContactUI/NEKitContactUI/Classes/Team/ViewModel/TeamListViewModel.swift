
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import NEKitContact
import NEKitCoreIM

public class TeamListViewModel {
    var contactRepo = ContactRepo()
    public var teamList = [Team]()
    func getTeamList() -> [Team]? {
        teamList = contactRepo.getTeamList()
        return teamList
    }
}
