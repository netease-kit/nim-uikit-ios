
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NIMSDK
import NEKitCoreIM


@objcMembers
open class GroupChatViewController: ChatViewController, TeamChatViewModelDelegate {
    

    
    public init(session: NIMSession,anchor:NIMMessage?) {
//        self.viewmodel = ChatViewModel(session: session)
        super.init(session: session)
        self.viewmodel = TeamChatViewModel(session: session, anchor: anchor)
        self.viewmodel.delegate = self
        
    }
    
    
    /// 创建群的构造方法
    /// - Parameter sessionId: 会话id
    public init(sessionId:String) {
        let session = NIMSession(sessionId, type: .team)
        super.init(session: session)
        
    }
    
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    open override func getSessionInfo(session: NIMSession) {
        if let vm = self.viewmodel as? TeamChatViewModel {
            if let t = vm.getTeam(teamId: session.sessionId)  {
                self.updateTeamInfo(team: t)
            }
        }
    }
    
//    MARK: private method
    private func updateTeamInfo(team: NIMTeam) {
        self.title = team.getShowName()
        if team.inAllMuteMode(),team.owner != NIMSDK.shared().loginManager.currentAccount() {
            self.menuView.textField.isEditable = false
            self.menuView.textField.placeholder = localizable("team_mute") as NSString
        }else {
            self.menuView.textField.isEditable = true
            self.menuView.textField.placeholder = localizable("send_to") + team.getShowName() as NSString
        }
    }
    
//    MARK: TeamChatViewModelDelegate
    public func onTeamRemoved(team: NIMTeam) {
        //只有群创建者 才弹弹窗
        if team.owner == IMKitLoginManager.instance.imAccid {
            showSingleAlert(message: localizable("team_has_been_removed")) {
                self.navigationController?.popViewController(animated: true)
            }
        }else {
            self.navigationController?.popViewController(animated: true)
        }

    }
    
    public func onTeamUpdate(team: NIMTeam) {
        self.updateTeamInfo(team: team)
    }
}
