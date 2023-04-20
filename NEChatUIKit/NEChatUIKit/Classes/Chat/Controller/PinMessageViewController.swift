//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

let PinMessageDefaultType = 1000
@objcMembers
public class PinMessageViewController: ChatBaseViewController, UITableViewDataSource, UITableViewDelegate, PinMessageViewModelDelegate, PinMessageCellDelegate {
  let viewmodel = PinMessageViewModel()

  var session: NIMSession

  public init(session: NIMSession) {
    self.session = session
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var cellClassDic = [
    NIMMessageType.text.rawValue: PinMessageTextCell.self,
    NIMMessageType.image.rawValue: PinMessageImageCell.self,
    NIMMessageType.audio.rawValue: PinMessageAudioCell.self,
    NIMMessageType.video.rawValue: PinMessageVideoCell.self,
    NIMMessageType.location.rawValue: PinMessageLocationCell.self,
    NIMMessageType.file.rawValue: PinMessageFileCell.self,
    PinMessageDefaultType: PinMessageDefaultCell.self,
  ]

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .white
    tableView.keyboardDismissMode = .onDrag
    tableView.backgroundColor = UIColor(hexString: "#EFF1F3")
    return tableView
  }()

  private lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "user_empty",
      content: chatLocalizable("no_pin_message"),
      frame: .zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()

