//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NERtcCallKit
import NIMSDK
import UIKit

class CustomFunChatViewController: FunP2PChatViewController, NERecordProvider {
  /// 话单拦截
  func onRecordSend(_ config: NERecordConfig) {
    NEALog.infoLog(className(), desc: "call status : \(NECallEngine.sharedInstance().callStatus)")
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      if NECallEngine.sharedInstance().callStatus == .calling {
        return
      }
    }

    let message = V2NIMMessageCreator.createCallMessage("", type: Int(config.callType.rawValue), channelId: "", status: Int(config.callState.rawValue), durations: [])
    if let cid = V2NIMConversationIdUtil.p2pConversationId(config.accId) {
      viewModel.chatRepo.sendMessage(message: message, conversationId: cid) { [weak self] result, error, ret in
        NEALog.infoLog(self?.className() ?? "", desc: "CustomNormalChatViewController result: \(error?.localizedDescription ?? "")")
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    NECallEngine.sharedInstance().setCall(self)
    // Do any additional setup after loading the view.
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
}
