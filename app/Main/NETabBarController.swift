// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEAdaptiveUIKit
import NEBaseUIKit
import NEChatKit
import NEChatUIKit
import NEContactUIKit
import NEConversationUIKit
import NELocalConversationUIKit
import NIMSDK
import ObjectiveC
import UIKit

/// Route root selections into an already prepared detail column before UIKit
/// starts a push transition. Adaptive shell pages are laid out before the push; legacy presentation keeps the old push.

private final class NEAdaptiveDemoNavigationController: NENavigationController {
  var presentSectionChild: ((UIViewController, Bool) -> Bool)?
  var prepareDetailPage: ((UIViewController) -> Void)?
  /// Forward selection is presented as a modal by the UIKit router. In compact
  /// Duo mode keep that modal inside this navigation container so it cannot
  /// cover the trailing tool rail/camera area. Other modal pages retain their
  /// existing presentation style.
  var isCompactAdaptiveLayout: (() -> Bool)?
  /// 详情栈回到根页面时的回调（用于折叠态恢复列表）。
  var onReturnToRoot: (() -> Void)?

  /// 呈现/关闭后通知外壳重排：折叠时据此收起侧栏，避免压在呈现页上。
  static let presentationDidChange = Notification.Name("NEAdaptivePresentationDidChange")

  override func present(_ viewControllerToPresent: UIViewController,
                        animated flag: Bool,
                        completion: (() -> Void)? = nil) {
    // 官方指引：presented 页面整窗展示，紧凑态也不再把选择页压进单栏容器；
    // 折叠区与安全区由系统负责避让。
    super.present(viewControllerToPresent, animated: flag) { [weak self] in
      completion?()
      _ = self
      NotificationCenter.default.post(name: Self.presentationDidChange, object: nil)
    }
  }

  override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    super.dismiss(animated: flag) { [weak self] in
      completion?()
      _ = self
      NotificationCenter.default.post(name: Self.presentationDidChange, object: nil)
    }
  }
  /// A detail page is already inside the shell's final right column. Keeping
  /// that push synchronous prevents UIKit from animating a full-width page
  /// into the column and then re-laying it out during the transition.
  var suppressDetailPushAnimation: (() -> Bool)?

  /// 页面的返回按钮由页面自己的 NENavigationView 绘制，不看栈深度；
  /// 这里按"是否导航根"统一显隐：根页面无返回，更深页面有返回。
  private func updateBackButtonsForStack() {
    for (index, page) in viewControllers.enumerated() {
      guard page.isViewLoaded else { continue }
      setBackButton(in: page.view, hidden: index == 0)
    }
  }

  private func setBackButton(in view: UIView, hidden: Bool) {
    if let button = view as? UIButton, button.accessibilityIdentifier == "id.backArrow" {
      button.isHidden = hidden
      return
    }
    for child in view.subviews { setBackButton(in: child, hidden: hidden) }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateBackButtonsForStack()
    // 页面可能在入栈前按别的容器尺寸创建；这里统一收敛到导航自身 bounds，
    // 否则换成 arrangement / tab 等容器后会出现"内容被压成一小块"。
    // 页面的 view 挂在 UINavigationTransitionView / Wrapper 里，父视图不是本导航，
    // 因此不能用 superview 判断；直接按导航 bounds 收敛尺寸。
    guard let top = topViewController else { return }
    let target = view.bounds
    if top.view.frame != target {
      top.view.frame = target
      top.view.setNeedsLayout()
      top.view.layoutIfNeeded()
    }
  }

  override func popViewController(animated: Bool) -> UIViewController? {
    let popped = super.popViewController(animated: animated)
    if viewControllers.count == 1 { onReturnToRoot?() }
    return popped
  }

  override func pushViewController(_ viewController: UIViewController, animated: Bool) {
    if !viewControllers.isEmpty,
       presentSectionChild?(viewController, animated) == true {
      return
    }
    // 详情栈自身的一级页面同样只占一层：路由有时直接把页面推到详情导航上，
    // 不经过外壳的 presentSectionChild，这里按页面身份标识兜住重复入栈。
    if !viewControllers.isEmpty {
      if viewController.restorationIdentifier == nil { viewController.loadViewIfNeeded() }
      if let identity = viewController.restorationIdentifier {
        if let existing = viewControllers.first(where: { $0 !== viewController && $0.restorationIdentifier == identity }) {
          popToViewController(existing, animated: animated)
          return
        }
        if let top = viewControllers.last, top.restorationIdentifier != nil {
          var stack = viewControllers
          stack[stack.count - 1] = viewController
          setViewControllers(stack, animated: false)
          return
        }
      }
    }
    let suppressAnimation = suppressDetailPushAnimation?() ?? false
    let shouldAnimate = animated && !suppressAnimation
    if suppressAnimation {
      prepareDetailPage?(viewController)
    }
    super.pushViewController(viewController, animated: shouldAnimate)
  }
}

private var adaptivePagingSafeAreaKey: UInt8 = 0


class NETabBarController: UITabBarController {
  private(set) var adaptiveShell: NEAdaptiveShellViewController?
  /// 阶段 2 旁路装配：系统 split view 容器，开关控制。
  private(set) var splitAssembly: NEAdaptiveSplitAssembly?
  private var chat: UIViewController?
  private var contactVC: NEBaseContactViewController?
  private var meVC = MeViewController()
  private var sessionUnreadCount = 0
  private var sessionUnreadFilter: V2NIMConversationFilter?
  private var localSessionUnreadFilter: V2NIMLocalConversationFilter?
  private var contactUnreadCount = 0

  /// 是通过切换UI风格触发，需要重置会话是否同步完成标志位，因为不是首次登录，已经同步过，同步完成回调不会再触发，正常单皮肤可忽略此逻辑
  var isChangeUIType = false {
    didSet {}
  }

