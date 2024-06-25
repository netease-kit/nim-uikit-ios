// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEConversationUIKit
import UIKit

public class InhertViewController: ConversationController {
  override public func viewDidLoad() {
    super.viewDidLoad()
    let test = TestViewController(conversationId: "")
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
