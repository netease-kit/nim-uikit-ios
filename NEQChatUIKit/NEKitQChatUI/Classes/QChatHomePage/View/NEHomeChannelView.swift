
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM
import MJRefresh
import NIMSDK

class NEHomeChannelView: UIView {
  private let className = "NEHomeChannelView"
  typealias CallBack = () -> Void
  typealias SelectedChannelBlock = (_ channel: ChatChannel?) -> Void
  public var channelViewModel = QChatChannelViewModel()
  public var channelArray = [ChatChannel]()

  public var setUpBlock: CallBack?
  public var addChannelBlock: CallBack?
  public var selectedChannelBlock: SelectedChannelBlock?
  public var hasMore = true
  public var nextTimeTag: TimeInterval = 0

  public var viewmodel: CreateServerViewModel?

  public var qchatServerModel: QChatServer? {
    didSet {
      hasMore = true
      nextTimeTag = 0
      self.titleLable.text = qchatServerModel?.name
      channelArray.removeAll()
      requestData(timeTag: 0)
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ rect: CGRect) {
    addCorner(conrners: [.topLeft, .topRight], radius: 8)
  }

  func setupSubviews() {
    backgroundColor = .white

    addSubview(titleLable)
    addSubview(setUpBtn)
    addSubview(divideLineView)
    addSubview(addChannelBtn)
    addSubview(subTitleLable)
    addSubview(tableView)
    addSubview(emptyView)

    NSLayoutConstraint.activate([
      titleLable.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      titleLable.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      titleLable.rightAnchor.constraint(equalTo: rightAnchor, constant: -30),

    ])

    NSLayoutConstraint.activate([
      setUpBtn.centerYAnchor.constraint(equalTo: titleLable.centerYAnchor),
      setUpBtn.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
    ])

    NSLayoutConstraint.activate([
      divideLineView.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: 16),
      divideLineView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      divideLineView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
      divideLineView.heightAnchor.constraint(equalToConstant: 1),
    ])

    NSLayoutConstraint.activate([
      subTitleLable.topAnchor.constraint(equalTo: divideLineView.bottomAnchor, constant: 16),
      subTitleLable.leftAnchor.constraint(equalTo: leftAnchor, constant: 18),
    ])

    NSLayoutConstraint.activate([
      addChannelBtn.centerYAnchor.constraint(equalTo: subTitleLable.centerYAnchor),
      addChannelBtn.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
    ])

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: subTitleLable.bottomAnchor, constant: 8),
      tableView.leftAnchor.constraint(equalTo: leftAnchor),
      tableView.rightAnchor.constraint(equalTo: rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: subTitleLable.bottomAnchor, constant: 8),
      emptyView.leftAnchor.constraint(equalTo: leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: rightAnchor),
      emptyView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @objc func updateChannelList() {
    requestData(timeTag: 0)
  }

  public func channelChange(noticeInfo: NIMQChatSystemNotification) {
    switch noticeInfo.type {
    case .channelRemove, .channelCreate, .channelUpdate:
      if noticeInfo.serverId == qchatServerModel?.serverId {
        requestData(timeTag: 0)
      }
    case .updateChannelCategoryBlackWhiteRole:
      if noticeInfo.serverId == qchatServerModel?.serverId,
         (noticeInfo.toAccids?.contains(IMKitLoginManager.instance.imAccid)) != nil {
        requestData(timeTag: 0)
      }

    default:
      print("")
    }
  }

  // MARK: lazy method

  private lazy var titleLable: UILabel = {
    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.textColor = UIColor.ne_darkText
    title.font = DefaultTextFont(16)
    return title
  }()