  init(_ isChangeUI: Bool) {
    isChangeUIType = isChangeUI
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // MARK: - 自绘侧栏（UI 稿：图标 + 文字 + 小红点 + 返回）

  private let sideRail = UIView()
  private var sideRailButtons: [UIControl] = []
  private var railBadgeDots: [UIView] = []
  private var railImages: [UIImage?] = []
  private var railSelectedImages: [UIImage?] = []
  private var arrangementDetail: UINavigationController?
  private var arrangementPrimary: UINavigationController?
  private var regularControllers: [UIViewController] = []
  private var compactControllers: [UIViewController] = []
  private var isCompactLayout = false
  private weak var arrangementController: UIViewController?
  private var sideRailReady = false

  private static let railWidth: CGFloat = 72
  private static let railTopInset: CGFloat = 12

  /// 折叠用 overlay（单栏叠加），展开用 split（左右并排）。
  /// 只切形态、不换导航栈，避免页面被重新挂载后丢失布局。
  private func applyArrangement(compact: Bool) {
    guard #available(iOS 27.1, *),
          let arrangement = arrangementController as? UIArrangementViewController else { return }
    if compact {
      // 折叠：只保留主列，聊天在主导航里 push（split/overlay 在竖屏都会上下分配）
      if let detail = arrangementDetail, let page = detail.viewControllers.last,
         detail.viewControllers.count > 1 {
        detail.setViewControllers([detail.viewControllers[0]], animated: false)
        arrangementPrimary?.pushViewController(page, animated: false)
      }
      arrangement.setViewController(nil, for: .secondary)
    } else if let detail = arrangementDetail {
      // 展开：把主列里的聊天页搬回 secondary
      if let primary = arrangementPrimary, primary.viewControllers.count > 1 {
        let page = primary.viewControllers.last!
        primary.setViewControllers([primary.viewControllers[0]], animated: false)
        detail.setViewControllers([detail.viewControllers[0], page], animated: false)
      }
      arrangement.setViewController(detail, for: .secondary)
      var split = UISplitArrangement()
      split.axes([.horizontal, .vertical])
      var props = split.defaultViewProperties
      var width = UISplitArrangement.DimensionRange()
      width.minimum = .automatic
      width.preferred = .absolute(320)
      width.maximum = .absolute(360)
      props.width = width
      split.setViewProperties(props, for: .primary)
      arrangement.updateArrangement(split, animated: false)
    }
  }

  private func installSideRail(titles: [String], images: [UIImage?], selectedImages: [UIImage?]) {
    guard !sideRailReady else { return }
    sideRailReady = true
    railImages = images
    railSelectedImages = selectedImages
    sideRail.frame = CGRect(x: view.bounds.width - Self.railWidth, y: Self.railTopInset,
                            width: Self.railWidth, height: view.bounds.height - Self.railTopInset)
    sideRail.backgroundColor = NEStyleManager.instance.isNormalStyle()
      ? UIColor(hexString: "#F6F8FA") : .funContactBackgroundColor
    view.addSubview(sideRail)

    var items: [UIView] = []
    let back = UIButton(type: .system)
    var backConfig = UIButton.Configuration.plain()
    backConfig.image = UIImage(systemName: "chevron.left")
    backConfig.baseForegroundColor = NEStyleManager.instance.isNormalStyle()
      ? UIColor(hexString: "#333333") : .ne_funTheme
    back.configuration = backConfig
    back.tintColor = NEStyleManager.instance.isNormalStyle() ? UIColor(hexString: "#333333") : .ne_funTheme
    back.addTarget(self, action: #selector(sideRailBackTapped), for: .touchUpInside)
    sideRail.addSubview(back)
    items.append(back)

    for index in titles.indices {
      let button = UIButton(type: .custom)
      var config = UIButton.Configuration.plain()
      config.image = images[index]
      config.imagePlacement = .top
      config.imagePadding = 4
      config.contentInsets = .init(top: 4, leading: 0, bottom: 4, trailing: 0)
      config.title = titles[index]
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var outgoing = incoming
        outgoing.font = .systemFont(ofSize: 11, weight: .medium)
        return outgoing
      }
      config.baseForegroundColor = index == 0
        ? (NEStyleManager.instance.isNormalStyle() ? UIColor(hexString: "#337EFF") : .ne_funTheme)
        : UIColor(hexString: "#999999")
      button.configuration = config
      button.tag = index
      button.addTarget(self, action: #selector(sideRailItemTapped(_:)), for: .touchUpInside)
      sideRail.addSubview(button)
      items.append(button)

      let dot = UIView()
      dot.backgroundColor = UIColor(hexString: "#FF3B30")
      dot.layer.cornerRadius = 4
      dot.isHidden = true
      dot.frame = CGRect(x: 0, y: 0, width: 8, height: 8)
      sideRail.addSubview(dot)
      railBadgeDots.append(dot)
    }
    sideRailButtons = items.compactMap { $0 as? UIControl }
    layoutSideRail()
    updateRailSelection(selectedIndex)
  }

  private var lastRailSelection = -1
  private var lastArrangementContentSize: CGSize = .zero

  /// 统一刷新侧栏选中态（颜色 + 选中图标），首次安装与切换都要走这里
  private func updateRailSelection(_ index: Int) {
    guard sideRailButtons.count > 1 else { return }
    lastRailSelection = index
    let accent = NEStyleManager.instance.isNormalStyle() ? UIColor(hexString: "#337EFF") : UIColor.ne_funTheme
    for (offset, control) in sideRailButtons.enumerated() where offset > 0 {
      let itemIndex = offset - 1
      guard let button = control as? UIButton else { continue }
      let selected = itemIndex == index
      button.configuration?.baseForegroundColor = selected ? accent : UIColor(hexString: "#999999")
      if itemIndex < railImages.count {
        let image = (selected && itemIndex < railSelectedImages.count) ? railSelectedImages[itemIndex] : railImages[itemIndex]
        button.configuration?.image = image
      }
    }
  }


  private func layoutSideRail() {
    guard sideRailReady else { return }
    sideRail.frame = CGRect(x: view.bounds.width - Self.railWidth, y: Self.railTopInset,
                            width: Self.railWidth, height: view.bounds.height - Self.railTopInset)
    let itemHeight: CGFloat = 64
    let spacing: CGFloat = 8
    let backHeight: CGFloat = 44
    // 返回箭头固定在顶部，但要避开 Duo 右缘的系统状态区（时钟 / Wi-Fi 占约 100pt）
    let backY: CGFloat = 100
    if let back = sideRailButtons.first {
      back.frame = CGRect(x: 0, y: backY, width: Self.railWidth, height: backHeight)
    }
    // 三个分区整体垂直居中
    let tabCount = max(0, sideRailButtons.count - 1)
    let tabsHeight = CGFloat(tabCount) * itemHeight + CGFloat(max(0, tabCount - 1)) * spacing
    let startY = max(backY + backHeight + 12, (sideRail.bounds.height - tabsHeight) / 2)
    for offset in 0..<tabCount {
      let item = sideRailButtons[offset + 1]
      let y = startY + CGFloat(offset) * (itemHeight + spacing)
      item.frame = CGRect(x: 0, y: y, width: Self.railWidth, height: itemHeight)
      // 红点贴在图标右上角
      if railBadgeDots.indices.contains(offset) {
        railBadgeDots[offset].center = CGPoint(x: item.frame.midX + 14, y: item.frame.minY + 14)
      }
    }
  }

  @objc private func sideRailItemTapped(_ sender: UIControl) {
    selectedIndex = sender.tag
    updateRailSelection(sender.tag)
  }

  @objc private func sideRailBackTapped() {
    guard let controllers = viewControllers, controllers.indices.contains(selectedIndex) else { return }
    if #available(iOS 27.1, *), let arrangement = controllers[selectedIndex] as? UIArrangementViewController {
      (arrangement.viewController(for: .secondary) as? UINavigationController)?.popViewController(animated: true)
    } else {
      (controllers[selectedIndex] as? UINavigationController)?.popViewController(animated: true)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard sideRailReady else { return }
    layoutSideRail()
    if lastRailSelection != selectedIndex { updateRailSelection(selectedIndex) }
    if let listPage = arrangementPrimary?.topViewController {
      // 折叠：cell 按安全区（含侧栏 72pt）内缩，内容自然让出侧栏；
      // 展开：列宽已排除侧栏，关闭该内缩让 cell 铺满列宽。
      NETabBarController.updateTableContentInsets(in: listPage.view, managedByContainer: !isCompactLayout)
    }
    let compact = view.bounds.width < 600
    if compact != isCompactLayout {
      isCompactLayout = compact
      applyArrangement(compact: compact)
    }
    // 内容区收窄：右侧 72pt 给侧栏、顶部 12pt 呼吸区
    let content = CGRect(x: 0, y: Self.railTopInset,
                         width: max(0, view.bounds.width - Self.railWidth),
                         height: max(0, view.bounds.height - Self.railTopInset))
    // arrangement 由 SwiftUI 承载（UIArrangementCoreHostingView），手工改它的 frame
    // 会让内部列不刷新；这里不再插手它的尺寸，只通过安全区让页面避让侧栏。
    if let arrangement = arrangementController, lastArrangementContentSize != view.bounds.size {
      lastArrangementContentSize = view.bounds.size
      arrangement.view.setNeedsLayout()
      arrangement.view.layoutIfNeeded()
    }
    for controller in viewControllers ?? [] where controller !== arrangementController {
      if controller.view.frame != content { controller.view.frame = content }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    ContactRepo.shared.addContactListener(self)
    TeamRepo.shared.addTeamListener(self)
    // Choose the first parent before UIKit attaches any navigation controller.
    // Clearing an already attached tab array is not a synchronous detach contract.
    let useAdaptiveUIKit = NEAdaptiveDeviceGate.isFoldableDevice
      && !UserDefaults.standard.bool(forKey: "disableAdaptiveUIKit")
    let sections = setUpControllers(useAdaptiveNavigation: useAdaptiveUIKit)
    if !useAdaptiveUIKit {
      setViewControllers(sections, animated: false)
      selectedIndex = 0
    } else if #available(iOS 27.1, *), UserDefaults.standard.bool(forKey: "useArrangementAssembly") {
      // 实验：系统容器 UIArrangementViewController + 系统 tab bar
      installArrangementAssembly(sections: sections)
    } else {
      // 侧栏（UI 稿要求的竖排 tabbar + 返回）由自适应外壳提供。
      installAdaptiveShell(sections: sections)
    }

    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      LocalConversationRepo.shared.addLocalConversationListener(self)
    } else {
      ConversationRepo.shared.addConversationListener(self)
    }

    setUpSessionBadgeValue()
    setUpContactBadgeValue()

    NotificationCenter.default.addObserver(self, selector: #selector(clearValidationUnreadCount), name: NENotificationName.clearValidationMessageUnreadCount, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(changeLanguage), name: NENotificationName.changeLanguage, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(clearAdaptiveConversation), name: NENotificationName.popGroupChatVC, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(clearAdaptiveConversation), name: NENotificationName.deleteConversationNotificationName, object: nil)
  }

  @objc func changeLanguage() {
    chat?.tabBarItem.title = localizable("message")
    contactVC?.tabBarItem.title = localizable("contact")
    meVC.tabBarItem.title = localizable("mine")
    adaptiveShell?.configuration.backAccessibilityLabel = localizable("adaptive_back")
    refreshAdaptiveTabItems()
  }

  /// 左列选中高亮的唯一开关：`enabled` 由外壳按"右列是否有内容"统一驱动，
  /// 页面只负责记住自己的选中行并在开关打开时恢复。
  private func setLeftColumnSelection(enabled: Bool, in shell: NEAdaptiveShellViewController) {
    let color = enabled
      ? shell.configuration.selectedTintColor.withAlphaComponent(0.1)
      : nil
    for section in shell.sections {
      for page in section.viewControllers where page.isViewLoaded {
        (page as? NEBaseContactViewController)?.listSelectionBackgroundColor = color
        (page as? NEBaseConversationController)?.listSelectionBackgroundColor = color
        (page as? NEBaseLocalConversationController)?.listSelectionBackgroundColor = color
        (page as? MeViewController)?.listSelectionBackgroundColor = color
        // 关闭高亮时同步取消表格选中行，避免样式恢复后旧选中行又被点亮。
        if !enabled { clearTableSelection(in: page.view) }
      }
    }
  }


  /// 展开态下右列仍在展示会话时，左列当前分组保留该行（已读/@ 清除后也不移除），
  /// 关闭详情栏或折叠成单栏后释放，行为与普通手机一致。
  private func updateConversationGroupRetention(in shell: NEAdaptiveShellViewController) {
    guard let root = shell.sections.first?.viewControllers.first as? NEBaseConversationController else { return }
    let activeId = shell.conversationCoordinator.activeIntent?.parameters["conversationId"] as? String
    root.retainConversationInGroup(shell.isShowingPairedContent ? activeId : nil)
  }

  /// 递归取消所有表格的选中行（列表的 tableView 可能嵌套在容器里）。
  private func clearTableSelection(in view: UIView) {
    if let table = view as? UITableView, let selected = table.indexPathForSelectedRow {
      table.deselectRow(at: selected, animated: false)
    }
    for child in view.subviews { clearTableSelection(in: child) }
  }

  private func refreshAdaptiveTabItems() {
    guard let shell = adaptiveShell else { return }
    shell.updateRailItems()
  }

  /// 阶段 2 第 1 步：用系统 `UISplitViewController` 旁路装配「列表 + 详情」。
  /// 仅做骨架与容器切换，聊天等路由接线在后续步骤完成；开关默认关闭。
  /// 实验：系统 tab bar + UIArrangementViewController（Duo 专用容器）。
  @available(iOS 27.1, *)
  private func installArrangementAssembly(sections: [UINavigationController]) {
    guard let listSection = sections.first else { return }
    let detail = NEAdaptiveDemoNavigationController(rootViewController: makeAdaptiveEmptyDetail())
    detail.prepareDetailPage = { [weak self] page in
      self?.prepareAdaptivePage(page, paired: true, managedByContainer: true, loadView: true)
    }
    ChatRouter.setConversationPresentationHandler({ [weak self, weak detail] route, parameters in
      guard let self, let detail, let cid = parameters["conversationId"] as? String else { return false }
      let sessionId = parameters["sessionId"] as? String ?? ""
      let topicId = (parameters["topic"] as? V2NIMTopic).map { String($0.topicId) } ?? ""
      let intent = NEConversationOpenIntent(key: "\(route)|\(cid)|\(sessionId)|\(topicId)",
                                            route: route, parameters: parameters,
                                            requiresPresentationAction: parameters["anchor"] is V2NIMMessage || parameters["onReceiveNewMsgs"] != nil)
      guard let page = self.makeAdaptiveConversation(intent) else { return false }
      ChatRouter.applyPresentationParameters(intent.parameters, to: page, reload: true)
      if self.isCompactLayout {
        listSection.pushViewController(page, animated: true)
      } else {
        let placeholder = detail.viewControllers.first ?? UIViewController()
        detail.setViewControllers([placeholder, page], animated: false)
      }
      return true
    }, for: listSection)

    usesSystemTabBadges = true
    let arrangement = UIArrangementViewController()
    // 侧栏 72pt + 顶部 12pt 用安全区表达：arrangement 由系统布局，改 frame 会破坏列刷新
    arrangement.additionalSafeAreaInsets = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 72)
    // arrangement 是 tab 的第 0 项，需要自己的 tabBarItem（否则系统 tab bar 无图标/标题）
    arrangement.tabBarItem = listSection.tabBarItem
    arrangement.setViewController(listSection, for: .primary)
    arrangement.setViewController(detail, for: .secondary)
    var config = UISplitArrangement()
    config.axes([.horizontal, .vertical])
    var props = config.defaultViewProperties
    var width = UISplitArrangement.DimensionRange()
    width.minimum = .automatic
    width.preferred = .absolute(320)
    width.maximum = .absolute(360)
    props.width = width
    config.setViewProperties(props, for: .primary)
    arrangement.updateArrangement(config, animated: false)

    installSideRail(titles: ["消息", "通讯录", "我"],
                    images: sections.map { $0.viewControllers.first?.tabBarItem.image },
                    selectedImages: sections.map { $0.viewControllers.first?.tabBarItem.selectedImage })
    arrangementDetail = detail
    arrangementPrimary = listSection
    // 实验：列表不再按"容器托管内边距"处理，避免重复扣除右缘安全区
    if let listPage = listSection.topViewController {
      listPage.loadViewIfNeeded()
      // managedByContainer=true 会关闭 insetsContentViewsToSafeArea，避免 cell 被右缘安全区
      // 内缩（Duo 上会缩 84pt，表现为列表右侧一条留白）
      NETabBarController.updateTableContentInsets(in: listPage.view, managedByContainer: true)
    }
    var regular: [UIViewController] = [arrangement]
    regular.append(contentsOf: sections.dropFirst().map { $0 as UIViewController })
    regularControllers = regular
    setViewControllers(regular, animated: false)
    selectedIndex = 0
    isCompactLayout = view.bounds.width < 600
    applyArrangement(compact: isCompactLayout)
    // 双栏走官方 arrangement，侧栏按 UI 稿自绘（系统竖排栏只有图标、无文字）
    arrangementController = arrangement
    usesSystemTabBadges = false
    if #available(iOS 18.0, *) {
      setTabBarHidden(true, animated: false)
    } else {
      tabBar.isHidden = true
    }
  }

