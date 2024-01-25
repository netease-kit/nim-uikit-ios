
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIMKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseReadViewController: ChatBaseViewController, UIScrollViewDelegate, UITableViewDelegate,
  UITableViewDataSource {
  public var read: Bool = true
  public var line: UIView = .init()
  public var lineLeftCons: NSLayoutConstraint?
  public var readTableView = UITableView(frame: .zero, style: .plain)
  public var readUsers = [NEKitUser]()
  public var unReadUsers = [NEKitUser]()
  public let readButton = UIButton(type: .custom)
  public let unreadButton = UIButton(type: .custom)
  private var message: NIMMessage
  init(message: NIMMessage) {
    self.message = message
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData(message: message)
  }

  open func commonUI() {
    title = chatLocalizable("message_read")
    navigationView.moreButton.isHidden = true

    readButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    readButton.setTitle(chatLocalizable("read"), for: .normal)
    readButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    readButton.translatesAutoresizingMaskIntoConstraints = false
    readButton.addTarget(self, action: #selector(readButtonEvent), for: .touchUpInside)
    readButton.accessibilityIdentifier = "id.tabHasRead"

    unreadButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    unreadButton.setTitle(chatLocalizable("unread"), for: .normal)
    unreadButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    unreadButton.translatesAutoresizingMaskIntoConstraints = false
    unreadButton.addTarget(self, action: #selector(unreadButtonEvent), for: .touchUpInside)
    readButton.accessibilityIdentifier = "id.tabUnRead"

    view.addSubview(readButton)
    NSLayoutConstraint.activate([
      readButton.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      readButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      readButton.heightAnchor.constraint(equalToConstant: 48),
      readButton.widthAnchor.constraint(equalToConstant: kScreenWidth / 2.0),
    ])

    view.addSubview(unreadButton)
    NSLayoutConstraint.activate([
      unreadButton.topAnchor.constraint(equalTo: readButton.topAnchor),
      unreadButton.leadingAnchor.constraint(equalTo: readButton.trailingAnchor),
      unreadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      unreadButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    line.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(line)
    lineLeftCons = line.leadingAnchor.constraint(equalTo: view.leadingAnchor)
    NSLayoutConstraint.activate([
      line.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 0),
      line.heightAnchor.constraint(equalToConstant: 1),
      line.widthAnchor.constraint(equalTo: readButton.widthAnchor),
      lineLeftCons!,
    ])

    view.addSubview(emptyView)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        emptyView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
        emptyView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0),
        emptyView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0),
        emptyView.bottomAnchor.constraint(
          equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
          constant: 0
        ),
      ])
    } else {
      NSLayoutConstraint.activate([
        emptyView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
        emptyView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
        emptyView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
        emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
      ])
    }
    readTableView.delegate = self
    readTableView.dataSource = self
    readTableView.sectionHeaderHeight = 0
    readTableView.sectionFooterHeight = 0
    readTableView.translatesAutoresizingMaskIntoConstraints = false
    readTableView.separatorStyle = .none
    readTableView.tableFooterView = UIView()
    view.addSubview(readTableView)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        readTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
        readTableView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
        readTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        readTableView.bottomAnchor
          .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        readTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        readTableView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
        readTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        readTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
    }
  }

  open func readButtonEvent(button: UIButton) {
    if read {
      return
    }
    read = true
    lineLeftCons?.constant = 0
    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }
    if readUsers.count == 0 {
      readTableView.isHidden = true
      emptyView.isHidden = false
    } else {
      readTableView.isHidden = false
      emptyView.isHidden = true
      readTableView.reloadData()
    }
  }

  open func unreadButtonEvent(button: UIButton) {
    if !read {
      return
    }
    read = false
    lineLeftCons?.constant = button.width
    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }
    if unReadUsers.count == 0 {
      readTableView.isHidden = true
      emptyView.isHidden = false
    } else {
      readTableView.isHidden = false
      emptyView.isHidden = true
      readTableView.reloadData()
    }
  }

  func loadData(message: NIMMessage) {
    NIMSDK.shared().chatManager.queryMessageReceiptDetail(message) { anError, receiptInfo in
      print("anError:\(anError) receiptInfo:\(receiptInfo)")
      if let error = anError as? NSError {
        if error.code == noNetworkCode {
          self.showToast(commonLocalizable("network_error"))
        } else {
          self.showToast(error.localizedDescription)
        }
        return
      }

      for userId in receiptInfo?.readUserIds ?? [] {
        if let uId = userId as? String,
           let user = UserInfoProvider.shared.getUserInfo(userId: uId) {
          self.readUsers.append(user)
        }
      }

      for userId in receiptInfo?.unreadUserIds ?? [] {
        if let uId = userId as? String,
           let user = UserInfoProvider.shared.getUserInfo(userId: uId) {
          self.unReadUsers.append(user)
        }
      }
      self.readButton.setTitle("已读 (" + "\(self.readUsers.count)" + ")", for: .normal)
      self.unreadButton.setTitle("未读 (" + "\(self.unReadUsers.count)" + ")", for: .normal)
      self.readTableView.reloadData()

      if self.read, self.readUsers.count == 0 {
        self.readTableView.isHidden = true
        self.emptyView.isHidden = false
      } else {
        self.readTableView.isHidden = false
        self.emptyView.isHidden = true
      }
    }
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if read {
      return readUsers.count
    } else {
      return unReadUsers.count
    }
  }

  func cellSetModel(cell: UserBaseTableViewCell, indexPath: IndexPath) -> UITableViewCell {
    if read {
      let model = readUsers[indexPath.row]
      cell.setModel(model)

    } else {
      let model = unReadUsers[indexPath.row]
      cell.setModel(model)
    }
    return cell
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(UserBaseTableViewCell.self)",
      for: indexPath
    ) as! UserBaseTableViewCell
    return cellSetModel(cell: cell, indexPath: indexPath)
  }

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "emptyView",
      content: chatLocalizable("message_all_unread"),
      frame: .zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(view)
    return view
  }()
}
