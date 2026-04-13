// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseAIRobotBindController: NEContactBaseViewController, UITableViewDelegate, UITableViewDataSource {
  // MARK: - 属性

  public let viewModel = AIRobotBindViewModel()

  /// 扫码解析出来的 qrCode（二维码 UUID，有效期 300s）
  public var qrCode: String = ""

  // MARK: - 扫码结果解析

  /// 解析扫码 JSON 字符串，返回 qrCode；失败或已过期时返回 nil 并通过 errorMessage 传出提示
  /// JSON 格式：{"qrCode":"...","expireAt":1774946965000}（expireAt 单位：毫秒）
  public static func parseQrCodeJSON(_ jsonString: String) -> (qrCode: String?, errorMessage: String?) {
    guard let data = jsonString.data(using: .utf8),
          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let code = dict["qrCode"] as? String, !code.isEmpty else {
      return (nil, nil) // 非绑定机器人二维码，忽略
    }
    // 校验过期时间（expireAt 单位毫秒）
    if let expireAt = dict["expireAt"] as? TimeInterval {
      let expireDate = Date(timeIntervalSince1970: expireAt / 1000)
      if expireDate < Date() {
        return (nil, "二维码已过期")
      }
    }
    return (code, nil)
  }

  /// 选中的机器人 index
  public var selectedIndex: Int = -1

  // MARK: - Views

  /// "新建机器人"区域（顶部卡片）
  public lazy var createBotView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white
    return v
  }()

  public lazy var createBotIconView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .ne_normalTheme
    v.clipsToBounds = true
    return v
  }()

  public lazy var createBotPlusH: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white
    return v
  }()

  public lazy var createBotPlusV: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white
    return v
  }()

  public lazy var createBotLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = localizable("create_ai_robot")
    l.font = .systemFont(ofSize: 14)
    l.textColor = .ne_darkText
    return l
  }()

  public lazy var createBotSeparator: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .ne_greyLine
    return v
  }()

  /// "新建机器人"行右侧箭头（Normal 皮肤显示，Fun 皮肤隐藏）
  public lazy var createBotArrowView: UIImageView = {
    let iv = UIImageView(image: coreLoader.loadImage("arrow_right"))
    iv.translatesAutoresizingMaskIntoConstraints = false
    iv.contentMode = .scaleAspectFit
    iv.isHidden = true // 默认隐藏，Normal 子类中设为可见
    return iv
  }()

  /// "选择已有的机器人"标签
  public lazy var sectionLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.text = localizable("ai_robot_bind_select_hint")
    l.font = .systemFont(ofSize: 14)
    l.textColor = .ne_emptyTitleColor
    return l
  }()

  /// 机器人列表
  public lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .plain)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.backgroundColor = .clear
    tv.separatorStyle = .none
    tv.delegate = self
    tv.dataSource = self
    tv.estimatedRowHeight = 0
    tv.estimatedSectionHeaderHeight = 0
    tv.estimatedSectionFooterHeight = 0
    if #available(iOS 15.0, *) {
      tv.sectionHeaderTopPadding = 0
    }
    return tv
  }()

  // MARK: - 生命周期

  override open func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("ai_robot_bind_title")
    navigationView.moreButton.isHidden = true
    view.backgroundColor = pageBackgroundColor()
    // viewDidLoad 只做 UI 搭建，数据加载统一放在 viewWillAppear
    setupBindUI()
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // 无网络时仅提示，不发起请求
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    // 在 viewDidAppear（转场动画完成后）加载数据，避免 SDK 调用与页面转场动画争夺主线程
    // 保证首次进入 / 从创建页返回 / VC 实例被 Router 复用时，均只发起一次网络请求
    loadData()
  }

  // MARK: - 数据加载

  open func loadData() {
    viewModel.loadBots { [weak self] error in
      guard let strongSelf = self else { return }
      let update = {
        strongSelf.view.isUserInteractionEnabled = true
        if let error = error {
          strongSelf.showToast(robotErrorMessage(error))
          return
        }
        if let prev = strongSelf.viewModel.previousBoundAccid, !prev.isEmpty {
          strongSelf.selectedIndex = strongSelf.viewModel.bots.firstIndex(where: { $0.accid == prev }) ?? -1
        }
        strongSelf.tableView.reloadData()
      }
      if Thread.isMainThread {
        update()
      } else {
        DispatchQueue.main.async { update() }
      }
    }
  }

  // MARK: - UI 构建

  open func setupBindUI() {
    // "新建机器人" 区域
    view.addSubview(createBotView)
    NSLayoutConstraint.activate([
      createBotView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      createBotView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: createBotHorizontalMargin()),
      createBotView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -createBotHorizontalMargin()),
      createBotView.heightAnchor.constraint(equalToConstant: createBotRowHeight()),
    ])
    setupCreateBotViewStyle()

    // 图标容器
    createBotView.addSubview(createBotIconView)
    NSLayoutConstraint.activate([
      createBotIconView.leftAnchor.constraint(equalTo: createBotView.leftAnchor, constant: 16),
      createBotIconView.centerYAnchor.constraint(equalTo: createBotView.centerYAnchor),
      createBotIconView.widthAnchor.constraint(equalToConstant: 36),
      createBotIconView.heightAnchor.constraint(equalToConstant: 36),
    ])
    setupCreateBotIconStyle()

    // "+" 横线
    createBotIconView.addSubview(createBotPlusH)
    NSLayoutConstraint.activate([
      createBotPlusH.centerXAnchor.constraint(equalTo: createBotIconView.centerXAnchor),
      createBotPlusH.centerYAnchor.constraint(equalTo: createBotIconView.centerYAnchor),
      createBotPlusH.widthAnchor.constraint(equalToConstant: 14),
      createBotPlusH.heightAnchor.constraint(equalToConstant: 1.5),
    ])

    // "+" 竖线
    createBotIconView.addSubview(createBotPlusV)
    NSLayoutConstraint.activate([
      createBotPlusV.centerXAnchor.constraint(equalTo: createBotIconView.centerXAnchor),
      createBotPlusV.centerYAnchor.constraint(equalTo: createBotIconView.centerYAnchor),
      createBotPlusV.widthAnchor.constraint(equalToConstant: 1.5),
      createBotPlusV.heightAnchor.constraint(equalToConstant: 14),
    ])

    // 右侧箭头（Normal 皮肤显示，Fun 皮肤隐藏）
    createBotView.addSubview(createBotArrowView)
    NSLayoutConstraint.activate([
      createBotArrowView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -22),
      createBotArrowView.centerYAnchor.constraint(equalTo: createBotView.centerYAnchor),
      createBotArrowView.widthAnchor.constraint(equalToConstant: 14),
      createBotArrowView.heightAnchor.constraint(equalToConstant: 14),
    ])

    // 文字
    createBotView.addSubview(createBotLabel)
    NSLayoutConstraint.activate([
      createBotLabel.leftAnchor.constraint(equalTo: createBotIconView.rightAnchor, constant: 12),
      createBotLabel.centerYAnchor.constraint(equalTo: createBotView.centerYAnchor),
      createBotLabel.rightAnchor.constraint(equalTo: createBotArrowView.leftAnchor, constant: -8),
    ])

    // 分割线
    createBotView.addSubview(createBotSeparator)
    NSLayoutConstraint.activate([
      createBotSeparator.leftAnchor.constraint(equalTo: createBotView.leftAnchor),
      createBotSeparator.rightAnchor.constraint(equalTo: createBotView.rightAnchor),
      createBotSeparator.bottomAnchor.constraint(equalTo: createBotView.bottomAnchor),
      createBotSeparator.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCreateBot))
    createBotView.addGestureRecognizer(tap)

    // 分区块（6pt 高灰色）
    let dividerBlock = UIView()
    dividerBlock.translatesAutoresizingMaskIntoConstraints = false
    dividerBlock.backgroundColor = pageBackgroundColor()
    view.addSubview(dividerBlock)
    NSLayoutConstraint.activate([
      dividerBlock.topAnchor.constraint(equalTo: createBotView.bottomAnchor),
      dividerBlock.leftAnchor.constraint(equalTo: view.leftAnchor),
      dividerBlock.rightAnchor.constraint(equalTo: view.rightAnchor),
      dividerBlock.heightAnchor.constraint(equalToConstant: dividerBlockHeight()),
    ])

    // 机器人列表（顶部直接接 dividerBlock，section header 承载"选择已有的机器人"标签）
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: dividerBlock.bottomAnchor),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    tableView.register(NEBaseAIRobotBindCell.self, forCellReuseIdentifier: "\(NEBaseAIRobotBindCell.self)")
  }

  // MARK: - 子类 override 点

  open func pageBackgroundColor() -> UIColor { .funContactNavigationBackgroundColor }
  open func createBotHorizontalMargin() -> CGFloat { 0 }
  open func createBotRowHeight() -> CGFloat { 60 }
  open func bindRowHeight() -> CGFloat { 60 }
  open func confirmButtonColor() -> UIColor { .normalContactThemeColor }
  /// 分区灰块高度（Normal: 6，Fun: 8）
  open func dividerBlockHeight() -> CGFloat { 6 }
  /// "选择已有机器人"标签字重
  open func sectionLabelFont() -> UIFont { .systemFont(ofSize: 14) }
  /// "选择已有机器人"标签颜色
  open func sectionLabelColor() -> UIColor { .ne_emptyTitleColor }
  /// section header 高度（含上下内边距，默认 44）
  open func sectionHeaderHeight() -> CGFloat { 44 }

  open func setupCreateBotViewStyle() {
    // Normal/Fun 可 override（如设置圆角）
  }

  open func setupCreateBotIconStyle() {
    createBotIconView.backgroundColor = .ne_normalTheme
    createBotIconView.layer.cornerRadius = 18
  }

  // MARK: - UITableViewDataSource / Delegate

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.bots.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "\(NEBaseAIRobotBindCell.self)", for: indexPath) as! NEBaseAIRobotBindCell
    let bot = viewModel.bots[indexPath.row]
    cell.configure(bot: bot, isSelected: indexPath.row == selectedIndex)
    return cell
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    bindRowHeight()
  }

  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    // 每次返回独立的 header 实例，避免复用同一 sectionLabel 导致约束累积
    let header = UIView()
    header.backgroundColor = .white

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("ai_robot_bind_select_hint")
    label.font = sectionLabelFont()
    label.textColor = sectionLabelColor()
    header.addSubview(label)
    NSLayoutConstraint.activate([
      label.leftAnchor.constraint(equalTo: header.leftAnchor, constant: 16),
      label.rightAnchor.constraint(equalTo: header.rightAnchor, constant: -16),
      label.centerYAnchor.constraint(equalTo: header.centerYAnchor),
    ])
    return header
  }

  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    sectionHeaderHeight()
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard indexPath.row < viewModel.bots.count else { return }
    let bot = viewModel.bots[indexPath.row]

    // 非首次扫码 + 选择了与上次不同的机器人，弹二次确认
    let prevAccid = viewModel.previousBoundAccid ?? ""
    let isSameAsPrev = !prevAccid.isEmpty && bot.accid == prevAccid

    if !prevAccid.isEmpty, !isSameAsPrev {
      // 换绑确认：复用相同弹窗
      showBindConfirmAlert(bot: bot, isRebind: true)
    } else {
      showBindConfirmAlert(bot: bot, isRebind: false)
    }
  }

  // MARK: - Actions

  open func didTapCreateBot() {
    // 数量上限检查
    let maxCount = AIRobotViewModel.maxRobotCount
    if viewModel.bots.count >= maxCount {
      showToast(localizable("ai_robot_exceed_limit"))
      return
    }
    // 网络检查
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    let defaultName = "Bot_Claw"
    Router.shared.use(ContactCreateAIRobotRouter,
                      parameters: ["nav": navigationController as Any,
                                   "animated": true,
                                   "defaultName": defaultName,
                                   // 将当前绑定页的 qrCode 传给创建页，创建成功后自动绑定
                                   "autoBindQrCode": qrCode as Any,
                                   // 创建+绑定成功后，需要将自身（绑定页）从导航栈移除
                                   "autoBindSourceVC": self],
                      closure: nil)
  }

  /// 展示绑定确认弹窗
  /// - Parameter bot: 选中的机器人
  /// - Parameter isRebind: 是否为换绑（UI 弹窗内容相同，仅作语义区分）
  open func showBindConfirmAlert(bot: V2NIMUserAIBot, isRebind: Bool) {
    let overlay = UIView(frame: UIScreen.main.bounds)
    overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    overlay.tag = 9921

    let alertView = UIView()
    alertView.translatesAutoresizingMaskIntoConstraints = false
    alertView.backgroundColor = .white
    alertView.layer.cornerRadius = 14
    alertView.clipsToBounds = true
    overlay.addSubview(alertView)

    NSLayoutConstraint.activate([
      alertView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      alertView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
      alertView.widthAnchor.constraint(equalToConstant: 270),
      alertView.heightAnchor.constraint(equalToConstant: 160),
    ])

    // 标题
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = localizable("ai_robot_bind_confirm_title")
    titleLabel.font = UIFont(name: "PingFangSC-Regular", size: 17) ?? .systemFont(ofSize: 17)
    titleLabel.textColor = .black
    titleLabel.textAlignment = .center
    alertView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 19),
      titleLabel.leftAnchor.constraint(equalTo: alertView.leftAnchor, constant: 16),
      titleLabel.rightAnchor.constraint(equalTo: alertView.rightAnchor, constant: -16),
      titleLabel.heightAnchor.constraint(equalToConstant: 22),
    ])

    // 描述
    let descLabel = UILabel()
    descLabel.translatesAutoresizingMaskIntoConstraints = false
    descLabel.text = localizable("ai_robot_bind_confirm_desc")
    descLabel.font = UIFont(name: "PingFangSC-Regular", size: 13) ?? .systemFont(ofSize: 13)
    descLabel.textColor = .ne_darkText
    descLabel.textAlignment = .center
    descLabel.numberOfLines = 0
    alertView.addSubview(descLabel)
    NSLayoutConstraint.activate([
      descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      descLabel.leftAnchor.constraint(equalTo: alertView.leftAnchor, constant: 16),
      descLabel.rightAnchor.constraint(equalTo: alertView.rightAnchor, constant: -16),
    ])

    // 水平分割线
    let hLine = UIView()
    hLine.translatesAutoresizingMaskIntoConstraints = false
    hLine.backgroundColor = UIColor(red: 0, green: 0, blue: 80 / 255.0, alpha: 0.05)
    alertView.addSubview(hLine)
    NSLayoutConstraint.activate([
      hLine.leftAnchor.constraint(equalTo: alertView.leftAnchor),
      hLine.rightAnchor.constraint(equalTo: alertView.rightAnchor),
      hLine.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -44),
      hLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    // 取消按钮
    let cancelBtn = UIButton(type: .custom)
    cancelBtn.translatesAutoresizingMaskIntoConstraints = false
    cancelBtn.setTitle(commonLocalizable("cancel"), for: .normal)
    cancelBtn.setTitleColor(.ne_greyText, for: .normal)
    cancelBtn.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 17) ?? .systemFont(ofSize: 17)
    alertView.addSubview(cancelBtn)
    NSLayoutConstraint.activate([
      cancelBtn.leftAnchor.constraint(equalTo: alertView.leftAnchor),
      cancelBtn.bottomAnchor.constraint(equalTo: alertView.bottomAnchor),
      cancelBtn.widthAnchor.constraint(equalTo: alertView.widthAnchor, multiplier: 0.5, constant: -0.25),
      cancelBtn.heightAnchor.constraint(equalToConstant: 44),
    ])

    // 竖向分割线
    let vLine = UIView()
    vLine.translatesAutoresizingMaskIntoConstraints = false
    vLine.backgroundColor = UIColor(red: 0, green: 0, blue: 80 / 255.0, alpha: 0.05)
    alertView.addSubview(vLine)
    NSLayoutConstraint.activate([
      vLine.leftAnchor.constraint(equalTo: cancelBtn.rightAnchor),
      vLine.bottomAnchor.constraint(equalTo: alertView.bottomAnchor),
      vLine.widthAnchor.constraint(equalToConstant: 0.5),
      vLine.heightAnchor.constraint(equalToConstant: 44),
    ])

    // 确认按钮
    let confirmBtn = UIButton(type: .custom)
    confirmBtn.translatesAutoresizingMaskIntoConstraints = false
    confirmBtn.setTitle(commonLocalizable("sure"), for: .normal)
    confirmBtn.setTitleColor(confirmButtonColor(), for: .normal)
    confirmBtn.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 17) ?? .systemFont(ofSize: 17)
    alertView.addSubview(confirmBtn)
    NSLayoutConstraint.activate([
      confirmBtn.rightAnchor.constraint(equalTo: alertView.rightAnchor),
      confirmBtn.bottomAnchor.constraint(equalTo: alertView.bottomAnchor),
      confirmBtn.widthAnchor.constraint(equalTo: alertView.widthAnchor, multiplier: 0.5, constant: -0.25),
      confirmBtn.heightAnchor.constraint(equalToConstant: 44),
    ])

    // 添加到 keyWindow
    if let window = UIApplication.shared.keyWindow {
      window.addSubview(overlay)
      overlay.frame = window.bounds
    } else {
      view.addSubview(overlay)
    }

    cancelBtn.addTarget(self, action: #selector(dismissBindAlert), for: .touchUpInside)

    // 将待绑定 bot 暂存到属性，confirmBind 直接读取
    pendingBot = bot
    confirmBtn.addTarget(self, action: #selector(confirmBind), for: .touchUpInside)
  }

  /// 暂存待确认绑定的机器人（弹窗确认期间有效）
  private var pendingBot: V2NIMUserAIBot?

  open func dismissBindAlert() {
    pendingBot = nil
    removeBindAlert()
  }

  open func confirmBind() {
    removeBindAlert()
    guard let bot = pendingBot else { return }
    pendingBot = nil
    // 网络检查
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    performBind(bot: bot)
  }

  private func removeBindAlert() {
    let window = UIApplication.shared.keyWindow ?? view
    window?.subviews.first(where: { $0.tag == 9921 })?.removeFromSuperview()
  }

  /// 执行绑定
  open func performBind(bot: V2NIMUserAIBot) {
    view.isUserInteractionEnabled = false
    viewModel.bindBot(bot, qrCode: qrCode) { [weak self] error in
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.view.isUserInteractionEnabled = true
        if let error = error {
          self.showToast(robotErrorMessage(error))
          return
        }
        // 绑定成功：进入机器人名片页，当前绑定页关闭
        let nav = self.navigationController
        // 移除自身
        var vcs = nav?.viewControllers ?? []
        vcs.removeAll(where: { $0 === self })
        nav?.setViewControllers(vcs, animated: false)
        // 跳转详情页
        Router.shared.use(ContactAIRobotDetailRouter,
                          parameters: ["nav": nav as Any,
                                       "bot": bot,
                                       "animated": true],
                          closure: nil)
      }
    }
  }
}
