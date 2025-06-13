
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

public
protocol AIChatViewDelegate: NSObjectProtocol {
  func didClickMessageItem(_ text: String)
  func didClickEditButton(_ text: String?)
}

@objcMembers
open class AIChatViewController: UIViewController {
  public weak var delegate: AIChatViewDelegate?
  public let viewModel = AIChatViewModel()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  lazy var titleIcon: UIImageView = {
    let icon = UIImageView(image: UIImage.ne_imageNamed(name: "ai_icon_highlight"))
    icon.translatesAutoresizingMaskIntoConstraints = false
    return icon
  }()

  public lazy var titleView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(titleIcon)
    NSLayoutConstraint.activate([
      titleIcon.leftAnchor.constraint(equalTo: view.leftAnchor),
      titleIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      titleIcon.widthAnchor.constraint(equalToConstant: 24),
      titleIcon.heightAnchor.constraint(equalToConstant: 24),
    ])

    view.addSubview(reloadButton)
    NSLayoutConstraint.activate([
      reloadButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      reloadButton.rightAnchor.constraint(equalTo: view.rightAnchor),
      reloadButton.widthAnchor.constraint(equalToConstant: 24),
      reloadButton.heightAnchor.constraint(equalToConstant: 24),
    ])

    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.text = chatLocalizable("ai_chat_title")
    view.addSubview(title)
    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: titleIcon.rightAnchor, constant: 4),
      title.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      title.rightAnchor.constraint(equalTo: reloadButton.leftAnchor, constant: 4),
      title.heightAnchor.constraint(equalToConstant: 24),
    ])

    return view
  }()

  public lazy var reloadButton: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
//    button.isHidden = true
    button.setImage(UIImage.ne_imageNamed(name: "ai_reload"), for: .normal)
    button.addTarget(self, action: #selector(reloadData), for: .touchUpInside)
    return button
  }()

  public lazy var loadDataView: NELottieAnimationView = {
    let view = NELottieAnimationView(name: "ai_chat_loading", bundle: chatCoreLoader.bundle)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.loopMode = .loop
    view.contentMode = .center
    return view
  }()

  public lazy var loadDataFailedView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true

    let failedTips = UILabel()
    failedTips.translatesAutoresizingMaskIntoConstraints = false
    failedTips.text = chatLocalizable("ai_chat_for_failure")
    failedTips.textColor = .ne_darkText

    let failedReloadButton = UIButton()
    failedReloadButton.translatesAutoresizingMaskIntoConstraints = false
    failedReloadButton.backgroundColor = .white
    failedReloadButton.layer.cornerRadius = 8
    failedReloadButton.layer.borderWidth = 1
    failedReloadButton.layer.borderColor = UIColor(hexString: "#000000", 0.1).cgColor
    failedReloadButton.setTitle(chatLocalizable("ai_chat_click_retry"), for: .normal)
    failedReloadButton.setTitleColor(.ne_darkText, for: .normal)
    failedReloadButton.titleLabel?.font = .systemFont(ofSize: 14)
    failedReloadButton.addTarget(self, action: #selector(reloadData), for: .touchUpInside)

    view.addSubview(failedReloadButton)
    NSLayoutConstraint.activate([
      failedReloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      failedReloadButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      failedReloadButton.heightAnchor.constraint(equalToConstant: 32),
    ])

    view.addSubview(failedTips)
    NSLayoutConstraint.activate([
      failedTips.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      failedTips.centerYAnchor.constraint(equalTo: failedReloadButton.centerYAnchor, constant: -44),
      failedTips.heightAnchor.constraint(equalToConstant: 24),
    ])

    return view
  }()

  public lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear

    tableView.estimatedRowHeight = 0
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0

    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
  }

  open func commonUI() {
    view.backgroundColor = .clear

    view.addSubview(titleView)
    NSLayoutConstraint.activate([
      titleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
      titleView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: chat_content_margin),
      titleView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -chat_cell_margin),
      titleView.heightAnchor.constraint(equalToConstant: 24),
    ])

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: chat_content_margin),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: chat_cell_margin),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -chat_cell_margin),
      tableView.heightAnchor.constraint(equalToConstant: 216),
    ])

    tableView.register(AIChatTableViewCell.self, forCellReuseIdentifier: "\(AIChatTableViewCell.self)")

    view.addSubview(loadDataView)
    NSLayoutConstraint.activate([
      loadDataView.topAnchor.constraint(equalTo: tableView.topAnchor),
      loadDataView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      loadDataView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
      loadDataView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
    ])

    view.addSubview(loadDataFailedView)
    NSLayoutConstraint.activate([
      loadDataFailedView.topAnchor.constraint(equalTo: tableView.topAnchor),
      loadDataFailedView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
      loadDataFailedView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
      loadDataFailedView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
    ])
  }

  /// 加载 AI 助聊语句
  /// - Parameters:
  ///   - messages: 上下文消息
  ///   - lastMessage: 对方发送的最后一条消息
  ///   - force: 是否强制刷新助聊语句
  open func loadData(_ messages: [V2NIMMessage]? = nil,
                     _ lastMessage: V2NIMMessage?,
                     _ force: Bool) {
    if !force, messages?.last?.messageClientId == viewModel.lastContents?.last?.messageClientId {
      return
    }

    tableView.isHidden = true
    loadDataFailedView.isHidden = true
    loadDataView.isHidden = false
    loadDataView.play()

    viewModel.loadData(messages, lastMessage) { [weak self] error in
      self?.loadDataView.isHidden = true
      self?.loadDataView.stop()
      if error != nil {
        self?.loadDataFailedView.isHidden = false
        self?.tableView.isHidden = true
      } else {
        self?.loadDataFailedView.isHidden = true
        self?.tableView.isHidden = false
        self?.tableView.reloadData()
      }
    }
  }

  open func reloadData() {
    if let aiChatReloadClick = ChatUIConfig.shared.aiChatReloadClick {
      aiChatReloadClick(self, viewModel.lastContents, viewModel.lastMessage)
      return
    }

    loadData(nil, nil, true)
  }
}

extension AIChatViewController: UITableViewDelegate, UITableViewDataSource {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.aiChatData?.count ?? 0
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    72
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard indexPath.row < viewModel.aiChatData?.count ?? 0,
          let model = viewModel.aiChatData?[indexPath.row] else {
      return UITableViewCell()
    }

    let cell = tableView.dequeueReusableCell(withIdentifier: "\(AIChatTableViewCell.self)", for: indexPath) as! AIChatTableViewCell
    cell.setModel(model)
    cell.delegate = self
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let aiChatData = viewModel.aiChatData,
          indexPath.row < aiChatData.count else {
      return
    }

    if let text = aiChatData[indexPath.row].contentTitle {
      delegate?.didClickMessageItem(text)
    }
  }
}

extension AIChatViewController: AIChatTableViewCellDelegate {
  public func didClickEditButton(_ text: String?) {
    delegate?.didClickEditButton(text)
  }
}