  private func installSplitAssembly(sections: [UINavigationController]) {
    guard let chatSection = sections.first else { return }
    // 三个分区各自包一层 split：会话栏负责右侧聊天，其余分区保留各自详情列。
    var splitControllers: [UIViewController] = []
    var chatAssembly: NEAdaptiveSplitAssembly?
    for (index, section) in sections.enumerated() {
      let detail = NEAdaptiveDemoNavigationController(rootViewController: makeAdaptiveEmptyDetail())
      let assembly = NEAdaptiveSplitAssembly(primary: section,
                                             secondary: detail,
                                             emptyDetail: makeAdaptiveEmptyDetail())
      splitControllers.append(assembly.splitViewController)
      if index == 0 { chatAssembly = assembly }
    }
    guard let assembly = chatAssembly else { return }
    splitAssembly = assembly
    // 会话打开路由指向 split 的 secondary 栈：列表点击与通知跳转都走这里。
    ChatRouter.setConversationPresentationHandler({ [weak self, weak assembly] route, parameters in
      guard let self, let assembly,
            let cid = parameters["conversationId"] as? String else { return false }
      let sessionId = parameters["sessionId"] as? String ?? ""
      let topicId = (parameters["topic"] as? V2NIMTopic).map { String($0.topicId) } ?? ""
      let intent = NEConversationOpenIntent(
        key: "\(route)|\(cid)|\(sessionId)|\(topicId)",
        route: route,
        parameters: parameters,
        requiresPresentationAction: parameters["anchor"] is V2NIMMessage || parameters["onReceiveNewMsgs"] != nil
      )
      guard let page = self.makeAdaptiveConversation(intent) else { return false }
      ChatRouter.applyPresentationParameters(intent.parameters, to: page, reload: true)
      let placeholder = assembly.secondaryNavigation.viewControllers.first ?? UIViewController()
      assembly.secondaryNavigation.setViewControllers([placeholder, page], animated: false)
      // 折叠成单栏时展示聊天详情（而不是会话列表）
      assembly.splitViewController.setViewController(assembly.secondaryNavigation, for: .compact)
      return true
    }, for: chatSection)
    setViewControllers(splitControllers, animated: false)
    selectedIndex = 0
    if #available(iOS 18.0, *) {
      setTabBarHidden(true, animated: false)
    } else {
      tabBar.isHidden = true
    }
  }


  /// Demo reference assembly. The existing controller remains the sole unread owner.
  private func installAdaptiveShell(sections: [UINavigationController]) {
    let detail = NEAdaptiveDemoNavigationController(rootViewController: makeAdaptiveEmptyDetail())
    // Explicit reference-host geometry; the integration document keeps these
    // calibration inputs separate from the public module's API defaults.
    let configuration = NEAdaptiveShellConfiguration(railWidth: 72,
                                                     singleContentMinimumWidth: 240, masterMinimumWidth: 240,
                                                     detailMinimumWidth: 320, dividerWidth: 1, mediumMasterWidth: 280,
                                                     expandedMasterWidth: 320, masterMaximumWidth: 360)
    configuration.railUsesTrailingEdge = true
    configuration.railItemHeight = 64
    configuration.railItemSpacing = 18
    configuration.railItemsTopInset = 268
    configuration.railBackTopInset = 168
    // Keep the design breathing room above the hosted page. The shell updates
    // the strip color from the active section so the gap remains continuous.
    configuration.contentTopInset = 12
    // Keep the system/status-area strip in the same color as the selected
    // section's root page. FunUI uses the contact navigation gray; leaving the
    // shell's default white exposes a visible band above the retained page.
    configuration.contentBackgroundColor = NEStyleManager.instance.isNormalStyle()
      ? .white : .funContactBackgroundColor
    let shell = NEAdaptiveShellViewController(sections: sections,
                                              detailNavigationController: detail, configuration: configuration)
    detail.isCompactAdaptiveLayout = { [weak shell] in
      shell?.isUsingAdaptiveLayout == true && shell?.isShowingPairedContent == false
    }
    shell.contentBackgroundColorProvider = { [weak shell] in
      guard let shell else { return configuration.contentBackgroundColor }
      let activeContent = shell.activeContentViewController
      activeContent?.loadViewIfNeeded()
      guard let color = activeContent?.view.backgroundColor, color != .clear else {
        return configuration.contentBackgroundColor
      }
      return color
    }
    shell.contentBackgroundColorsProvider = { [weak shell] in
      guard let shell else {
        return (master: configuration.contentBackgroundColor, detail: configuration.contentBackgroundColor)
      }
      let fallback = configuration.contentBackgroundColor
      func backgroundColor(of controller: UIViewController?) -> UIColor {
        controller?.loadViewIfNeeded()
        var candidate = controller?.view
        while let view = candidate {
          if let color = view.backgroundColor, color != .clear, color.cgColor.alpha > 0 {
            return color
          }
          candidate = view.superview
        }
        return fallback
      }
      let master = shell.sections.indices.contains(shell.selectedSectionIndex)
        ? backgroundColor(of: shell.sections[shell.selectedSectionIndex].visibleViewController)
        : fallback
      return (master: master, detail: backgroundColor(of: shell.activeContentViewController))
    }
    // Contacts and Mine keep their original root navigation controller as the
    // master. Pushed pages receive the same themed navigation container in the
    // detail column, without duplicating the section root or its data owner.
    detail.suppressDetailPushAnimation = { [weak shell] in shell?.isUsingAdaptiveLayout == true }
    detail.prepareDetailPage = { [weak self, weak shell] page in
      self?.prepareAdaptivePage(page,
                                paired: shell?.isShowingPairedContent == true,
                                managedByContainer: shell?.isUsingAdaptiveLayout == true,
                                loadView: true)
    }
    shell.sectionDetailNavigationFactory = { [weak shell] in
      let navigation = NEAdaptiveDemoNavigationController()
      navigation.isCompactAdaptiveLayout = { [weak shell] in
        shell?.isUsingAdaptiveLayout == true && shell?.isShowingPairedContent == false
      }
      navigation.suppressDetailPushAnimation = { [weak shell] in shell?.isUsingAdaptiveLayout == true }
      navigation.prepareDetailPage = { [weak self, weak shell] page in
        self?.prepareAdaptivePage(page,
                                  paired: shell?.isShowingPairedContent == true,
                                  managedByContainer: shell?.isUsingAdaptiveLayout == true,
                                  loadView: true)
      }
      return navigation
    }
    configuration.selectedTintColor = NEStyleManager.instance.isNormalStyle() ? .neUIKitDefaultPrimaryColor : .ne_funTheme
    configuration.railBackgroundColor = tabBar.backgroundColor ?? .white
    configuration.dividerColor = NEStyleManager.instance.isNormalStyle()
      ? .neUIKitDefaultNavigationDividerColor : .funContactDividerLineColor
    configuration.normalTintColor = UIColor(hexString: "#C5C9D2")
    configuration.backImage = CommonUIConfig.shared.backArrowImage
    configuration.backAccessibilityLabel = localizable("adaptive_back")
    shell.onDetailPlaceholderChanged = { [weak self, weak shell] placeholder in
      guard let self, let shell else { return }
      // 右列有内容才点亮左列选中行；右列回到占位（含折叠态）一律取消。
      self.setLeftColumnSelection(enabled: !placeholder, in: shell)
      self.updateConversationGroupRetention(in: shell)
    }
    shell.sectionEmptyDetailFactory = { [weak self] index in
      let titles = ["", "adaptive_empty_contact", "adaptive_empty_mine"]
      return self?.makeAdaptiveEmptyDetail(textKey: titles[index]) ?? UIViewController()
    }
    shell.onConversationOpened = { [weak self] conversationId in
      guard let self, let root = self.adaptiveShell?.sections.first?.viewControllers.first else { return }
      if let shell = self.adaptiveShell { self.updateConversationGroupRetention(in: shell) }
      if let conversation = root as? NEBaseConversationController {
        conversation.selectConversation(conversationId: conversationId, animated: false)
      } else if let conversation = root as? NEBaseLocalConversationController {
        conversation.selectConversation(conversationId: conversationId, animated: false)
      }
    }
    shell.view.tintColor = NEStyleManager.instance.isNormalStyle() ? .neUIKitDefaultPrimaryColor : .ne_funTheme
    shell.conversationCoordinator.controllerFactory = { [weak self] intent in
      self?.makeAdaptiveConversation(intent)
    }
    shell.conversationCoordinator.presentationAction = { intent, root in
      ChatRouter.applyPresentationParameters(intent.parameters, to: root, reload: true)
    }
    shell.onContentLayout = { [weak shell] controllers in
      guard let shell else { return }
      // The shell owns the system safe-area boundary. Every page in a retained
      // navigation stack must use the existing navigation height inside that
      // boundary; applying this only to the root leaves pushed contact/mine
      // pages with a second status-bar inset and inconsistent top spacing.
      for controller in controllers {
        let pages = (controller as? UINavigationController)?.viewControllers ?? [controller]
        for page in pages {
          guard page.isViewLoaded else { continue }
          // Horizontal safe area is already budgeted by the shell/rail.
          self.prepareAdaptivePage(page, paired: shell.isShowingPairedContent,
                                   managedByContainer: shell.isUsingAdaptiveLayout)
        }
      }
    }
    shell.onCompactChatVisibilityChanged = { root, _ in
      // 单屏聊天页的返回入口统一放在右侧工具栏（外壳绘制），
      // 页面导航栏不再保留返回按钮；其它页面的返回控制不变。
      root.loadViewIfNeeded()
      (root as? NEBaseViewController)?.navigationView.backButton.isHidden = true
      (root as? NEChatBaseViewController)?.navigationView.backButton.isHidden = true
      root.navigationItem.leftBarButtonItem = nil
      root.navigationItem.hidesBackButton = true
    }
    let registerNavigation: (UINavigationController) -> Void = { nav in
      ChatRouter.setConversationPresentationHandler({ [weak shell] route, parameters in
        guard let shell, let cid = parameters["conversationId"] as? String else { return false }
        let sessionId = parameters["sessionId"] as? String ?? ""
        let topicId = (parameters["topic"] as? V2NIMTopic).map { String($0.topicId) } ?? ""
        let intent = NEConversationOpenIntent(key: "\(route)|\(cid)|\(sessionId)|\(topicId)", route: route,
                                              parameters: parameters, requiresPresentationAction: parameters["anchor"] is V2NIMMessage || parameters["onReceiveNewMsgs"] != nil)
        let handled = shell.openConversation(intent)
        if handled, parameters["removeUserVC"] as? Bool == true || parameters["removeTeamVC"] as? Bool == true,
           let source = parameters["nav"] as? UINavigationController,
           source !== shell.conversationCoordinator.navigationController,
           source.viewControllers.count > 1 {
          source.popViewController(animated: false)
        }
        return handled
      }, for: nav)
    }
    shell.onSectionDetailNavigationCreated = registerNavigation
    for nav in sections + [detail] {
      registerNavigation(nav)
    }
    for section in sections {
      guard let navigation = section as? NEAdaptiveDemoNavigationController else { continue }
      navigation.isCompactAdaptiveLayout = { [weak shell] in
        shell?.isUsingAdaptiveLayout == true && shell?.isShowingPairedContent == false
      }
      navigation.presentSectionChild = { [weak shell, weak navigation] controller, animated in
        guard let shell, let navigation else { return false }
        return shell.presentSectionChild(controller, from: navigation, animated: animated)
      }
      // In compact Duo mode section pages remain in their original navigation
      // stack. They still belong to the adaptive shell, so prepare them before
      // the push and suppress UIKit's full-width transition. The legacy
      // fallback returns false and preserves the normal iPhone animation.
      navigation.suppressDetailPushAnimation = { [weak shell] in shell?.isUsingAdaptiveLayout == true }
      navigation.prepareDetailPage = { [weak self, weak shell] page in
        self?.prepareAdaptivePage(page,
                                  paired: shell?.isShowingPairedContent == true,
                                  managedByContainer: shell?.isUsingAdaptiveLayout == true,
                                  loadView: true)
      }
    }
    // Dispatch through the registered Router first. Only the stock handlers opt
    // into adaptive presentation, so customer replacement handlers retain ownership.
    adaptiveShell = shell
    shell.onLegacyFallback = { [weak self, weak shell] in
      guard let self, let shell else { return }
      self.restoreLegacyShell(shell)
    }
    // The Duo design has one app-owned trailing rail. Keep the root tab bar
    // only as a containment host and never ask UIKit to place a native sidebar.
    setViewControllers([shell], animated: false)
    selectedIndex = 0
    if #available(iOS 18.0, *) {
      setTabBarHidden(true, animated: false)
    } else {
      tabBar.isHidden = true
    }
  }

  private static func updateTableContentInsets(in view: UIView, managedByContainer: Bool) {
    if let table = view as? UITableView {
      // UITableView also owns the bottom safe-area adjustment; let its
      // dedicated helper capture and restore the complete indicator inset.
      table.ne_setContentInsetsManagedByContainer(managedByContainer)
    } else if let scroll = view as? UIScrollView {
      scroll.ne_setScrollIndicatorsManagedByContainer(managedByContainer)
    }
    for child in view.subviews { updateTableContentInsets(in: child, managedByContainer: managedByContainer) }
  }

  private static func updatePagingSafeArea(in controller: UIViewController, managedByContainer: Bool) {
    if let paging = controller as? NEPagingViewController {
      if managedByContainer {
        if objc_getAssociatedObject(paging, &adaptivePagingSafeAreaKey) == nil {
          objc_setAssociatedObject(paging, &adaptivePagingSafeAreaKey,
                                   NSNumber(value: paging.includeSafeAreaInsets),
                                   .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        if paging.includeSafeAreaInsets {
          paging.includeSafeAreaInsets = false
          paging.collectionView.collectionViewLayout.invalidateLayout()
        }
      } else if let original = objc_getAssociatedObject(paging, &adaptivePagingSafeAreaKey) as? NSNumber {
        paging.includeSafeAreaInsets = original.boolValue
        paging.collectionView.collectionViewLayout.invalidateLayout()
        objc_setAssociatedObject(paging, &adaptivePagingSafeAreaKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
    for child in controller.children {
      updatePagingSafeArea(in: child, managedByContainer: managedByContainer)
    }
  }

  /// Apply shell-owned geometry before a paired detail page is published.
  /// `onContentLayout` remains the source of truth for already visible stacks;
  /// this helper only closes the first-frame gap for a newly pushed page.
  private func prepareAdaptivePage(_ page: UIViewController, paired: Bool,
                                   managedByContainer: Bool,
                                   loadView: Bool = false) {
    if loadView { page.loadViewIfNeeded() }
    guard page.isViewLoaded else { return }
    NETabBarController.updateTableContentInsets(in: page.view, managedByContainer: managedByContainer)
    NETabBarController.updatePagingSafeArea(in: page, managedByContainer: managedByContainer)
    if let page = page as? NEBaseConversationController { page.topConstant = NEConstant.navigationHeight }
    if let page = page as? NEBaseLocalConversationController { page.topConstant = NEConstant.navigationHeight }
    if let page = page as? NEBaseContactViewController { page.topConstant = NEConstant.navigationHeight }
    if let page = page as? NEContactBaseViewController { page.topConstant = NEConstant.navigationHeight }
    if let page = page as? NEChatBaseViewController { page.topConstant = NEConstant.navigationHeight }
    if let page = page as? NEBaseViewController { page.topConstant = NEConstant.navigationHeight }
    if paired {
      setAdaptiveSelectionButtonWidth(page)
      if let page = page as? NEBaseViewController {
        setAdaptiveNavigationButtonWidths(page.navigationView)
      }
      if let page = page as? NEChatBaseViewController {
        setAdaptiveNavigationButtonWidths(page.navigationView)
      }
      if let page = page as? NEContactBaseViewController {
        setAdaptiveNavigationButtonWidths(page.navigationView)
      }
      if let page = page as? NELocalConversationBaseViewController {
        setAdaptiveNavigationButtonWidths(page.navigationView)
      }
    }
    page.view.setNeedsLayout()
    page.view.layoutIfNeeded()
  }

  /// System-navigation variants use a custom bar-button view instead of the
  /// shell's `NENavigationView`; keep the dynamic selection count readable in
  /// that path as well.
  private func setAdaptiveSelectionButtonWidth(_ page: UIViewController) {
    let button: UIButton?
    if let page = page as? NEBaseContactSelectedPageController {
      button = page.selectedSureButton
    } else if let page = page as? NEBaseContactSelectedViewController {
      button = page.sureButton
    } else {
      button = nil
    }
    guard let button else { return }
    var frame = button.frame
    frame.size.width = 100
    button.frame = frame
  }

  /// Keep icon-only actions compact while preserving text actions such as
  /// "确定(2)" on the Duo detail navigation bar.
  private func setAdaptiveNavigationButtonWidths(_ navigationView: NENavigationView) {
    navigationView.setBackButtonWidth(44)
    let hasTextAction = !(navigationView.moreButton.currentTitle?.isEmpty ?? true)
    navigationView.setMoreButtonWidth(hasTextAction ? 100 : 44)
  }

  private func restoreLegacyShell(_ shell: NEAdaptiveShellViewController) {
    // An active chat keeps its parent. The shell supplies full-width single-page
    // presentation and bottom tabs while the rail no longer fits the budget.
    guard shell.conversationCoordinator.activeIntent == nil else { return }
    let sections = shell.detachSectionsForLegacyTransfer()
    for section in shell.sections {
      let page = section.viewControllers.first
      for page in section.viewControllers where page.isViewLoaded {
        NETabBarController.updateTableContentInsets(in: page.view, managedByContainer: false)
        NETabBarController.updatePagingSafeArea(in: page, managedByContainer: false)
      }
      (page as? NEBaseContactViewController)?.listSelectionBackgroundColor = nil
      (page as? NEBaseConversationController)?.listSelectionBackgroundColor = nil
      (page as? NEBaseLocalConversationController)?.listSelectionBackgroundColor = nil
      (page as? MeViewController)?.listSelectionBackgroundColor = nil
    }
    for page in shell.conversationCoordinator.navigationController.viewControllers where page.isViewLoaded {
      NETabBarController.updateTableContentInsets(in: page.view, managedByContainer: false)
      NETabBarController.updatePagingSafeArea(in: page, managedByContainer: false)
    }
    for nav in sections + [shell.conversationCoordinator.navigationController] {
      ChatRouter.setConversationPresentationHandler(nil, for: nav)
      (nav as? NEAdaptiveDemoNavigationController)?.presentSectionChild = nil
    }
    shell.invalidateWindowContext()
    adaptiveShell = nil
    setViewControllers(sections, animated: false)
    selectedIndex = 0
    if #available(iOS 18.0, *) {
      setTabBarHidden(false, animated: false)
    } else {
      tabBar.isHidden = false
    }
  }

  private func makeAdaptiveEmptyDetail() -> UIViewController {
    makeAdaptiveEmptyDetail(textKey: "adaptive_empty_conversation")
  }

  private func makeAdaptiveEmptyDetail(textKey: String) -> UIViewController {
    let controller = UIViewController()
    controller.view.backgroundColor = NEStyleManager.instance.isNormalStyle()
      ? .white : .funContactItemBackgroundColor
    let empty = NEEmptyDataView(imageName: NEStyleManager.instance.isNormalStyle() ? "user_empty" : "fun_user_empty",
                                content: textKey.isEmpty ? "" : localizable(textKey), frame: .zero)
    controller.view.addSubview(empty)
    empty.translatesAutoresizingMaskIntoConstraints = false
    // NEEmptyDataView is also used by legacy list pages and intentionally has
    // a 176pt top offset there. Detail placeholders need the image/text group
    // centered in the current right column, so tune only this Duo-owned copy.
    if let top = empty.constraints.first(where: {
      $0.firstItem as AnyObject? === empty.emptyImageView && $0.firstAttribute == .top
    }) {
      top.constant = 0
    }
    NSLayoutConstraint.activate([
      empty.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
      empty.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
      empty.heightAnchor.constraint(equalToConstant: 120),
      empty.widthAnchor.constraint(lessThanOrEqualTo: controller.view.widthAnchor, constant: -32),
    ])
    return controller
  }

  private func makeAdaptiveConversation(_ intent: NEConversationOpenIntent) -> UIViewController? {
    guard let cid = intent.parameters["conversationId"] as? String else { return nil }
    let normal = NEStyleManager.instance.isNormalStyle()
    let anchor = intent.parameters["anchor"] as? V2NIMMessage
    let controller: UIViewController
    switch intent.route {
    case PushP2pChatVCRouter:
      controller = normal ? P2PChatViewController(conversationId: cid, anchor: anchor) : FunP2PChatViewController(conversationId: cid, anchor: anchor)
    case PushTeamChatVCRouter:
      controller = normal ? TeamChatViewController(conversationId: cid, anchor: anchor) : FunTeamChatViewController(conversationId: cid, anchor: anchor)
    case PushBotSubSessionListRouter:
      guard let sessionId = intent.parameters["sessionId"] as? String else { return nil }
      let name = intent.parameters["sessionName"] as? String ?? (NEAIUserManager.shared.getShowName(sessionId) ?? sessionId)
      controller = normal ? BotSubSessionListViewController(conversationId: cid, sessionId: sessionId, sessionName: name) : FunBotSubSessionListViewController(conversationId: cid, sessionId: sessionId, sessionName: name)
    case PushBotSubSessionChatRouter:
      guard let sessionId = intent.parameters["sessionId"] as? String else { return nil }
      let name = intent.parameters["sessionName"] as? String ?? (NEAIUserManager.shared.getShowName(sessionId) ?? sessionId)
      let topic = intent.parameters["topic"] as? V2NIMTopic
      controller = normal ? BotSubSessionChatViewController(conversationId: cid, sessionId: sessionId, sessionName: name, topic: topic) : FunBotSubSessionChatViewController(conversationId: cid, sessionId: sessionId, sessionName: name, topic: topic)
    default: return nil
    }
    _ = ChatRouter.applyPresentationParameters(intent.parameters, to: controller, reload: false)
    return controller
  }

  deinit {
    if let shell = adaptiveShell {
      for navigation in shell.sections + [shell.conversationCoordinator.navigationController] {
        ChatRouter.setConversationPresentationHandler(nil, for: navigation)
        (navigation as? NEAdaptiveDemoNavigationController)?.presentSectionChild = nil
      }
    }
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      if let filter = localSessionUnreadFilter {
        LocalConversationRepo.shared.unsubscribeUnreadCountByFilter(filter)
      }
      LocalConversationRepo.shared.removeLocalConversationListener(self)
    } else {
      if let filter = sessionUnreadFilter {
        ConversationRepo.shared.unsubscribeUnreadCountByFilter(filter) { _ in }
      }
      ConversationRepo.shared.removeConversationListener(self)
    }

    ContactRepo.shared.removeContactListener(self)
    TeamRepo.shared.removeTeamListener(self)
    NotificationCenter.default.removeObserver(self)
  }

  private func setUpControllers(useAdaptiveNavigation: Bool) -> [UINavigationController] {
    let sections: [UINavigationController]
    if NEStyleManager.instance.isNormalStyle() {
      // chat
      if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
        chat = LocalConversationController()
        (chat as? LocalConversationController)?.viewModel.syncFinished = isChangeUIType
      } else {
        chat = ConversationController()
        (chat as? ConversationController)?.viewModel.syncFinished = isChangeUIType
      }

      chat?.tabBarItem = UITabBarItem(
        title: localizable("message"),
        image: UIImage(named: "chat"),
        selectedImage: UIImage(named: "chatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      chat?.tabBarItem.accessibilityIdentifier = "id.conversation"
      let chatNav: UINavigationController = useAdaptiveNavigation
        ? NEAdaptiveDemoNavigationController(rootViewController: chat!)
        : NENavigationController(rootViewController: chat!)

      // Contacts
      contactVC = ContactViewController()
      contactVC?.tabBarItem = UITabBarItem(
        title: localizable("contact"),
        image: UIImage(named: "contact"),
        selectedImage: UIImage(named: "contactSelect")?.withRenderingMode(.alwaysOriginal)
      )
      contactVC?.tabBarItem.accessibilityIdentifier = "id.contact"
      let contactsNav: UINavigationController = useAdaptiveNavigation
        ? NEAdaptiveDemoNavigationController(rootViewController: contactVC!)
        : NENavigationController(rootViewController: contactVC!)

      // Me
      meVC.tabBarItem = UITabBarItem(
        title: localizable("mine"),
        image: UIImage(named: "person"),
        selectedImage: UIImage(named: "personSelect")?.withRenderingMode(.alwaysOriginal)
      )
      meVC.tabBarItem.accessibilityIdentifier = "id.mine"
      meVC.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
      meVC.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#337EFF")], for: .selected)
      let meNav: UINavigationController = useAdaptiveNavigation
        ? NEAdaptiveDemoNavigationController(rootViewController: meVC)
        : NENavigationController(rootViewController: meVC)

      sections = [chatNav, contactsNav, meNav]

      if #available(iOS 13.0, *) {
        let appearance = UITabBarAppearance()
        // 折叠屏保持原逻辑（避免影响 Duo 竖排 tab bar）；非折叠在 iOS 26 以下
        // 必须先配置不透明背景，否则只设 backgroundColor 会让 tab bar 透明、
        // 露出窗口黑底（iOS 17 上表现为黑色 tab bar）。
        let isFoldableDevice = NEAdaptiveDeviceGate.isFoldableDevice
        if !isFoldableDevice, #unavailable(iOS 26.0) {
          appearance.configureWithOpaqueBackground()
        }
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hexString: "#C5C9D2")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#999999")]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#337EFF")]
        // 背景色必须放进 appearance：直接设 tabBar.backgroundColor 会让 Duo 竖排 tab bar 退化成空白
        appearance.backgroundColor = UIColor(hexString: "#F6F8FA")
        tabBar.standardAppearance = appearance
        if !isFoldableDevice, #available(iOS 15.0, *) {
          // 列表停在顶部时使用的是 scrollEdgeAppearance，未设置会退回系统默认背景。
          tabBar.scrollEdgeAppearance = appearance
        }
      } else {
        tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
        for vc in sections {
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#337EFF")], for: .selected)
        }
      }
    } else {
      // chat
      if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
        chat = FunLocalConversationController()
        (chat as? FunLocalConversationController)?.viewModel.syncFinished = isChangeUIType
      } else {
        chat = FunConversationController()
        (chat as? FunConversationController)?.viewModel.syncFinished = isChangeUIType
      }

      chat?.tabBarItem = UITabBarItem(
        title: localizable("message"),
        image: UIImage(named: "funChat"),
        selectedImage: UIImage(named: "funChatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      chat?.tabBarItem.accessibilityIdentifier = "id.conversation"
      let chatNav: UINavigationController = useAdaptiveNavigation
        ? NEAdaptiveDemoNavigationController(rootViewController: chat!)
        : NENavigationController(rootViewController: chat!)

      // Contacts
      contactVC = FunContactViewController()
      contactVC?.tabBarItem = UITabBarItem(
        title: localizable("contact"),
        image: UIImage(named: "funContact"),
        selectedImage: UIImage(named: "funContactSelect")?.withRenderingMode(.alwaysOriginal)
      )
      contactVC?.tabBarItem.accessibilityIdentifier = "id.contact"
      let contactsNav: UINavigationController = useAdaptiveNavigation
        ? NEAdaptiveDemoNavigationController(rootViewController: contactVC!)
        : NENavigationController(rootViewController: contactVC!)

      // Me
      meVC.tabBarItem = UITabBarItem(
        title: localizable("mine"),
        image: UIImage(named: "funPerson"),
        selectedImage: UIImage(named: "funPersonSelect")?.withRenderingMode(.alwaysOriginal)
      )
      meVC.tabBarItem.accessibilityIdentifier = "id.mine"
      let meNav: UINavigationController = useAdaptiveNavigation
        ? NEAdaptiveDemoNavigationController(rootViewController: meVC)
        : NENavigationController(rootViewController: meVC)

      sections = [chatNav, contactsNav, meNav]
      for vc in sections {
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_funTheme], for: .selected)
      }

      if #available(iOS 13.0, *) {
        let appearance = UITabBarAppearance()
        let isFoldableDevice = NEAdaptiveDeviceGate.isFoldableDevice
        if !isFoldableDevice, #unavailable(iOS 26.0) {
          appearance.configureWithOpaqueBackground()
        }
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hexString: "#C5C9D2")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#999999")]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.ne_funTheme]
        appearance.backgroundColor = UIColor(hexString: "#F6F6F6")
        tabBar.standardAppearance = appearance
        if !isFoldableDevice, #available(iOS 15.0, *) {
          tabBar.scrollEdgeAppearance = appearance
        }
      } else {
        tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
        for vc in sections {
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_funTheme], for: .selected)
        }
      }
    }
    return sections
  }

  func setUpSessionBadgeValue() {
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      if localSessionUnreadFilter == nil {
        let filter = V2NIMLocalConversationFilter()
        filter.ignoreMuted = true
        localSessionUnreadFilter = filter
        LocalConversationRepo.shared.addUnreadCountChangeObserver(filter) { _ in }
      }
      guard let filter = localSessionUnreadFilter else {
        return
      }
      LocalConversationRepo.shared.getUnreadCountByFilter(filter) { [weak self] count, _ in
        self?.updateSessionBadge(count ?? 0)
      }
    } else {
      if sessionUnreadFilter == nil {
        let filter = V2NIMConversationFilter()
        filter.ignoreMuted = true
        sessionUnreadFilter = filter
        ConversationRepo.shared.subscribeUnreadCountByFilter(filter) { _ in }
      }
      guard let filter = sessionUnreadFilter else {
        return
      }
      ConversationRepo.shared.getUnreadCountByFilter(filter) { [weak self] count, _ in
        self?.updateSessionBadge(count ?? 0)
      }
    }
  }

  private func updateSessionBadge(_ count: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      self.sessionUnreadCount = count
      self.adaptiveShell?.sections.first?.tabBarItem.badgeValue = count > 0 ? "" : nil
      self.refreshAdaptiveTabItems()
      self.updateTabBadge(index: 0, value: count > 0 ? "" : nil)
    }
  }

  // 设置通讯录未读显示状态
  func setUpContactBadgeValue() {
    DispatchQueue.global().async { [weak self] in
      ContactRepo.shared.getUnreadApplicationCount { count, error in
        if IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth {
          let option = V2NIMTeamJoinActionInfoQueryOption()
          option.offset = 0
          option.limit = neTeamJoinActionPageLimit
          TeamRepo.shared.getTeamJoinActionInfoList(option) { result, error in
            if let actions = result?.infos {
              let unreadActions = actions.filter { $0.timestamp > neTeamJoinActionReadTime }
              self?.contactUnreadCount = count + unreadActions.count
            } else {
              self?.contactUnreadCount = count
            }

            // 显示红点
            DispatchQueue.main.async {
              self?.updateTabBadge(index: 1, value: (self?.contactUnreadCount ?? 0) > 0 ? "" : nil)
              self?.refreshAdaptiveTabItems()

              //      // 显示未读数
              //      self?.setupContactBadge(unreadCount: contactUnreadCount)
            }
          }
        }
      }
    }
  }

  // 设置通讯录显示未读数
  func setupContactBadge(unreadCount: Int) {
    if unreadCount > 0 {
      if unreadCount > 99 {
        tabBar.setServerBadge(count: "99+")
      } else {
        tabBar.setServerBadge(count: "\(unreadCount)")
      }
    } else {
      tabBar.setServerBadge(count: nil)
    }
  }

  /// arrangement 装配使用系统 tab bar，红点必须走系统 badgeValue（自绘红点位置会错）
  private var usesSystemTabBadges = false

  private func updateTabBadge(index: Int, value: String?) {
    if railBadgeDots.indices.contains(index) {
      railBadgeDots[index].isHidden = (value == nil)
      return
    }
    if usesSystemTabBadges, let controllers = viewControllers, index < controllers.count {
      controllers[index].tabBarItem.badgeValue = value
      return
    }
    if value != nil { tabBar.showBadgOn(index: index, tabbarItemNums: 3) } else { tabBar.hideBadg(on: index) }
    if let sections = adaptiveShell?.sections, index < sections.count {
      sections[index].tabBarItem.badgeValue = value
    }
  }

  private func refreshSessionBadge() {
    setUpSessionBadgeValue()
  }

  @objc open func clearValidationUnreadCount() {
    updateTabBadge(index: 1, value: nil)
    refreshAdaptiveTabItems()
  }

  @objc private func clearAdaptiveConversation(_ notification: Notification) {
    guard let shell = adaptiveShell else { return }
    if let conversationId = notification.object as? String {
      shell.clearConversationIfNeeded(conversationId)
    } else {
      shell.clearActiveConversation()
    }
  }
}

