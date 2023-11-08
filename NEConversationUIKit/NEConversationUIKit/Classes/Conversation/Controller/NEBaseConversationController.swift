
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseConversationController: UIViewController, NIMChatManagerDelegate {
  public let viewmodel = ConversationViewModel()
  public var listCtrl = NEBaseConversationListViewController()

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = NEKitConversationConfig.shared.ui.hiddenNav
    } else {
      navigationController?.isNavigationBarHidden = true
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    NIMSDK.shared().chatManager.add(self)
  }

  func initSystemNav() {
    let brandBarBtn = UIButton()
    brandBarBtn.accessibilityIdentifier = "id.titleBarTitle"
    brandBarBtn.setTitle(localizable("appName"), for: .normal)
    brandBarBtn.setImage(UIImage.ne_imageNamed(name: "brand_yunxin"), for: .normal)
    brandBarBtn.layoutButtonImage(style: .left, space: 12)
    brandBarBtn.setTitleColor(UIColor.black, for: .normal)
    brandBarBtn.titleLabel?.font = NEConstant.textFont("PingFangSC-Medium", 20)
    let brandBtn = UIBarButtonItem(customView: brandBarBtn)
    navigationItem.leftBarButtonItem = brandBtn
  }

  open func setupSubviews() {
    initSystemNav()
    view.addSubview(navView)
    NSLayoutConstraint.activate([
      navView.topAnchor.constraint(equalTo: view.topAnchor),
      navView.leftAnchor.constraint(equalTo: view.leftAnchor),
      navView.rightAnchor.constraint(equalTo: view.rightAnchor),
      navView.heightAnchor
        .constraint(equalToConstant: NEConstant.navigationAndStatusHeight),
    ])

    listCtrl.view.translatesAutoresizingMaskIntoConstraints = false
    addChild(listCtrl)
    view.addSubview(listCtrl.view)
  }

  deinit {
    NIMSDK.shared().chatManager.remove(self)
  }

  // MARK: lazyMethod

  public lazy var navView: TabNavigationView = {
    let nav = TabNavigationView(frame: CGRect.zero)
    nav.translatesAutoresizingMaskIntoConstraints = false
    nav.delegate = self

    nav.isHidden = NEKitConversationConfig.shared.ui.hiddenNav
    return nav
  }()
}

extension NEBaseConversationController: TabNavigationViewDelegate {
  open func searchAction() {}

  open func didClickAddBtn() {}

  open func createDiscussGroup() {
    Router.shared.register(ContactSelectedUsersRouter) { param in
      print("user setting accids : ", param)
      Router.shared.use(TeamCreateDisuss, parameters: param, closure: nil)
    }
    Router.shared.use(
      ContactUserSelectRouter,
      parameters: ["nav": navigationController as Any, "limit": inviteNumberLimit],
      closure: nil
    )
    weak var weakSelf = self
    Router.shared.register(TeamCreateDiscussResult) { param in
      print("create discuss ", param)
      if let code = param["code"] as? Int, let teamid = param["teamId"] as? String,
         code == 0 {
        let session = weakSelf?.viewmodel.repo.createTeamSession(teamid)
        Router.shared.use(
          PushTeamChatVCRouter,
          parameters: ["nav": weakSelf?.navigationController as Any,
                       "session": session as Any],
          closure: nil
        )
      } else if let msg = param["msg"] as? String {
        weakSelf?.showToast(msg)
      }
    }
  }

  open func createSeniorGroup() {
    Router.shared.register(ContactSelectedUsersRouter) { param in
      Router.shared.use(TeamCreateSenior, parameters: param, closure: nil)
    }
    Router.shared.use(
      ContactUserSelectRouter,
      parameters: ["nav": navigationController as Any, "limit": 200],
      closure: nil
    )
    weak var weakSelf = self
    Router.shared.register(TeamCreateSeniorResult) { param in
      print("create senior : ", param)
      if let code = param["code"] as? Int, let teamid = param["teamId"] as? String,
         code == 0 {
        let session = weakSelf?.viewmodel.repo.createTeamSession(teamid)
        Router.shared.use(
          PushTeamChatVCRouter,
          parameters: ["nav": weakSelf?.navigationController as Any,
                       "session": session as Any],
          closure: nil
        )
      } else if let msg = param["msg"] as? String {
        weakSelf?.showToast(msg)
      }
    }
  }

  // MARK: =========================NIMChatManagerDelegate========================

  open func onRecvRevokeMessageNotification(_ notification: NIMRevokeMessageNotification) {
    guard let msg = notification.message else {
      return
    }
    saveRevokeMessage(msg) { error in
    }
  }

  open func saveRevokeMessage(_ message: NIMMessage, _ completion: @escaping (Error?) -> Void) {
    let messageNew = NIMMessage()
    messageNew.text = localizable("message_recalled")
    var muta = [String: Any]()
    muta[revokeLocalMessage] = true
//    if message.messageType == .text {
//      muta[revokeLocalMessageContent] = message.text
//    }
    messageNew.timestamp = message.timestamp
    messageNew.from = message.from
    messageNew.localExt = muta
    let setting = NIMMessageSetting()
    setting.shouldBeCounted = false
    setting.isSessionUpdate = false
    messageNew.setting = setting
    if let session = message.session {
      viewmodel.repo.saveMessageToDB(messageNew, session, completion)
    }
  }
}