    viewmodel.delegate = self
    setupUI()
    loadData()
  }

  func loadData() {
    weak var weakSelf = self
    viewmodel.getPinitems(session: session) { error in
      if let err = error as? NSError {
        if weakSelf?.session.sessionType == .team, err.code == 414 {
          weakSelf?.showToast(chatLocalizable("team_not_exist"))
        } else {
          weakSelf?.showToast(err.localizedDescription)
        }
      } else {
        weakSelf?.emptyView.isHidden = (weakSelf?.viewmodel.items.count ?? 0) > 0
        weakSelf?.tableView.reloadData()
      }
    }
  }

  func setupUI() {
    title = chatLocalizable("operation_pin")
    view.addSubview(tableView)
    if #available(iOS 10, *) {
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: view.topAnchor,
          constant: kNavigationHeight + KStatusBarHeight
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: view.topAnchor,
          constant: 0
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
    }

    view.addSubview(emptyView)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
        emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
        emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        emptyView.topAnchor.constraint(equalTo: view.topAnchor),
        emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
        emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
        emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
    }

    cellClassDic.forEach { (key: Int, value: PinMessageBaseCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = viewmodel.items[indexPath.row]
    if item.message.session?.sessionType == .P2P {
      let session = item.message.session
      Router.shared.use(
        PushP2pChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any,
                     "anchor": item.message],
        closure: nil
      )
    } else if item.message.session?.sessionType == .team {
      let session = item.message.session
      Router.shared.use(
        PushTeamChatVCRouter,
        parameters: ["nav": navigationController as Any, "session": session as Any,
                     "anchor": item.message],
        closure: nil
      )
    }
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewmodel.items[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "\(model.getMessageType())", for: indexPath) as! PinMessageBaseCell
    cell.delegate = self
    cell.configure(model)
    return cell
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewmodel.items.count
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewmodel.items[indexPath.row]
    return model.cellHeight()
  }

  func showAction(item: PinMessageModel) {
    var actions = [UIAlertAction]()
    weak var weakSelf = self
    /*
     let jumpAction = UIAlertAction(title: chatLocalizable("pin_jump_detail"), style: .default) { _ in
       if item.message.session?.sessionType == .P2P {
         let session = item.message.session
         Router.shared.use(
           PushP2pChatVCRouter,
           parameters: ["nav": weakSelf?.navigationController as Any, "session": session as Any,
                        "anchor": item.message],
           closure: nil
         )
       } else if item.message.session?.sessionType == .team {
         let session = item.message.session
         Router.shared.use(
           PushTeamChatVCRouter,
           parameters: ["nav": weakSelf?.navigationController as Any, "session": session as Any,
                        "anchor": item.message],
           closure: nil
         )
       }
     }
     actions.append(jumpAction)
     */
    let cancelPinAction = UIAlertAction(title: chatLocalizable("operation_cancel_pin"), style: .default) { _ in

      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.showToast(commonLocalizable("network_error"))
        return
      }
      weakSelf?.viewmodel.removePinMessage(item.message) { error, model in
        if let err = error {
//          weakSelf?.showToast(err.localizedDescription)
        } else {
          if let index = weakSelf?.viewmodel.items.firstIndex(of: item) {
            NotificationCenter.default.post(name: Notification.Name(removePinMessageNoti), object: item.message)
            weakSelf?.viewmodel.items.remove(at: index)
            weakSelf?.emptyView.isHidden = (weakSelf?.viewmodel.items.count ?? 0) > 0
            weakSelf?.tableView.reloadData()
            weakSelf?.showToast(chatLocalizable("cancel_pin_success"))
          }
        }
      }
    }
    actions.append(cancelPinAction)

    if item.message.messageType == .text {
      let copyAction = UIAlertAction(title: chatLocalizable("operation_copy"), style: .default) { _ in
        let text = item.message.text
        let pasteboard = UIPasteboard.general
        pasteboard.string = text
        weakSelf?.view.makeToast(chatLocalizable("copy_success"), duration: 2, position: .center)
      }
      actions.append(copyAction)
    }

    if item.message.messageType != .audio {
      let forwardAction = UIAlertAction(title: chatLocalizable("operation_forward"), style: .default) { _ in
        if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
          weakSelf?.showToast(commonLocalizable("network_error"))
          return
        }
        weakSelf?.forwardMessage(item.message)
      }

      actions.append(forwardAction)
    }

    let cancelAction = UIAlertAction(title: chatLocalizable("cancel"), style: .cancel) { _ in
    }
    actions.append(cancelAction)

    showActionSheet(actions)
  }

  private func forwardMessage(_ message: NIMMessage) {
    weak var weakSelf = self
    let userAction = UIAlertAction(title: chatLocalizable("contact_user"),
                                   style: .default) { action in

      Router.shared.register(ContactSelectedUsersRouter) { param in
        print("user setting accids : ", param)
        var items = [ForwardItem]()

        if let users = param["im_user"] as? [NIMUser] {
          users.forEach { user in
            let item = ForwardItem()
            item.uid = user.userId
            item.avatar = user.userInfo?.avatarUrl
            item.name = user.userInfo?.nickName
            items.append(item)
          }

          let forwardAlert = ForwardAlertViewController()
          forwardAlert.setItems(items)
          if let senderName = message.senderName {
            forwardAlert.context = senderName
          }
          weakSelf?.addChild(forwardAlert)
          weakSelf?.view.addSubview(forwardAlert.view)

          forwardAlert.sureBlock = {
            print("sure click ")
            weakSelf?.viewmodel.forwardUserMessage(message, users)
          }
        }
      }
      var param = [String: Any]()
      param["nav"] = weakSelf?.navigationController as Any
      param["limit"] = 6
      if let session = weakSelf?.session, session.sessionType == .P2P {
        var filters = Set<String>()
        filters.insert(session.sessionId)
        param["filters"] = filters
      }
      Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)
    }

    let teamAction = UIAlertAction(title: chatLocalizable("team"), style: .default) { action in

      Router.shared.register(ContactTeamDataRouter) { param in
        if let team = param["team"] as? NIMTeam {
          let item = ForwardItem()
          item.avatar = team.avatarUrl
          item.name = team.getShowName()
          item.uid = team.teamId

          let forwardAlert = ForwardAlertViewController()
          forwardAlert.setItems([item])
          if let senderName = message.senderName {
            forwardAlert.context = senderName
          }
          forwardAlert.sureBlock = {
            weakSelf?.viewmodel.forwardTeamMessage(message, team)
          }
          weakSelf?.addChild(forwardAlert)
          weakSelf?.view.addSubview(forwardAlert.view)
        }
      }

      Router.shared.use(
        ContactTeamListRouter,
        parameters: ["nav": weakSelf?.navigationController as Any],
        closure: nil
      )
    }

    let cancelAction = UIAlertAction(title: chatLocalizable("cancel"),
                                     style: .cancel) { action in
    }

    showActionSheet([teamAction, userAction, cancelAction])
  }

  // MARK: PinMessageViewModelDelegate

  public func didNeedRefreshUI() {
    loadData()
  }

  // MARK: PinMessageCellDelegate

  func didClickMore(_ model: PinMessageModel?) {
    print("did click more")
    if let item = model {
      showAction(item: item)
    }
  }
}