// MARK: - NEContactListener

extension NETabBarController: NEContactListener {
  func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    setUpContactBadgeValue()
  }

  func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication) {
    setUpContactBadgeValue()
  }
}

// MARK: - NETeamListener

extension NETabBarController: NETeamListener {
  func onReceive(_ joinActionInfo: V2NIMTeamJoinActionInfo) {
    setUpContactBadgeValue()
  }
}

// MARK: - V2NIMConversationListener

extension NETabBarController: NEConversationListener {
  func onConversationChanged(_ conversations: [V2NIMConversation]) {
    refreshSessionBadge()
  }

  func onConversationCreated(_ conversation: V2NIMConversation) {
    refreshSessionBadge()
  }

  func onConversationDeleted(_ conversationIds: [String]) {
    refreshSessionBadge()
    for conversationId in conversationIds {
      adaptiveShell?.clearConversationIfNeeded(conversationId)
    }
  }

  func onUnreadCountChangedByFilter(_ filter: V2NIMConversationFilter, _ unreadCount: Int) {
    guard filter.ignoreMuted, filter.conversationGroupId == nil else {
      return
    }
    updateSessionBadge(unreadCount)
  }
}

// MARK: - NELocalConversationListener

extension NETabBarController: NELocalConversationListener {
  func onLocalConversationChanged(_ conversations: [V2NIMLocalConversation]) {
    refreshSessionBadge()
  }