  private lazy var setUpBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "home_setupServer"), for: .normal)
    button.setImage(UIImage.ne_imageNamed(name: "home_setupServer"), for: .highlighted)
    button.addTarget(self, action: #selector(setupBtnClick), for: .touchUpInside)
    return button
  }()

  private lazy var divideLineView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_greyLine
    return view
  }()

  private lazy var subTitleLable: UILabel = {
    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.text = "消息频道"
    title.textColor = PlaceholderTextColor
    title.font = DefaultTextFont(14)
    return title
  }()

  private lazy var addChannelBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "home_addChannel"), for: .normal)
    button.setImage(UIImage.ne_imageNamed(name: "home_addChannel"), for: .highlighted)
    button.addTarget(self, action: #selector(addChannelBtnClick), for: .touchUpInside)
    return button
  }()

  lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      NEHomeChannelCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(NEHomeChannelCell.self))"
    )
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    let mjfooter = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    mjfooter.stateLabel?.isHidden = true
    tableView.mj_footer = mjfooter
    return tableView
  }()

  private lazy var emptyView: EmptyDataView = {
    let view = EmptyDataView(
      imageName: "channel_noMoreData",
      content: "该服务器下暂无频道",
      frame: tableView.bounds
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()
}

extension NEHomeChannelView {
  @objc func setupBtnClick(sender: UIButton) {
    if setUpBlock != nil {
      setUpBlock!()
    }
  }

  @objc func addChannelBtnClick(sender: UIButton) {
    if addChannelBlock != nil {
      addChannelBlock!()
    }
  }

  @objc func loadMoreData() {
    requestData(timeTag: nextTimeTag)
    tableView.mj_footer?.endRefreshing()
  }

  public func requestData(timeTag: TimeInterval) {
    if timeTag != 0, !hasMore {
      // 上拉加载无多余数据，无需请求
      return
    }

    guard let serverId = qchatServerModel?.serverId else { return }
    let param = QChatGetChannelsByPageParam(timeTag: timeTag, serverId: serverId)
    channelViewModel.getChannelsByPage(parameter: param) { [self] error, result in
      if error == nil {
        guard let dataArray = result?.channels else { return }
        if timeTag == 0 {
          self.channelArray.removeAll()
          self.channelArray = dataArray
          if dataArray.isEmpty {
            emptyView.setttingContent(content: "该服务器下暂无频道")
            emptyView.setEmptyImage(name: "channel_noMoreData")
            emptyView.isHidden = false
          } else {
            emptyView.isHidden = true
          }

        } else {
          self.channelArray += dataArray
        }
        self.hasMore = result?.hasMore ?? false
        self.nextTimeTag = result?.nextTimetag ?? 0
        tableView.reloadData()
      } else {
        NELog.errorLog(self.className, desc: "❌getChannelsByPage failed,error = \(error!)")
      }
    }
  }

  public func showEmptyServerView() {
    titleLable.isHidden = true
    setUpBtn.isHidden = true
    divideLineView.isHidden = true
    subTitleLable.isHidden = true
    addChannelBtn.isHidden = true
    emptyView.isHidden = false
    emptyView.setttingContent(content: "暂无服务器，\n赶紧去添加心仪的服务器吧")
    emptyView.setEmptyImage(name: "servers_noMore")
  }

  public func dismissEmptyView() {
    titleLable.isHidden = false
    setUpBtn.isHidden = false
    divideLineView.isHidden = false
    subTitleLable.isHidden = false
    addChannelBtn.isHidden = false
    emptyView.isHidden = true
  }
}

extension NEHomeChannelView: UITableViewDataSource, UITableViewDelegate {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    channelArray.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(NEHomeChannelCell.self))",
      for: indexPath
    ) as! NEHomeChannelCell
    if indexPath.row < channelArray.count {
      let channel = channelArray[indexPath.row]
      cell.channelModel = channel
      if let sid = qchatServerModel?.serverId, let cid = channel.channelId,
         let unreadCount = viewmodel?.getChannelUnreadCount(
           sid,
           cid
         ) {
        cell.redAngleView.isHidden = false
        if unreadCount <= 0 {
          cell.redAngleView.isHidden = true
        } else if unreadCount <= 99 {
          cell.redAngleView.text = "\(unreadCount)"
        } else {
          cell.redAngleView.text = "99+"
        }
      } else {
        cell.redAngleView.isHidden = true
      }
    }
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let block = selectedChannelBlock, channelArray.count > 0 {
      block(channelArray[indexPath.row])
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    32
  }
}
