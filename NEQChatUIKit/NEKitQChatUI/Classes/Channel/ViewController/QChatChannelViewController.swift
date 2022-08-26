
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import Toast_Swift
import NEKitCoreIM

struct Channel {
  var sectionName = ""
  var contentName = ""
}

public class QChatChannelViewController: QChatTableViewController, QChatTextEditCellDelegate,
  QChatChannelTypeVCDelegate {
  var viewModel: QChatChannelViewModel?
  var dataList = [Channel]()
  // 防重点击创建频道
  var isCreatedChannel = false

  public init(serverId: UInt64) {
    viewModel = QChatChannelViewModel(serverId: serverId)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
  }

  func commonUI() {
    title = localizable("create_channel")
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: localizable("create"),
      style: .plain,
      target: self,
      action: #selector(createChannel)
    )
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: localizable("cancel"),
      style: .plain,
      target: self,
      action: #selector(cancelEvent)
    )
    navigationItem.rightBarButtonItem?.tintColor = .ne_greyText
    tableView.register(
      QChatTextEditCell.self,
      forCellReuseIdentifier: "\(QChatTextEditCell.self)"
    )
    tableView.register(
      QChatTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatTextArrowCell.self)"
    )
    tableView.register(
      QChatSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(QChatSectionView.self)"
    )
  }

  func loadData() {
    dataList
      .append(Channel(sectionName: localizable("channel_name"),
                      contentName: localizable("input_channel_name")))
    dataList.append(Channel(
      sectionName: localizable("channel_topic"),
      contentName: localizable("input_channel_topic")
    ))
    dataList
      .append(Channel(sectionName: localizable("channel_type"),
                      contentName: localizable("public")))
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    dataList.count
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    1
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextEditCell.self)",
        for: indexPath
      ) as! QChatTextEditCell
      cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        .union(CornerType.topLeft).union(CornerType.topRight)
      cell.textFied.placeholder = dataList[indexPath.section].contentName
      cell.delegate = self
      cell.textFied.tag = 11
      return cell
    } else if indexPath.section == 1 {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextEditCell.self)",
        for: indexPath
      ) as! QChatTextEditCell
      cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        .union(CornerType.topLeft).union(CornerType.topRight)
      cell.textFied.placeholder = dataList[indexPath.section].contentName
      cell.delegate = self
      cell.textFied.tag = 12
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextArrowCell.self)",
        for: indexPath
      ) as! QChatTextArrowCell
      cell.titleLabel.text = dataList[indexPath.section].contentName
      cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        .union(CornerType.topLeft).union(CornerType.topRight)
      return cell
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let sectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(QChatSectionView.self)"
      ) as! QChatSectionView
    sectionView.titleLable.text = dataList[section].sectionName
    return sectionView
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 2 {
      // select channel type
      let vc = QChatChannelTypeVC()
      vc.delegate = self
      vc.isPrivate = viewModel?.isPrivate ?? false
      navigationController?.pushViewController(vc, animated: true)
    }
  }

//    MARK: event

  @objc func createChannel() {
      
      guard let name = viewModel?.name,name.count > 0 else {
          self.showToast("频道名称不能为空")
          return
      }
      
    if !isCreatedChannel {
      isCreatedChannel = true
      viewModel?.createChannel { error, channel in
        NELog.errorLog(
          "QChatChannelViewController",
          desc: "error:\(error?.localizedDescription) channel:\(channel)"
        )
        if error == nil {
          // success to chatVC
          self.navigationController?.dismiss(animated: true, completion: {
            NotificationCenter.default.post(
              name: NotificationName.createChannel,
              object: channel
            )
          })
        } else {
          self.view.makeToast(error?.localizedDescription) { didTap in
            self.navigationController?.dismiss(animated: true, completion: nil)
          }
        }
      }
    }
  }

  @objc func cancelEvent() {
    print(#function)
    dismiss(animated: true, completion: nil)
  }

//    MARK: QChatTextEditCellDelegate

  func textDidChange(_ textField: UITextField) {
    print("textFieldDidChangeSelection textField:\(textField.text)")
    if textField.tag == 11 {
      if textField.text?.count == 0 {
        navigationItem.rightBarButtonItem?.tintColor = .ne_greyText
      } else {
        if var str = textField.text, str.count > 50 {
          str = str.substring(to: str.index(str.startIndex, offsetBy: 50))
          print("str:\(str)")
          textField.text = str
        }
        navigationItem.rightBarButtonItem?.tintColor = .ne_blueText
      }
      viewModel?.name = textField.text
    } else if textField.tag == 12 {
      if var str = textField.text, str.count > 64 {
        str = str.substring(to: str.index(str.startIndex, offsetBy: 64))
        print("str:\(str)")
        textField.text = str
      }
      viewModel?.topic = textField.text
    }
  }

//    MARK: QChatChannelTypeVCDelegate

  func didSelected(type: Int) {
    viewModel?.isPrivate = type == 0 ? false : true
    if dataList.count >= 3 {
      dataList.removeLast()
      dataList.append(Channel(
        sectionName: localizable("channel_type"),
        contentName: type == 0 ? localizable("public") : localizable("private")
      ))
      tableView.reloadData()
    }
  }
}
