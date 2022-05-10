
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NIMSDK
class P2PChatViewController: ChatViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func getSessionInfo(session: NIMSession) {
        viewmodel.getUserInfo(userId: session.sessionId)
        let user = viewmodel.getUserInfo(userId: session.sessionId)
        let title = user?.showName() ?? ""
        self.title = title
        titleContent = title
        //self.menuView.textField.placeholder = localizable("send_to") + title
        self.menuView.textField.placeholder = localizable("send_to") + title as NSString
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