  func onLocalConversationCreated(_ conversation: V2NIMLocalConversation) {
    refreshSessionBadge()
  }

  func onLocalConversationDeleted(_ conversationIds: [String]) {
    refreshSessionBadge()
    for conversationId in conversationIds {
      adaptiveShell?.clearConversationIfNeeded(conversationId)
    }
  }

  func onLocalUnreadCountChangedByFilter(_ filter: V2NIMLocalConversationFilter, _ unreadCount: Int) {
    guard filter.ignoreMuted else {
      return
    }
    updateSessionBadge(unreadCount)
  }
}

/// 阶段 2 旁路装配：用系统 `UISplitViewController` 承载「列表 + 详情」。
///
/// 官方指引要求优先使用系统容器（split view / tab bar），由系统负责栏宽、
/// 折叠区与安全区。这里先只搭骨架并通过 `UserDefaults` 开关启用，
/// 旧的自适应外壳保持可用，随时可以回退。
final class NEAdaptiveSplitAssembly {
  /// 开关：默认关闭，避免未接路由前影响现有体验。
  static let enableKey = "enableAdaptiveSplitAssembly"

  static var isEnabled: Bool {
    UserDefaults.standard.bool(forKey: enableKey)
  }

  let splitViewController: UISplitViewController
  private(set) var primaryNavigation: UINavigationController?
  let secondaryNavigation: UINavigationController

  init(primary: UINavigationController,
       secondary: UINavigationController,
       emptyDetail: UIViewController) {
    primaryNavigation = primary
    secondaryNavigation = secondary
    secondary.setViewControllers([emptyDetail], animated: false)

    splitViewController = UISplitViewController(style: .doubleColumn)
    // 双栏并列显示；紧凑宽度（折叠态）由系统自动收敛成单栏。
    splitViewController.preferredDisplayMode = .oneBesideSecondary
    splitViewController.preferredSplitBehavior = .tile
    splitViewController.setViewController(primary, for: .primary)
    splitViewController.setViewController(secondary, for: .secondary)
    splitViewController.setViewController(primary, for: .compact)
  }
}
