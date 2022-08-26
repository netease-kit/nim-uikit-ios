
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
import NEKitCoreIM
import NEKitCommonUI

public class ReadViewController: NEBaseViewController, UIScrollViewDelegate, UITableViewDelegate,
  UITableViewDataSource {
  public var read: Bool = true
  public var line: UIView = .init()
  public var lineLeftCons: NSLayoutConstraint?
  public var readTableView = UITableView(frame: .zero, style: .plain)
  public var readUsers = [User]()
  public var unReadUsers = [User]()
  public let readButton = UIButton(type: .custom)
  public let unreadButton = UIButton(type: .custom)
  private var message: NIMMessage
  init(message: NIMMessage) {
    self.message = message
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData(message: message)
  }

  func commonUI() {
    title = localizable("message_read")
    readButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    readButton.setTitle("已读(0）", for: .normal)
    readButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    readButton.translatesAutoresizingMaskIntoConstraints = false
    readButton.addTarget(self, action: #selector(readButtonEvent), for: .touchUpInside)
    view.addSubview(readButton)

    unreadButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    unreadButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    unreadButton.setTitle("未读(0）", for: .normal)
    unreadButton.translatesAutoresizingMaskIntoConstraints = false
    unreadButton.addTarget(self, action: #selector(unreadButtonEvent), for: .touchUpInside)

    view.addSubview(unreadButton)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        readButton.topAnchor.constraint(
          equalTo: self.view.safeAreaLayoutGuide.topAnchor,
          constant: 0
        ),
        readButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
        readButton.heightAnchor.constraint(equalToConstant: 48),
        readButton.widthAnchor.constraint(equalTo: unreadButton.widthAnchor),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        readButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
        readButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        readButton.heightAnchor.constraint(equalToConstant: 48),
        readButton.widthAnchor.constraint(equalTo: unreadButton.widthAnchor),
      ])
    }

    NSLayoutConstraint.activate([
      unreadButton.topAnchor.constraint(equalTo: readButton.topAnchor),
      unreadButton.leadingAnchor.constraint(equalTo: readButton.trailingAnchor),
      unreadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      unreadButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = UIColor.ne_blueText
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
    readTableView.register(
      UserTableViewCell.self,
      forCellReuseIdentifier: "\(UserTableViewCell.self)"
    )
    readTableView.separatorStyle = .none
    readTableView.rowHeight = 62
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

  @objc func readButtonEvent(button: UIButton) {
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

  @objc func unreadButtonEvent(button: UIButton) {
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
      if let error = anError {
        self.showToast(error.localizedDescription)
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

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if read {
      return readUsers.count
    } else {
      return unReadUsers.count
    }
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(UserTableViewCell.self)",
      for: indexPath
    ) as! UserTableViewCell
    if read {
      let model = readUsers[indexPath.row]
      cell.setModel(model)

    } else {
      let model = unReadUsers[indexPath.row]
      cell.setModel(model)
    }
    return cell
  }

  private lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "emptyView",
      content: localizable("message_all_unread"),
      frame: .zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(view)
    return view
  }()
}
