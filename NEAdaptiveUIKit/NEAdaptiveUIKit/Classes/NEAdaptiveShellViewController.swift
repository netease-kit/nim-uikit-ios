#if canImport(UIKit)
  import UIKit

  /// 尾部安全区归属计算。
  ///
  /// Duo 窗口尾部有一段系统状态区（时钟 / Wi-Fi），外壳用 rail 覆盖它、并按列宽
  /// 让内容避让；但页面仍会继承整段尾部安全区。UIKit 会据此把左滑操作按钮从
  /// 操作容器里再向内缩进，表现为“删除”按钮右侧留下一条空白。UIKit 允许负的
  /// `additionalSafeAreaInsets`，因此可以按页面抵消继承值而不改页面自身布局。
  enum NEAdaptiveTrailingInset {
    /// - Parameters:
    ///   - safeAreaRight: 页面当前尾部安全区（已包含上一次写入的补偿值）。
    ///   - applied: 上一次由外壳写入的补偿值。
    /// - Returns: 抵消继承值所需的补偿量；无需补偿时为 0。
    static func cancellation(safeAreaRight: CGFloat, applied: CGFloat) -> CGFloat {
      let inherited = safeAreaRight - applied
      return abs(inherited) > 0.5 ? -inherited : 0
    }
  }

  /// Explicit customer-owned dimensions. Values must be calibrated against the host window.
  @objcMembers public final class NEAdaptiveShellConfiguration: NSObject {
    public var railWidth: CGFloat
    public var singleContentMinimumWidth: CGFloat
    public var masterMinimumWidth: CGFloat
    public var detailMinimumWidth: CGFloat
    public var dividerWidth: CGFloat
    public var mediumMasterWidth: CGFloat
    public var expandedMasterWidth: CGFloat
    public var masterMaximumWidth: CGFloat
    public var mediumThreshold: CGFloat = 600
    public var expandedThreshold: CGFloat = 840
    public var compactAspectRatio: CGFloat = 1.2
    public var railBackgroundColor: UIColor = .secondarySystemBackground
    /// Dynamic color for the boundary between paired columns.
    public var dividerColor: UIColor = .separator
    public var selectedTintColor: UIColor = .systemBlue
    public var normalTintColor: UIColor = .secondaryLabel
    /// 皮肤提供的返回图；关闭 `usesSystemBackButtonStyle` 时使用。
    public var backImage: UIImage?
    /// 侧栏返回按钮的着色，默认使用系统标签色，保持系统返回按钮观感。
    public var backTintColor: UIColor = .label
    /// 单屏聊天返回入口使用系统返回按钮样式（SF Symbol `chevron.left`）。
    ///
    /// 产品稿要求单屏聊天的返回入口与系统返回按钮一致，而不是各皮肤自绘的
    /// 返回箭头，因此默认开启；需要沿用皮肤返回图的接入方可以关闭。
    public var usesSystemBackButtonStyle = true
    public var backAccessibilityLabel: String?
    /// Duo places the rail on the physical trailing edge so it lines up with
    /// the system status region shown in the interaction reference. Legacy customers
    /// can retain the safe-rect placement by leaving this false.
    public var railUsesTrailingEdge = false
    public var railItemHeight: CGFloat = 64
    public var railItemSpacing: CGFloat = 18
    /// 已废弃：分区入口组固定在侧栏底部，不再读取顶部内边距。
    public var railItemsTopInset: CGFloat = 268
    /// 侧栏底部入口组与窗口底部安全区之间的距离。
    public var railItemsBottomInset: CGFloat = 12
    /// 统一返回按钮的圆形视觉与命中尺寸。
    public var railBackButtonSize: CGFloat = 44
    /// 页面右侧操作迁移到侧栏后的圆形按钮尺寸。
    public var railActionButtonSize: CGFloat = 52
    /// 多个右侧操作之间的垂直间距。
    public var railActionSpacing: CGFloat = 12
    /// 返回按钮与第一个右侧操作之间的间距。
    public var railActionTopSpacing: CGFloat = 8
    /// 侧栏控件的统一圆形外观：浅色底 + 细描边。
    public var railControlBackgroundColor: UIColor = .secondarySystemBackground
    public var railControlBorderColor: UIColor = .separator
    public var railControlBorderWidth: CGFloat = 0.5
    public var railActionTextColor: UIColor = .label
    public var railActionTextFont: UIFont = .systemFont(ofSize: 14, weight: .medium)
    /// 数量角标（页面右侧按钮文案中的计数）背景色；nil 时跟随 `selectedTintColor`（皮肤主题色）。
    public var railBadgeBackgroundColor: UIColor?
    public var railBadgeTextColor: UIColor = .systemBackground
    /// Host-calibrated position below a trailing system status region.
    /// Content safe-area top does not describe occlusion inside that region.
    public var railBackTopInset: CGFloat = 0
    /// Design breathing room inside the system top safe-area boundary.
    /// Keep this separate from page navigation heights so child pages do not
    /// receive a second status-bar inset.
    public var contentTopInset: CGFloat = 0
    public var contentBackgroundColor: UIColor = .systemBackground

    public init(railWidth: CGFloat, singleContentMinimumWidth: CGFloat, masterMinimumWidth: CGFloat,
                detailMinimumWidth: CGFloat, dividerWidth: CGFloat, mediumMasterWidth: CGFloat,
                expandedMasterWidth: CGFloat, masterMaximumWidth: CGFloat) {
      self.railWidth = railWidth; self.singleContentMinimumWidth = singleContentMinimumWidth
      self.masterMinimumWidth = masterMinimumWidth; self.detailMinimumWidth = detailMinimumWidth
      self.dividerWidth = dividerWidth; self.mediumMasterWidth = mediumMasterWidth
      self.expandedMasterWidth = expandedMasterWidth; self.masterMaximumWidth = masterMaximumWidth
      super.init()
    }

    var policy: NEAdaptiveLayoutConfiguration {
      var value = NEAdaptiveLayoutConfiguration(
        railWidth: railWidth, singleContentMinimumWidth: singleContentMinimumWidth,
        masterMinimumWidth: masterMinimumWidth, detailMinimumWidth: detailMinimumWidth,
        dividerWidth: dividerWidth,
        medium: .init(preferredMasterWidth: mediumMasterWidth, maximumMasterWidth: masterMaximumWidth),
        expanded: .init(preferredMasterWidth: expandedMasterWidth, maximumMasterWidth: masterMaximumWidth)
      )
      value.mediumThreshold = mediumThreshold; value.expandedThreshold = expandedThreshold
      value.compactAspectRatio = compactAspectRatio
      value.railUsesTrailingEdge = railUsesTrailingEdge
      return value
    }
  }

  /// Stable parent for the existing chat navigation stack. Resize does not forward false exits.
  @objcMembers public final class NEChatDetailHostController: UIViewController {
    public let navigationControllerContent: UINavigationController
    private var contentVisible = false
    override public var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

    public init(navigationController: UINavigationController) {
      navigationControllerContent = navigationController
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    override public func viewDidLoad() {
      super.viewDidLoad()
      addChild(navigationControllerContent)
      view.addSubview(navigationControllerContent.view)
      navigationControllerContent.didMove(toParent: self)
    }

    override public func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      navigationControllerContent.view.frame = view.bounds
    }

    fileprivate func setContentVisible(_ visible: Bool, animated: Bool = false) {
      guard visible != contentVisible else { return }
      contentVisible = visible
      navigationControllerContent.beginAppearanceTransition(visible, animated: animated)
      navigationControllerContent.endAppearanceTransition()
    }
  }

  /// Observe UIKit's supported navigation completion callback and preserve the
  /// host delegate's animation, interaction, and appearance callbacks.
  private final class NEAdaptiveNavigationObserver: NSObject, UINavigationControllerDelegate {
    weak var originalDelegate: UINavigationControllerDelegate?
    var didShow: (() -> Void)?
    /// 在页面真正出现前压制页面自己的返回/右侧入口，避免先展示再隐藏的闪烁。
    var willShow: ((UIViewController) -> Void)?
    init(_ navigation: UINavigationController, didShow: @escaping () -> Void) {
      originalDelegate = navigation.delegate
      self.didShow = didShow
      super.init()
      navigation.delegate = self
    }
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
      originalDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
      willShow?(viewController)
    }
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController, animated: Bool) {
      originalDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
      DispatchQueue.main.async { [weak self] in self?.didShow?() }
    }
    override func responds(to selector: Selector!) -> Bool {
      super.responds(to: selector) || (originalDelegate?.responds(to: selector) ?? false)
    }
    override func forwardingTarget(for selector: Selector!) -> Any? {
      originalDelegate?.responds(to: selector) == true ? originalDelegate : super.forwardingTarget(for: selector)
    }
  }

  private final class NEAdaptiveSectionHost: UIViewController {
    let content: UINavigationController
    var makeDetailNavigation: () -> UINavigationController = { UINavigationController() }
    var onDetailNavigationCreated: ((UINavigationController) -> Void)?
    var onStackChanged: (() -> Void)?
    var makeEmptyDetail: (() -> UIViewController)?
    private(set) var splitDetail: UINavigationController?
    private var detailObservation: NEAdaptiveNavigationObserver?
    private var contentVisible = false
    private var splitMasterWidth: CGFloat?
    private var dividerWidth: CGFloat = 0
    private let dividerView = UIView()
    private var isTransferring = false
    private var waitingForTransition = false
    override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }
    init(_ content: UINavigationController) { self.content = content; super.init(nibName: nil, bundle: nil) }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
      super.viewDidLoad()
      addChild(content); view.addSubview(content.view); content.didMove(toParent: self)
      dividerView.isUserInteractionEnabled = false
      dividerView.isHidden = true
      dividerView.accessibilityIdentifier = "id.adaptive.section.divider"
      view.addSubview(dividerView)
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      guard splitMasterWidth != nil, splitDetail != nil else {
        content.view.frame = view.bounds
        dividerView.isHidden = true
        return
      }
      applySplitGeometry()
    }

    /// Transfer controllers through UIKit's public navigation APIs after any
    /// push/pop animation completes. Views always remain under their real parent.
    func configureSplit(masterWidth: CGFloat?, dividerWidth: CGFloat, dividerColor: UIColor) {
      dividerView.backgroundColor = dividerColor
      guard !isTransferring else { return }
      if let transition = content.transitionCoordinator ?? splitDetail?.transitionCoordinator {
        guard !waitingForTransition else { return }
        waitingForTransition = true
        transition.animate(alongsideTransition: nil) { [weak self] _ in
          self?.waitingForTransition = false
          self?.onStackChanged?()
        }
        return
      }
      guard let width = masterWidth else {
        restoreSplitIfNeeded()
        splitMasterWidth = nil
        dividerView.isHidden = true
        view.setNeedsLayout()
        return
      }
      // Establish the destination geometry before UIKit sees the migrated child.
      // Keep this synchronous even when the host is inside a window resize
      // transition: otherwise the detail navigation can inherit an animation
      // from its old full-width frame into the right column.
      UIView.performWithoutAnimation { [weak self] in
        self?.applySplitConfiguration(masterWidth: width, dividerWidth: dividerWidth)
      }
    }

    private func applySplitConfiguration(masterWidth width: CGFloat, dividerWidth: CGFloat) {
      let resolvedMasterWidth = max(0, min(width, view.bounds.width))
      splitMasterWidth = resolvedMasterWidth
      self.dividerWidth = max(0, dividerWidth)
      let installsDetail = splitDetail == nil
      if installsDetail { installDetailHost() }
      applySplitGeometry()
      view.layoutIfNeeded()
      let pushedFromMaster = Array(content.viewControllers.dropFirst())
      if !pushedFromMaster.isEmpty, let root = content.viewControllers.first {
        isTransferring = true
        content.setViewControllers([root], animated: false)
        // 展开时把左列子页面迁入右列：保留空详情作为栈底，
        // 页面自身有返回按钮就按普通栈中页展示，不再强制把第一个页面当根。
        let migratedBase = emptyDetailController ?? UIViewController()
        splitDetail!.setViewControllers([migratedBase] + pushedFromMaster, animated: false)
        isTransferring = false
      }
      applySplitGeometry()
      view.layoutIfNeeded()
      if installsDetail, contentVisible, let detail = splitDetail {
        detail.beginAppearanceTransition(true, animated: false)
        detail.endAppearanceTransition()
      }
    }

    private func applySplitGeometry() {
      guard let splitMasterWidth, let detail = splitDetail else { return }
      content.view.frame = CGRect(x: 0, y: 0, width: splitMasterWidth, height: view.bounds.height)
      dividerView.frame = CGRect(x: splitMasterWidth, y: 0,
                                 width: dividerWidth, height: view.bounds.height)
      dividerView.isHidden = dividerWidth <= 0
      detail.view.frame = CGRect(x: splitMasterWidth + dividerWidth, y: 0,
                                 width: max(0, view.bounds.width - splitMasterWidth - dividerWidth), height: view.bounds.height)
    }

    /// 空占位控制器。右侧第一个页面作为导航根（栈深兜底不额外补返回），
    /// 页面自身返回若存在仍由 rail 展示；占位页只在重置时临时放回，所以需要单独持有引用。
    private weak var emptyDetailController: UIViewController?

    private func installDetailHost() {
      let detail = makeDetailNavigation()
      let empty = makeEmptyDetail?() ?? UIViewController()
      emptyDetailController = empty
      detail.setViewControllers([empty], animated: false)
      addChild(detail)
      view.addSubview(detail.view)
      detail.didMove(toParent: self)
      splitDetail = detail
      onDetailNavigationCreated?(detail)
      detailObservation = NEAdaptiveNavigationObserver(detail) { [weak self] in
        guard let self, !self.isTransferring else { return }
        self.onStackChanged?()
      }
    }

    private func restoreSplitIfNeeded() {
      guard let detail = splitDetail, let root = content.viewControllers.first else { return }
      isTransferring = true
      // 右列可能以页面作根（新模型）：整栈迁回左列，保留层级，
      // 否则折叠再展开后栈深变小，返回按钮会消失。
      var pushed = Array(detail.viewControllers.dropFirst())
      if let first = detail.viewControllers.first, first !== emptyDetailController {
        pushed = Array(detail.viewControllers)
      }
      detail.delegate = detailObservation?.originalDelegate
      detailObservation = nil
      if contentVisible {
        detail.beginAppearanceTransition(false, animated: false)
        detail.endAppearanceTransition()
      }
      // Detach from the source stack before assigning a new parent.
      detail.setViewControllers([], animated: false)
      if !pushed.isEmpty { content.setViewControllers([root] + pushed, animated: false) }
      detail.willMove(toParent: nil)
      detail.view.removeFromSuperview()
      detail.removeFromParent()
      splitDetail = nil
      isTransferring = false
    }

    func detachContentForTransfer() {
      restoreSplitIfNeeded()
      content.willMove(toParent: nil)
      content.view.removeFromSuperview()
      content.removeFromParent()
    }

    func setVisible(_ visible: Bool) {
      guard contentVisible != visible else { return }; contentVisible = visible
      for navigation in [content, splitDetail].compactMap({ $0 }) {
        navigation.beginAppearanceTransition(visible, animated: false)
        navigation.endAppearanceTransition()
      }
    }

    /// 右列当前是否停留在空占位（没有打开任何页面）。
    /// 没有独立分栏时（统一共享右列模型 / 折叠态）以本分区导航栈深判断，
    /// 不能用 `nil === nil` 比较，否则会恒为 true。
    var isShowingDetailPlaceholder: Bool {
      guard let detail = splitDetail else { return content.viewControllers.count == 1 }
      return detail.topViewController === emptyDetailController
    }

    /// 右列是否有内容：打开了页面，或在页面上呈现了模态。
    var hasDetailContent: Bool {
      guard let detail = splitDetail else { return false }
      return detail.topViewController !== emptyDetailController || detail.presentedViewController != nil
    }

    func resetDetail() {
      if let detail = splitDetail {
        // 兜底不能用"当前栈顶"，否则会把刚打开的页面当成占位又设回去
        // （表现为切换 tab 后右列仍显示上一个页面）。占位实例丢了就新建一个。
        let placeholder: UIViewController
        if let existing = emptyDetailController {
          placeholder = existing
        } else {
          let created = makeEmptyDetail?() ?? UIViewController()
          emptyDetailController = created
          placeholder = created
        }
        detail.setViewControllers([placeholder], animated: false)
      }
      if let root = content.viewControllers.first, content.viewControllers.count > 1 {
        content.setViewControllers([root], animated: false)
      }
      onStackChanged?()
    }
  }

  /// One right rail, retained section stacks, and a retained double-column content container.
  @objcMembers public final class NEAdaptiveShellViewController: UIViewController, NEConversationPresentationHandler, UITabBarDelegate {
    public let configuration: NEAdaptiveShellConfiguration
    public let sections: [UINavigationController]
    public let detailHost: NEChatDetailHostController
    public let conversationCoordinator: NEConversationNavigationCoordinator
    public private(set) var selectedSectionIndex = 0
    /// 折叠态从非会话分区（如通讯录群聊）进入聊天时记录来源分区；
    /// 返回时回该分区，而不是切到会话列表。展开态不记录。
    private var compactChatOriginSection: Int?
    public private(set) var isUsingLegacyLayout = false
    public var onSectionSelected: ((Int) -> Void)?
    /// Host uses its original legacy shell when no usable content/rail budget remains.
    public var onLegacyFallback: (() -> Void)?
    public var onGeometryChanged: ((NSDictionary) -> Void)?
    /// Called after the shell computes its safe-area content frame. Hosts may
    /// align their own custom title bars to that already-safe coordinate space.
    public var onContentLayout: (([UIViewController]) -> Void)?
    /// Supplies the background used behind the Duo content host, including the
    /// intentional top breathing room. The host may derive it from the active
    /// section so that the strip has the same color as the visible page.
    public var contentBackgroundColorProvider: (() -> UIColor)?
    /// Supplies independent master/detail colors for the Duo top breathing
    /// room. Paired pages can legitimately use different backgrounds.
    public var contentBackgroundColorsProvider: (() -> (master: UIColor, detail: UIColor))?
    /// The controller that currently owns the visible content surface.
    ///
    /// In a paired Duo layout a section's root navigation controller remains
    /// mounted as the master while its child stack is moved to the detail
    /// column. Hosts that derive shell chrome (for example the top design
    /// breathing room) must therefore inspect the visible detail controller,
    /// rather than always reading the section root.
    public var activeContentViewController: UIViewController? {
      guard sections.indices.contains(selectedSectionIndex) else { return nil }
      if selectedSectionIndex == 0 {
        if decision?.mode == .medium || decision?.mode == .expanded {
          return detailHost.navigationControllerContent.visibleViewController
        }
        return conversationCoordinator.navigationController.visibleViewController
      }
      if sectionHosts.indices.contains(selectedSectionIndex),
         let detail = sectionHosts[selectedSectionIndex].splitDetail,
         !detail.viewControllers.isEmpty {
        return detail.visibleViewController
      }
      return sections[selectedSectionIndex].visibleViewController
    }
    /// Provide the host's themed navigation subclass for section detail pages.
    public var sectionDetailNavigationFactory: (() -> UINavigationController)?
    /// Bind the same presentation handlers used by the original section stacks.
    public var onSectionDetailNavigationCreated: ((UINavigationController) -> Void)?
    public var onCompactChatVisibilityChanged: ((UIViewController, Bool) -> Void)?
    public var onConversationOpened: ((String) -> Void)?
    public var sectionEmptyDetailFactory: ((Int) -> UIViewController)?
    /// 并排双栏下右列是否处于空白占位（宿主据此点亮/取消左列选中高亮）。
    /// 折叠或降级为单栏时恒为 true：此时没有并排的左列，不应保留选中效果。
    public var onDetailPlaceholderChanged: ((Bool) -> Void)?
    private let rail = UIStackView()
    private let railBackground = UIView()
    private let railScroll = UIScrollView()
    private let backButton = UIButton(type: .system)
    /// 页面右侧操作迁移到侧栏后的垂直按钮组，固定在返回按钮下方。
    private let railActionStack = UIStackView()
    /// 每个动作按钮的承载容器：按钮与数量角标是兄弟视图，保证角标绘制在按钮描边之上。
    private var railActionContainers: [UIView] = []
    private var railActionButtons: [UIButton] = []
    private var railActionBadges: [UILabel] = []
    private var railActions: [NEAdaptiveRailAction] = []
    private var railBackHandler: (() -> Void)?
    /// 列内嵌 overlay（如 AI 划词搜）的返回拦截：存在时 rail 返回先关闭 overlay。
    private var adaptiveOverlayDismissHandler: (() -> Void)?
    private var adaptiveOverlayPresented = false
    /// 侧栏承载链（列顶页面 + 列内 present 页面）的入口绑定；每页一份，互不覆盖。
    private var railNavigationBindings: [ObjectIdentifier: NEAdaptiveRailPageNavigation] = [:]
    private var railRefreshScheduled = false
    /// 页面自绘导航栏的动作变化通知（名称由 NEBaseUIKit 的 `NENavigationView` 发布）。
    private var railNavigationObservation: NSObjectProtocol?
    private let fallbackTabBar = UITabBar()
    private let contentHost = UIView()
    private let contentTopMasterGap = UIView()
    private let contentTopDetailGap = UIView()
    private let dividerView = UIView()
    private var sectionHosts: [NEAdaptiveSectionHost] = []
    private var sectionStackObservations: [NEAdaptiveNavigationObserver] = []
    private var chatStackObservation: NEAdaptiveNavigationObserver?
    private var railButtons: [UIButton] = []
    private var railBadgeViews: [UIView] = []
    private var context: NEAdaptiveWindowContext?
    private weak var observedWindow: UIWindow?
    /// Whether roots are currently presented beside detail columns.
    public var isShowingPairedContent: Bool { decision?.mode == .medium || decision?.mode == .expanded }
    /// Whether the shell currently owns the content geometry.
    ///
    /// Compact Duo still has an app-owned trailing rail, so its lists must use
    /// the same horizontal safe-area and scroll-indicator policy as paired
    /// columns. Only the legacy fallback gives that ownership back to UIKit.
    public var isUsingAdaptiveLayout: Bool { !isUsingLegacyLayout && decision?.mode != nil }
    private var decision: NEAdaptiveLayoutDecision?
    private var compactShowsDetail = false
    private var legacyFallbackPending = false
    private var shellVisible = false
    private var isTransferringConversationSectionChild = false
    override public var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

    public init(sections: [UINavigationController], detailNavigationController: UINavigationController,
                configuration: NEAdaptiveShellConfiguration) {
      precondition(!sections.isEmpty)
      self.sections = sections; self.configuration = configuration
      detailHost = NEChatDetailHostController(navigationController: detailNavigationController)
      conversationCoordinator = NEConversationNavigationCoordinator(navigationController: detailNavigationController)
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    deinit {
      // 销毁前归还原页面入口，避免 hidesBackButton / alpha 残留在页面导航栏上。
      restoreRailPageNavigation()
      if let railNavigationObservation {
        NotificationCenter.default.removeObserver(railNavigationObservation)
      }
    }

    /// 全屏预览（图片/视频/文件）由外壳 present 时，折叠/展开会在预览期间重排外壳，
    /// 此时 rail 被隐藏；dismiss 本身不触发布局，需要在外壳关闭后重新计算可见性。
    override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
      super.dismiss(animated: flag) { [weak self] in
        completion?()
        guard let self, self.isViewLoaded else { return }
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
      }
    }

    override public func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      view.setNeedsLayout()
    }

    override public func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = configuration.contentBackgroundColor
      contentHost.clipsToBounds = true; view.addSubview(contentHost)
      contentHost.backgroundColor = configuration.contentBackgroundColor
      for gap in [contentTopMasterGap, contentTopDetailGap] {
        gap.isUserInteractionEnabled = false
        gap.backgroundColor = configuration.contentBackgroundColor
        view.addSubview(gap)
      }
      rail.axis = .vertical; rail.alignment = .fill; rail.spacing = configuration.railItemSpacing
      view.addSubview(railBackground); view.addSubview(railScroll); railScroll.addSubview(rail)
      railScroll.showsVerticalScrollIndicator = false
      railScroll.contentInsetAdjustmentBehavior = .never
      NotificationCenter.default.addObserver(forName: Notification.Name("NEAdaptiveOverlayDidPresent"),
                                             object: nil, queue: .main) { [weak self] note in
        guard let self else { return }
        self.adaptiveOverlayDismissHandler = note.userInfo?["dismiss"] as? () -> Void
        self.adaptiveOverlayPresented = true
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
      }
      NotificationCenter.default.addObserver(forName: Notification.Name("NEAdaptiveOverlayDidDismiss"),
                                             object: nil, queue: .main) { [weak self] _ in
        guard let self else { return }
        self.adaptiveOverlayDismissHandler = nil
        self.adaptiveOverlayPresented = false
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
      }
      NotificationCenter.default.addObserver(forName: Notification.Name("NEAdaptivePreviewDidDismiss"),
                                             object: nil, queue: .main) { [weak self] _ in
        // 图片/视频预览由窗口级 presenter 呈现，关闭时外壳不一定收到 dismiss/布局回调；
        // 预览消失后异步重排，恢复 rail/section 入口。
        DispatchQueue.main.async {
          guard let self, self.isViewLoaded else { return }
          self.view.setNeedsLayout()
          self.view.layoutIfNeeded()
        }
      }
      NotificationCenter.default.addObserver(forName: Notification.Name("NEAdaptivePresentationDidChange"),
                                             object: nil, queue: .main) { [weak self] _ in
        // present/dismiss 不触发布局回调；先同步压制顶层页入口（避免转场首帧露出），
        // 再异步刷新侧栏按钮位置。
        self?.prepareRailNavigationForPresentationChange()
      }
      // 页面动态改右侧按钮文案（如「确定(10)」）时刷新侧栏；没有 NEBaseUIKit 的
      // 宿主可调用 `refreshRailNavigation()` 达到同样效果。
      railNavigationObservation = NotificationCenter.default.addObserver(
        forName: Notification.Name("NENavigationViewDidChangeActions"),
        object: nil, queue: .main
      ) { [weak self] _ in
        self?.refreshRailNavigation()
      }
      railActionStack.axis = .vertical
      railActionStack.alignment = .center
      railActionStack.spacing = configuration.railActionSpacing
      railActionStack.isHidden = true
      view.addSubview(railActionStack)
      view.addSubview(backButton)
      applyBackButtonStyle()
      backButton.accessibilityIdentifier = "id.adaptive.back"
      backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
      fallbackTabBar.delegate = self
      fallbackTabBar.items = sections.map(\.tabBarItem)
      fallbackTabBar.selectedItem = sections[0].tabBarItem
      fallbackTabBar.isHidden = true
      view.addSubview(fallbackTabBar)
      sectionHosts = sections.map { NEAdaptiveSectionHost($0) }
      for (index, host) in sectionHosts.enumerated().dropFirst() {
        host.makeDetailNavigation = { [weak self] in self?.sectionDetailNavigationFactory?() ?? UINavigationController() }
        host.makeEmptyDetail = { [weak self] in self?.sectionEmptyDetailFactory?(index) ?? UIViewController() }
        host.onDetailNavigationCreated = { [weak self] in self?.onSectionDetailNavigationCreated?($0) }
        host.onStackChanged = { [weak self] in
          self?.layoutContent()
        }
      }
      sectionStackObservations = sections.map { navigation in
        let observer = NEAdaptiveNavigationObserver(navigation) { [weak self] in
          guard let self, self.isViewLoaded else { return }
          self.layoutContent()
        }
        observer.willShow = { [weak self] page in self?.prepareRailNavigationBeforeTransition(page) }
        return observer
      }
      chatStackObservation = NEAdaptiveNavigationObserver(conversationCoordinator.navigationController) { [weak self] in
        self?.layoutContent()
      }
      chatStackObservation?.willShow = { [weak self] page in self?.prepareRailNavigationBeforeTransition(page) }
      // 官方指引：alert、sheet 等系统组件应做窗口级呈现，由系统处理折叠区避让。
      // 因此外壳不再把每栏导航设为 presentation context；需要限定在栏内的
      // 页面（如文本详情）在自身 present 前显式设置。
      // Keep the existing navigation stacks directly under the shell. UIKit's
      // split container automatically wraps non-navigation hosts in private
      // navigation controllers, which changes appearance ownership and can
      // collapse a host to the navigation bar height on Duo.
      addChild(sectionHosts[0]); contentHost.addSubview(sectionHosts[0].view); sectionHosts[0].didMove(toParent: self)
      addChild(detailHost); contentHost.addSubview(detailHost.view); detailHost.didMove(toParent: self)
      for host in sectionHosts.dropFirst() {
        addChild(host); contentHost.addSubview(host.view); host.didMove(toParent: self); host.view.isHidden = true
      }
      dividerView.isUserInteractionEnabled = false
      dividerView.isHidden = true
      dividerView.accessibilityIdentifier = "id.adaptive.chat.divider"
      contentHost.addSubview(dividerView)
      for (index, section) in sections.enumerated() {
        let button = UIButton(type: .system)
        button.tag = index; button.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(sectionTapped(_:)), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: configuration.railItemHeight).isActive = true
        let badge = UIView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.backgroundColor = .systemRed
        badge.layer.cornerRadius = 4
        badge.isHidden = true
        badge.isUserInteractionEnabled = false
        button.addSubview(badge)
        NSLayoutConstraint.activate([
          badge.widthAnchor.constraint(equalToConstant: 8),
          badge.heightAnchor.constraint(equalToConstant: 8),
          badge.topAnchor.constraint(equalTo: button.topAnchor, constant: 8),
          badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -8),
        ])
        rail.addArrangedSubview(button); railButtons.append(button); railBadgeViews.append(badge)
        button.accessibilityIdentifier = section.tabBarItem.accessibilityIdentifier
      }
      updateRailItems()
    }

    override public func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated); shellVisible = true; refreshWindow(); updateVisibility()
    }

    override public func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated); shellVisible = false; updateVisibility()
    }

    override public func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews(); refreshWindow(); layoutContent()
    }

    override public func viewSafeAreaInsetsDidChange() { super.viewSafeAreaInsetsDidChange(); refreshWindow() }
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
      super.viewWillTransition(to: size, with: coordinator)
      coordinator.animate(alongsideTransition: { [weak self] _ in self?.refreshWindow() }, completion: { [weak self] _ in self?.refreshWindow() })
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection); refreshWindow()
    }

    /// SceneDelegate can forward scene updates here. Root/safe-area/trait updates are automatic.
    public func refreshWindow() {
      guard isViewLoaded, let window = view.window else { return }
      if observedWindow !== window {
        context?.invalidate()
        observedWindow = window
        context = NEAdaptiveWindowContext(window: window) { [weak self] snapshot in self?.apply(snapshot) }
      }
      context?.refresh()
    }

    public func invalidateWindowContext() { context?.invalidate(); context = nil; observedWindow = nil }

    /// Detaches retained section navigation stacks as one operation for a host
    /// that is leaving adaptive presentation. The shell remains responsible for
    /// its detail stack; callers must only use this while no active chat exists.
    public func detachSectionsForLegacyTransfer() -> [UINavigationController] {
      restoreRailPageNavigation()
      restoreHostedTrailingSafeArea()
      for (index, host) in sectionHosts.enumerated() {
        host.detachContentForTransfer()
        host.content.delegate = sectionStackObservations[index].originalDelegate
      }
      sectionStackObservations = []
      return sections
    }

    /// 尾部 rail 区域由外壳统一接管，宿主页面不应再继承窗口的尾部安全区。
    ///
    /// Duo 折叠外屏的窗口尾部有 84pt 系统状态区，外壳已把列宽收到 rail 左侧；
    /// 页面却仍继承整段尾部安全区，UIKit 便按它把左滑操作按钮从操作容器内缩
    /// （实测“删除”按钮距列尾 94pt）。这里按页面抵消继承值，让行尾控件与左滑
    /// 操作回到列宽边界；交还旧版布局时恢复。
    private func suppressHostedTrailingSafeArea() {
      for navigation in hostedNavigations {
        for page in navigation.viewControllers {
          guard page.isViewLoaded else { continue }
          let owned = NEAdaptiveTrailingInset.cancellation(
            safeAreaRight: page.view.safeAreaInsets.right,
            applied: page.additionalSafeAreaInsets.right)
          if abs(page.additionalSafeAreaInsets.right - owned) > 0.5 {
            page.additionalSafeAreaInsets.right = owned
          }
        }
      }
    }

    /// 交还列宽给宿主（旧版 tab 布局）时撤销尾部安全区补偿。
    private func restoreHostedTrailingSafeArea() {
      for navigation in hostedNavigations {
        for page in navigation.viewControllers where page.isViewLoaded {
          if page.additionalSafeAreaInsets.right != 0 {
            page.additionalSafeAreaInsets.right = 0
          }
        }
      }
    }

    @discardableResult public func openConversation(_ intent: NEConversationOpenIntent) -> Bool {
      dismissColumnPresentations()
      // 从通讯录/我的分区打开会话：共享详情列先回到会话列表的空占位，再压入聊天页。
      // 否则聊天返回后右列仍停留在该分区的占位（例如「请选择联系人」），
      // 而左列已经切回会话列表，出现文案与分区不一致。
      if selectedSectionIndex != 0 {
        conversationCoordinator.reset()
      }
      compactChatOriginSection = decision?.mode == .compact && selectedSectionIndex != 0
        ? selectedSectionIndex : nil
      guard conversationCoordinator.open(intent) else { return false }
      // 从列表页再次打开会话时必须清掉"只看列表"的偏好，
      // 否则布局仍按列表展示，表现为点击会话无反应。
      prefersConversationList = false
      compactShowsDetail = true
      if selectedSectionIndex != 0 {
        selectedSectionIndex = 0
        updateRailItems()
        onSectionSelected?(0)
      }
      layoutContent()
      refreshRailNavigation()
      if let cid = intent.parameters["conversationId"] as? String { onConversationOpened?(cid) }
      return true
    }

    /// Clears the retained chat when its conversation is deleted or the user
    /// leaves/disbands the team. The same transition is used for compact and
    /// paired Duo layouts so a stale detail controller cannot remain visible.
    public func clearConversationIfNeeded(_ conversationId: String) {
      guard let activeIntent = conversationCoordinator.activeIntent,
            activeIntent.parameters["conversationId"] as? String == conversationId else {
        return
      }
      dismissColumnPresentations()
      conversationCoordinator.reset()
      compactShowsDetail = false
      layoutContent()
    }

    /// Clears the current detail after a team leave/disband notification.
    public func clearActiveConversation() {
      guard conversationCoordinator.activeIntent != nil else { return }
      dismissColumnPresentations()
      conversationCoordinator.reset()
      compactShowsDetail = false
      layoutContent()
    }

    /// D-C returns exactly once to the list. The current conversation is
    /// closed and the detail column returns to its empty placeholder, so a
    /// later expansion cannot reveal the chat that was already left.
    public func showConversationList() {
      guard selectedSectionIndex == 0, decision?.mode == .compact || isUsingLegacyLayout else { return }
      if restoreCompactChatOriginSection() {
        return
      }
      // 折叠态从聊天返回列表：关闭当前会话，右列回到空白占位。
      // 这样展开后右侧不会重新露出已经返回的聊天详情。
      // legacy 回退继续沿用原导航行为，避免改变旧外壳语义。
      if !isUsingLegacyLayout {
        dismissColumnPresentations()
        conversationCoordinator.reset()
      }
      prefersConversationList = true
      compactShowsDetail = false
      layoutContent()
    }

    public func selectSection(_ index: Int) {
      guard sections.indices.contains(index) else { return }
      compactChatOriginSection = nil
      dismissColumnPresentations()
      prefersConversationList = false
      let changed = selectedSectionIndex != index
      if index == 0 {
        // Returning to Messages always starts at its retained list placeholder.
        // This also handles tapping the already-selected rail item while a
        // compact chat detail is visible.
        conversationCoordinator.reset()
        if let root = sections[0].viewControllers.first, sections[0].viewControllers.count > 1 {
          sections[0].setViewControllers([root], animated: false)
        }
        compactShowsDetail = false
      } else if sectionHosts.indices.contains(index) {
        // A tab switch always starts the selected section at its empty detail
        // state. Reset every section detail stack while the rail selection
        // changes so returning to Contacts or Mine cannot reveal a stale child
        // page from the previous visit. The root navigation controllers and
        // their data owners remain intact.
        for host in sectionHosts.dropFirst() { host.resetDetail() }
        // 统一：右列展示"该分区"的占位页（不能再用消息分区的 reset()，那会显示"请选择会话"）。
        conversationCoordinator.showPlaceholder(sectionEmptyDetailFactory?(index) ?? UIViewController())
        compactShowsDetail = false
      }
      // The root section controllers remain retained; only their detail stacks
      // are reset above so every tab entry starts from its empty placeholder.
      selectedSectionIndex = index
      updateRailItems()
      if changed { onSectionSelected?(index) }
      layoutContent()
    }

    /// Call before the original root-navigation push. False leaves the original
    /// push untouched in a compact window. Deeper detail pushes use their own stack.
    @discardableResult public func presentSectionChild(_ controller: UIViewController,
                                                       from navigationController: UINavigationController,
                                                       animated: Bool) -> Bool {
      guard let index = sections.firstIndex(where: { $0 === navigationController }),
            decision?.mode == .medium || decision?.mode == .expanded,
            !isUsingLegacyLayout, controller.parent == nil else { return false }
      if index == 0 {
        // The conversation list is the retained master column. Its first-level
        // pages (search, add friend, member selection, and group creation)
        // belong in the existing chat detail navigation so the list remains
        // visible. Compact and legacy windows never enter this branch.
        let detail = conversationCoordinator.navigationController
        guard !detail.viewControllers.isEmpty else { return false }
        dismissColumnPresentations()
        if NEAdaptivePageStack.reuseExistingPage(for: controller, in: detail) { return true }
        // 会话列表的一级页面（搜索、添加好友、分组等）共用同一个层级：
        // 已有聊天页时压在其上，返回回到聊天；没有聊天页时原地替换前一个
        // 一级页面，使返回始终回到会话列表，而不是退回上一个动作页。
        // 一级页面（搜索、添加好友等）采用"重置右列"的呈现方式：
        // 清掉正在展示的聊天，让一级页面成为右列根，返回直接回到空占位，
        // 而不是退回聊天页。
        if conversationCoordinator.activeIntent != nil {
          conversationCoordinator.reset()
        }
        if let base = conversationCoordinator.currentPlaceholder, base !== controller {
          detail.setViewControllers([base, controller], animated: false)
        } else {
          detail.setViewControllers([controller], animated: false)
        }
        layoutContent()
        // 非动画换栈不一定触发 willShow：延后校正一次，确保页面出现前入口已隐藏。
        refreshRailNavigation()
        return true
      }
      let sharedDetail = conversationCoordinator.navigationController
      guard !sharedDetail.viewControllers.isEmpty else { return false }
      dismissColumnPresentations()
      if NEAdaptivePageStack.reuseExistingPage(for: controller, in: sharedDetail) { return true }
      // 保留占位页作为栈底、页面压栈顶（栈深 2）：这些子页面按"栈中页"
      // 设计，栈深 > 1 才会显示返回按钮并预留导航栏高度，与群设置页一致。
      let base = conversationCoordinator.currentPlaceholder ?? UIViewController()
      sharedDetail.setViewControllers([base, controller], animated: false)
      layoutContent()
      // 非动画换栈不一定触发 willShow：延后校正一次，确保页面出现前入口已隐藏。
      refreshRailNavigation()
      return true
    }

    /// 单屏聊天返回入口的系统返回样式。
    ///
    /// 系统导航栏的返回入口使用 `chevron.left`；这里复用同一 SF Symbol 和
    /// 字重，保证侧栏返回与系统返回按钮在形状、粗细上一致，而不是各皮肤
    /// 自绘的返回箭头。找不到系统符号时才退回接入方提供的图片。
    private func applyBackButtonStyle() {
      if configuration.usesSystemBackButtonStyle {
        let symbol = UIImage(systemName: "chevron.left",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold))
        backButton.setImage(symbol ?? configuration.backImage, for: .normal)
      } else {
        backButton.setImage(configuration.backImage, for: .normal)
      }
      backButton.tintColor = configuration.backTintColor
      backButton.accessibilityLabel = configuration.backAccessibilityLabel
      // 产品稿：返回入口与右侧操作使用同一套圆形控件（浅色底 + 细描边）。
      backButton.backgroundColor = configuration.railControlBackgroundColor
      backButton.layer.cornerRadius = configuration.railBackButtonSize / 2
      backButton.layer.borderWidth = configuration.railControlBorderWidth
      backButton.layer.borderColor = configuration.railControlBorderColor.cgColor
      backButton.clipsToBounds = true
    }

    public func updateRailItems() {
      guard isViewLoaded else { return }
      applyBackButtonStyle()
      railBackground.backgroundColor = configuration.railBackgroundColor
      fallbackTabBar.tintColor = configuration.selectedTintColor
      fallbackTabBar.selectedItem = sections[selectedSectionIndex].tabBarItem
      for (index, button) in railButtons.enumerated() {
        let item = sections[index].tabBarItem!
        let selected = selectedSectionIndex == index
        var appearance = UIButton.Configuration.plain()
        appearance.title = item.title
        appearance.image = selected ? (item.selectedImage ?? item.image) : item.image
        appearance.imagePlacement = .top
        appearance.imagePadding = 8
        appearance.contentInsets = .zero
        appearance.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
          var attributes = attributes
          attributes.font = UIFont.systemFont(ofSize: 12, weight: .regular)
          return attributes
        }
        button.configuration = appearance
        button.tintColor = selected ? configuration.selectedTintColor : configuration.normalTintColor
        button.accessibilityLabel = item.title
        button.accessibilityValue = item.badgeValue
        button.accessibilityTraits = selected ? [.button, .selected] : [.button]
        if railBadgeViews.indices.contains(index) {
          railBadgeViews[index].isHidden = item.badgeValue == nil
        }
      }
    }

    @objc private func sectionTapped(_ sender: UIButton) { selectSection(sender.tag) }

    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
      guard let index = sections.firstIndex(where: { $0.tabBarItem === item }) else { return }
      selectSection(index)
    }

    @objc private func backTapped() {
      if let dismiss = adaptiveOverlayDismissHandler {
        adaptiveOverlayDismissHandler = nil
        dismiss()
        view.setNeedsLayout()
        return
      }
      // 折叠态从通讯录等分区进入聊天时，返回优先回到来源分区；
      // 页面自身的返回 binding 不能越过这个来源信息。
      if restoreCompactChatOriginSection() {
        view.setNeedsLayout()
        return
      }
      railBackHandler?()
      view.setNeedsLayout()
    }

    /// 恢复折叠态聊天的来源分区；没有来源或已展开时返回 false。
    @discardableResult
    private func restoreCompactChatOriginSection() -> Bool {
      guard !isUsingLegacyLayout, decision?.mode == .compact,
            let origin = compactChatOriginSection else { return false }
      compactChatOriginSection = nil
      dismissColumnPresentations()
      conversationCoordinator.reset()
      compactShowsDetail = false
      prefersConversationList = false
      selectedSectionIndex = origin
      updateRailItems()
      onSectionSelected?(origin)
      layoutContent()
      return true
    }

    @objc private func railActionTapped(_ sender: UIButton) {
      guard railActions.indices.contains(sender.tag) else { return }
      railActions[sender.tag].perform()
    }

    /// present/dismiss 发生时立即重解析承载链并压制入口；不做整页布局，避免打断转场。
    private func prepareRailNavigationForPresentationChange() {
      guard isViewLoaded, isUsingAdaptiveLayout else { return }
      let compactChat = decision?.mode == .compact && selectedSectionIndex == 0 && compactShowsDetail
      syncRailNavigation(legacy: false, compactChat: compactChat)
      view.setNeedsLayout()
      refreshRailNavigation()
    }

    /// 宿主在页面导航栏文案/启用态发生变化后主动刷新侧栏按钮。
    public func refreshRailNavigation() {
      guard isViewLoaded, !railRefreshScheduled else { return }
      railRefreshScheduled = true
      DispatchQueue.main.async { [weak self] in
        guard let self, self.isViewLoaded else { return }
        self.railRefreshScheduled = false
        self.layoutContent()
      }
    }

    /// 侧栏所在列的 present 解析结果。
    private struct RailColumnResolution {
      /// 列顶页面及其列内 present 链（从底到顶），截断到第一个遮挡型 present 之前。
      let pages: [UIViewController]
    }

    /// 解析侧栏所在列：折叠态是唯一内容页，双栏是右列页；并沿 present 链取到底。
    ///
    /// 只有 `.overCurrentContext` 且呈现上下文确实落在该列的页面才视为“列内覆盖”，
    /// 这类页面可以把自己的返回/右侧入口交给侧栏。全屏/pageSheet/custom 等呈现
    /// 会遮挡或压暗侧栏，侧栏保持呈现前的页面状态，避免依赖关闭通知而丢失返回；
    /// UIAlertController 属系统窗口级弹层，同样不参与列内链。
    ///
    /// 与 present 并列的还有“列内嵌页面”：页面用 `addChild` 把子控制器挂到承载页上
    /// 并覆盖整列（如分组名称表单）。它不是 present 链的一部分，必须按显式标记并入
    /// 承载链，否则侧栏会继续展示被覆盖页面的返回/右侧动作。
    private func resolveRailColumnPresentation() -> RailColumnResolution {
      guard isUsingAdaptiveLayout else { return RailColumnResolution(pages: []) }
      let navigation: UINavigationController
      if isShowingPairedContent {
        navigation = detailHost.navigationControllerContent
      } else if selectedSectionIndex == 0 {
        navigation = compactShowsDetail
          ? conversationCoordinator.navigationController
          : sections[0]
      } else {
        guard sections.indices.contains(selectedSectionIndex) else {
          return RailColumnResolution(pages: [])
        }
        navigation = sections[selectedSectionIndex]
      }
      // 列顶页面用导航栈顶而不是 `visibleViewController`：后者在有 present 页面时
      // 可能直接返回 present 页面，导致底层承载页从链里丢失。
      let base = navigation.viewControllers.last
      var pages = base.map { [$0] } ?? []
      var presented = navigation.presentedViewController ?? base?.presentedViewController
      while let current = presented {
        // 系统 alert/action sheet 由窗口级容器管理，关闭时机不能稳定感知；
        // 它本身会遮罩侧栏，保持底层侧栏状态即可。
        if current is UIAlertController { break }
        let presenter = current.presentingViewController
        let previous = pages.last
        let insideColumn = presenter === navigation || presenter === previous
          || (presenter.map { $0.view.isDescendant(of: navigation.view) } ?? false)
        guard current.modalPresentationStyle == .overCurrentContext, insideColumn else {
          // 遮挡型 present：侧栏保持呈现前页面（presenter）的动作，关闭后无需刷新。
          break
        }
        let resolved = (current as? UINavigationController)?.visibleViewController ?? current
        pages.append(resolved)
        presented = resolved.presentedViewController
      }
      if let overlay = Self.columnOverlayPage(in: pages.last) {
        pages.append(overlay)
      }
      return RailColumnResolution(pages: pages)
    }

    /// 列内嵌页面的接入约定：直接挂在承载页下、覆盖整列，并在根视图上以
    /// `id.adaptive.columnOverlay` 声明接管侧栏入口。
    ///
    /// 用显式标记而不是扫描任意子控制器，避免把页面内部的容器子控制器误判成
    /// 当前页；未标记的子页面保持原行为，侧栏仍属承载页。
    private static func columnOverlayPage(in page: UIViewController?) -> UIViewController? {
      guard let page else { return nil }
      return page.children.reversed().first {
        $0.isViewLoaded && $0.view.accessibilityIdentifier == "id.adaptive.columnOverlay"
      }
    }

    /// 每轮布局把页面导航栏的返回/右侧按钮同步到侧栏，并在页面切换时归还原入口。
    private func syncRailNavigation(legacy: Bool, compactChat: Bool) {
      if legacy {
        restoreRailPageNavigation()
        railActions = []
        updateRailActionButtons()
        railBackHandler = compactChat ? { [weak self] in self?.showConversationList() } : nil
        return
      }
      let chain = resolveRailColumnPresentation().pages
      let chainKeys = Set(chain.map { ObjectIdentifier($0) })
      // 离开承载链的页面（pop / dismiss / 切换列）归还原入口。
      for key in Array(railNavigationBindings.keys) where !chainKeys.contains(key) {
        railNavigationBindings[key]?.onChange = nil
        railNavigationBindings[key]?.restore()
        railNavigationBindings[key] = nil
      }
      // 链上每一页都保持压制，避免叠加 present 时底层页面的返回/动作重新露出；
      // 侧栏只展示最上层页面的入口。
      for page in chain {
        _ = bindRailNavigationIfNeeded(for: page)
      }
      let topPage = chain.last
      let topBinding = topPage.flatMap { railNavigationBindings[ObjectIdentifier($0)] }
      railActions = topBinding?.trailingActions() ?? []
      updateRailActionButtons()
      railBackHandler = makeRailBackHandler(page: topPage, compactChat: compactChat, binding: topBinding)
    }

    /// 为承载页建立（或复用）入口绑定，并立即隐藏页面自己的入口。
    ///
    /// 页面可能在首次出现时切换导航模式（自绘标题栏 ↔ 系统导航），因此每次
    /// 同步都校验绑定是否仍然有效；失效时重新解析，避免旧绑定让返回按钮残留。
    @discardableResult
    private func bindRailNavigationIfNeeded(for page: UIViewController) -> NEAdaptiveRailPageNavigation? {
      let key = ObjectIdentifier(page)
      if let existing = railNavigationBindings[key] {
        if existing.isValid(for: page) {
          existing.refreshSuppressedSystemItems()
          return existing
        }
        existing.onChange = nil
        existing.restore()
        railNavigationBindings[key] = nil
      }
      page.loadViewIfNeeded()
      guard let binding = NEAdaptiveRailPageNavigation.make(for: page) else { return nil }
      binding.onChange = { [weak self] in self?.refreshRailNavigation() }
      binding.suppress()
      railNavigationBindings[key] = binding
      return binding
    }

    /// 转场开始前先压制即将出现的页面入口，避免“先展示后消失”。
    private func prepareRailNavigationBeforeTransition(_ incoming: UIViewController) {
      guard isViewLoaded, isUsingAdaptiveLayout else { return }
      // 只有紧邻侧栏的那一列才迁移入口；左列根列表保持自己的标题栏。
      let isRailColumn: Bool
      if isShowingPairedContent {
        isRailColumn = incoming.navigationController === detailHost.navigationControllerContent
      } else {
        isRailColumn = incoming.navigationController === conversationCoordinator.navigationController
          || (sections.indices.contains(selectedSectionIndex)
            && incoming.navigationController === sections[selectedSectionIndex])
      }
      if isRailColumn {
        bindRailNavigationIfNeeded(for: incoming)
      } else {
        let compactChat = decision?.mode == .compact && selectedSectionIndex == 0 && compactShowsDetail
        syncRailNavigation(legacy: false, compactChat: compactChat)
      }
      view.setNeedsLayout()
      // 页面可能在自己的 viewWillAppear 里重配导航栏（例如系统导航开关），
      // 转场完成后再校正一次绑定。
      DispatchQueue.main.async { [weak self] in self?.refreshRailNavigation() }
      incoming.navigationController?.transitionCoordinator?.animate(alongsideTransition: nil) {
        [weak self] _ in
        self?.refreshRailNavigation()
      }
    }

    private func restoreRailPageNavigation() {
      for binding in railNavigationBindings.values {
        binding.onChange = nil
        binding.restore()
      }
      railNavigationBindings.removeAll()
    }

    /// 返回入口语义：
    /// - 折叠态单屏聊天根页一次回到列表（D-C）；聊天栈上方的设置页/子页面逐级返回；
    /// - 其它页面优先转发页面自己的返回按钮，保留清理未读、二次确认等语义；
    /// - 页面没有返回按钮但栈深 > 1 时补一个系统返回，避免入口丢失。
    private func makeRailBackHandler(page: UIViewController?, compactChat: Bool,
                                     binding: NEAdaptiveRailPageNavigation?) -> (() -> Void)? {
      guard let page else { return nil }
      // D-C 返回列表只适用于聊天页本身；聊天栈上方的设置页/子页面/present 页面
      // 都必须先逐级返回，不能直接跳回会话列表。
      if compactChat, page === conversationCoordinator.navigationController.viewControllers.first {
        return { [weak self] in self?.showConversationList() }
      }
      if let pageBack = binding?.backAction() {
        return { pageBack.perform() }
      }
      // 页面没有任何可解析的标题栏（例如演示工程的地图占位页）时，仍要提供
      // 栈返回，否则 push 进来后没有可见的返回入口。
      // 只对「真正位于该导航栈顶」的 push 页面补返回：列内嵌页面（文本详情等）
      // 的 navigationController 来自宿主，若据此 pop 会把底层页面退掉。
      if let navigation = page.navigationController,
         navigation.topViewController === page,
         navigation.viewControllers.count > 1 {
        return { [weak navigation] in navigation?.popViewController(animated: true) }
      }
      return nil
    }

    private func updateRailActionButtons() {
      railActionStack.spacing = configuration.railActionSpacing
      let actionSize = configuration.railActionButtonSize
      while railActionButtons.count < railActions.count {
        // 角标挂在承载容器上、位于按钮之后：圆形按钮的图层描边会压住自身子视图，
        // 角标只有作为按钮的兄弟视图，才能完整覆盖在按钮及其描边之上。
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = configuration.railControlBackgroundColor
        button.layer.borderWidth = configuration.railControlBorderWidth
        button.layer.borderColor = configuration.railControlBorderColor.cgColor
        button.layer.cornerRadius = actionSize / 2
        button.titleLabel?.font = configuration.railActionTextFont
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.addTarget(self, action: #selector(railActionTapped(_:)), for: .touchUpInside)
        container.addSubview(button)
        let badge = UILabel()
        badge.textAlignment = .center
        badge.font = .systemFont(ofSize: 11, weight: .semibold)
        badge.textColor = configuration.railBadgeTextColor
        badge.backgroundColor = configuration.railBadgeBackgroundColor ?? configuration.selectedTintColor
        badge.layer.cornerRadius = 10
        badge.clipsToBounds = true
        badge.isHidden = true
        badge.isUserInteractionEnabled = false
        // 按钮的无障碍文案已包含完整计数，角标不再单独朗读。
        badge.isAccessibilityElement = false
        container.addSubview(badge)
        NSLayoutConstraint.activate([
          container.widthAnchor.constraint(equalToConstant: actionSize),
          container.heightAnchor.constraint(equalToConstant: actionSize),
          button.topAnchor.constraint(equalTo: container.topAnchor),
          button.leftAnchor.constraint(equalTo: container.leftAnchor),
          button.rightAnchor.constraint(equalTo: container.rightAnchor),
          button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        railActionStack.addArrangedSubview(container)
        railActionContainers.append(container)
        railActionButtons.append(button)
        railActionBadges.append(badge)
      }
      for (index, button) in railActionButtons.enumerated() {
        let visible = index < railActions.count
        railActionContainers[index].isHidden = !visible
        guard visible else { continue }
        let action = railActions[index]
        button.tag = index
        button.setTitle(action.title, for: .normal)
        // 产品稿：文本型右侧按钮保留原文案，图标型按钮沿用原图标。
        button.setImage(action.title == nil ? action.image : nil, for: .normal)
        button.tintColor = configuration.railActionTextColor
        button.setTitleColor(configuration.railActionTextColor, for: .normal)
        button.setTitleColor(configuration.railActionTextColor.withAlphaComponent(0.4), for: .disabled)
        button.isEnabled = action.isEnabled
        // 侧栏按钮使用独立标识，避免与页面内已隐藏的原入口重名。
        button.accessibilityIdentifier = action.identifier.map { "id.adaptive.action.\($0)" }
        // 视觉只保留操作名 + 角标；无障碍仍读出页面原本的完整文案（含计数）。
        button.accessibilityLabel = action.accessibilityText
        applyRailBadge(railActionBadges[index], text: action.badge)
      }
      railActionStack.isHidden = railActions.isEmpty
    }

    private func applyRailBadge(_ badge: UILabel, text: String?) {
      guard let text, !text.isEmpty else {
        badge.text = nil
        badge.isHidden = true
        return
      }
      badge.text = text
      badge.isHidden = false
      let font = badge.font ?? .systemFont(ofSize: 11, weight: .semibold)
      let width = max(20, (text as NSString).size(withAttributes: [.font: font]).width + 10)
      let size = configuration.railActionButtonSize
      // 角标压在圆形按钮右上角，和产品稿一致；坐标相对承载容器（与按钮同框）。
      badge.frame = CGRect(x: size - width + 4, y: -4, width: width, height: 20)
      badge.layer.cornerRadius = 10
    }

    private func apply(_ snapshot: NEWindowSnapshot) {
      let old = decision
      let wasSinglePage = old?.mode == .compact || isUsingLegacyLayout
      decision = NEAdaptiveLayoutPolicy.resolve(window: .init(width: snapshot.size.width, height: snapshot.size.height,
                                                              top: snapshot.safeAreaTop, left: snapshot.safeAreaLeft, bottom: snapshot.safeAreaBottom, right: snapshot.safeAreaRight), configuration: configuration.policy)
      let enteringFallback = decision?.mode == nil && !isUsingLegacyLayout
      isUsingLegacyLayout = decision?.mode == nil
      if !wasSinglePage, decision?.mode == .compact || isUsingLegacyLayout {
        compactShowsDetail = conversationCoordinator.activeIntent != nil
      }
      if enteringFallback {
        legacyFallbackPending = conversationCoordinator.activeIntent != nil
      }
      layoutContent()
    }

    private func layoutContent() {
      guard isViewLoaded else { return }
      let enteringFallback = syncDecisionToCurrentViewBounds()
      guard let decision else { return }
      if decision.mode != .compact {
        compactChatOriginSection = nil
      }
      // 用户从聊天页返回占位后，不能继续用旧 intent 判断“右列仍打开会话”。
      _ = conversationCoordinator.syncActiveIntentWithNavigationStack()
      syncDetailStackAcrossPosture(paired: decision.mode == .medium || decision.mode == .expanded)
      // Resolve visibility before changing frames or installing a split detail
      // host. This prevents the previous section's right-column controller
      // from being painted for one frame while the new root is being laid out.
      updateVisibility()
      let safe = view.bounds.inset(by: view.safeAreaInsets)
      let legacy = isUsingLegacyLayout
      let railWidth = configuration.railWidth
      let railX = configuration.railUsesTrailingEdge
        ? view.bounds.maxX - railWidth
        : safe.maxX - railWidth
      // 每轮布局读取一次系统占位区，供侧栏返回/标签定位使用。
      let railMetrics = reservedRegionMetrics(railMinX: railX)
      let tabHeight = legacy ? min(49, max(0, safe.height)) : 0
      let contentWidth = legacy ? safe.width : railX - safe.minX
      // Safe-area top is the only shell-owned content inset. Extend the host to
      // the physical bottom so child safe-area constraints own the home-indicator
      // spacing instead of leaving a second blank strip below the shell.
      let contentBottom = legacy ? safe.maxY - tabHeight : view.bounds.maxY
      // Duo keeps a small design gap above the hosted page. Its color is
      // resolved from the active section so the strip remains continuous.
      let contentTop = legacy
        ? safe.minY
        : view.bounds.minY + max(0, configuration.contentTopInset)
      contentHost.frame = CGRect(x: safe.minX, y: contentTop,
                                 width: max(0, contentWidth), height: max(0, contentBottom - contentTop))
      let topGapHeight = legacy ? 0 : max(0, contentTop - view.bounds.minY)
      let masterGapWidth = legacy ? 0 : min(max(0, decision.masterWidth), contentHost.bounds.width)
      let detailGapX = safe.minX + masterGapWidth + (legacy ? 0 : configuration.dividerWidth)
      let detailGapWidth = legacy ? 0 : max(0, contentHost.bounds.width - masterGapWidth - configuration.dividerWidth)
      contentTopMasterGap.frame = CGRect(x: safe.minX, y: view.bounds.minY,
                                          width: masterGapWidth, height: topGapHeight)
      contentTopDetailGap.frame = CGRect(x: detailGapX, y: view.bounds.minY,
                                         width: detailGapWidth, height: topGapHeight)
      // Keep the breathing-room views hidden while a split host is being
      // installed or its navigation stack is being transferred. The host
      // publishes its final master/detail controllers later in this layout
      // pass; showing the gap before its themed colors are resolved exposes a
      // one-frame white strip on the right that then changes color.
      contentTopMasterGap.isHidden = true
      contentTopDetailGap.isHidden = true
      fallbackTabBar.isHidden = !legacy
      fallbackTabBar.frame = CGRect(x: safe.minX, y: safe.maxY - tabHeight, width: max(0, safe.width), height: tabHeight)
      rail.isHidden = legacy
      railScroll.isHidden = legacy
      railBackground.isHidden = legacy
      let compactChat = (decision.mode == .compact || legacy) && selectedSectionIndex == 0 && compactShowsDetail
      // 页面导航栏的返回与右侧按钮统一迁移到侧栏；折叠态和双栏右列同一套规则，
      // 左列根列表与空占位不迁移，仍由页面自己的标题栏承担。
      syncRailNavigation(legacy: legacy, compactChat: compactChat)
      let showsBack = legacy
        ? (compactChat && conversationCoordinator.navigationController.viewControllers.count == 1)
        : (railBackHandler != nil)
      let showsRailActions = !legacy && !railActions.isEmpty
      let compactSectionChild = decision.mode == .compact && selectedSectionIndex > 0
        && (sections[selectedSectionIndex].viewControllers.count > 1
          || (sectionHosts[selectedSectionIndex].splitDetail?.viewControllers.count ?? 0) > 1)
      // Messages keeps its list navigation in the source stack while compact.
      // Treat its first-level pages (search, more, conversation groups, etc.)
      // the same as Contacts/My children so the section tabs stay collapsed.
      let compactConversationSectionChild = decision.mode == .compact
        && selectedSectionIndex == 0
        && sections[0].viewControllers.count > 1
      // Single-page children keep the rail return/action but hide section tabs.
      let showsRailItems = !legacy && !compactChat && !compactSectionChild && !compactConversationSectionChild
      railBackground.frame = CGRect(x: railX, y: legacy ? safe.minY : view.bounds.minY, width: configuration.railWidth, height: legacy ? safe.height : view.bounds.height)
      let railHeight = CGFloat(sections.count) * configuration.railItemHeight
        + CGFloat(max(0, sections.count - 1)) * configuration.railItemSpacing
      let backSize = configuration.railBackButtonSize
      let actionSize = configuration.railActionButtonSize
      let actionsHeight = showsRailActions
        ? CGFloat(railActions.count) * actionSize
        + CGFloat(max(0, railActions.count - 1)) * configuration.railActionSpacing
        : 0
      // Keep app controls below the host's trailing status region. The content
      // top safe area only protects the content to its left, not this rail.
      // 官方做法：按 reserved region 的实际 frame 避让系统占位区，
      // 只有拿不到占位区信息时（iOS < 27.1 等）才退回设计常量。
      var backTop: CGFloat
      if legacy {
        backTop = contentTop
      } else if let occlusionBottom = railMetrics.railOcclusionBottom {
        backTop = min(max(contentTop, occlusionBottom), max(contentTop, safe.maxY - backSize))
      } else {
        backTop = min(max(contentTop, view.bounds.minY + configuration.railBackTopInset), max(contentTop, safe.maxY - backSize))
      }
      // 返回按钮固定在垂直轴顶部（HIG），右侧操作紧随其下；
      // 窗口高度不足时上移整组控件，避免压住底部入口组。
      if showsRailActions {
        let controlsBottomLimit = safe.maxY - backSize - configuration.railActionTopSpacing - actionsHeight
        backTop = min(backTop, max(contentTop, controlsBottomLimit))
      }
      let actionsTop = showsBack ? backTop + backSize + configuration.railActionTopSpacing : backTop
      // 返回与右侧动作统一使用 rail 中轴，保证圆形控件横向对齐。
      let backAxisX = railX + configuration.railWidth / 2
      let backX: CGFloat = legacy ? safe.minX : backAxisX - backSize / 2
      backButton.frame = CGRect(x: backX, y: backTop, width: backSize, height: backSize)
      // 旧版回退仍由页面自己的导航栏负责返回，外壳不再套用侧栏圆形外观。
      backButton.backgroundColor = legacy ? .clear : configuration.railControlBackgroundColor
      backButton.layer.borderWidth = legacy ? 0 : configuration.railControlBorderWidth
      backButton.layer.cornerRadius = legacy ? 0 : backSize / 2
      railActionStack.frame = CGRect(x: railX + (configuration.railWidth - actionSize) / 2,
                                     y: actionsTop, width: actionSize, height: actionsHeight)
      // 分区入口组固定在侧栏底部（产品稿），窗口不足时在剩余区域内滚动。
      let railTop = legacy ? safe.minY : view.bounds.minY
      let controlsBottom = showsRailActions
        ? actionsTop + actionsHeight
        : (showsBack ? backTop + backSize : railTop)
      let tabsTop = max(railTop, controlsBottom + 8)
      let tabsBottom = max(tabsTop, safe.maxY - configuration.railItemsBottomInset)
      railScroll.frame = CGRect(x: railX, y: tabsTop, width: configuration.railWidth,
                                height: max(0, tabsBottom - tabsTop))
      railScroll.contentSize = CGSize(width: configuration.railWidth, height: max(railHeight, railScroll.bounds.height))
      rail.frame = CGRect(x: 0, y: max(0, railScroll.bounds.height - railHeight),
                          width: configuration.railWidth, height: railHeight)
      // 侧栏始终显示（呈现页改为让出侧栏宽度，不再隐藏侧栏）。
      // 选中的分区宿主必须位于最上层：多个宿主同 frame 叠放，
      // 若被未选中的空宿主盖住，就会表现为"整页空白"。
      if sectionHosts.indices.contains(selectedSectionIndex) {
        view.bringSubviewToFront(sectionHosts[selectedSectionIndex].view)
        if selectedSectionIndex == 0 { view.bringSubviewToFront(detailHost.view) }
        // 侧栏与返回/右侧按钮必须始终位于内容之上，否则点击会被内容层吞掉。
        view.bringSubviewToFront(railBackground)
        view.bringSubviewToFront(railScroll)
        view.bringSubviewToFront(rail)
        view.bringSubviewToFront(backButton)
        view.bringSubviewToFront(railActionStack)
      }
      if decision.mode == .compact, sectionHosts.indices.contains(selectedSectionIndex) {
        let host = sectionHosts[selectedSectionIndex]
        if let top = host.content.topViewController {
          top.view.setNeedsLayout()
          top.view.layoutIfNeeded()
          if lastLaidOutMode != .compact {
            // 折叠瞬间：行高依赖宽度重算，重新加载一次并用有效内容高度校正偏移。
            reloadTablesAndResetOffset(in: top.view)
            // 折叠后偶发"层级与数据都正常但不绘制"：做一次可见性抖动并强制提交一帧。
            host.view.isHidden = true
            host.view.isHidden = false
            top.view.setNeedsDisplay()
            top.view.layer.setNeedsDisplay()
            CATransaction.flush()
          }
          fixOverflowingScrollOffsets(in: top.view)
        }
      }
      lastLaidOutMode = decision.mode
      let hasFullScreenPresentation = false
      backButton.isHidden = !showsBack || hasFullScreenPresentation
      rail.isHidden = !showsRailItems || presentedViewController != nil || adaptiveOverlayPresented
      railScroll.isHidden = !showsRailItems || presentedViewController != nil || adaptiveOverlayPresented
      railActionStack.isHidden = !showsRailActions || presentedViewController != nil || adaptiveOverlayPresented
      view.bringSubviewToFront(backButton)
      view.bringSubviewToFront(railActionStack)
      // 官方要求：部分折叠时按折叠区（division reserved region）调整分栏边界，
      // 而不是沿用固定的栏宽常量。没有折叠区时保持原有栏宽。
      let masterWidth = railMetrics.divisionMinX.map { min(max(0, $0), contentHost.bounds.width) } ?? decision.masterWidth
      sectionHosts[0].view.frame = CGRect(x: 0, y: 0, width: masterWidth, height: contentHost.bounds.height)
      detailHost.view.frame = CGRect(x: masterWidth + configuration.dividerWidth, y: 0,
                                     width: max(0, contentHost.bounds.width - masterWidth - configuration.dividerWidth),
                                     height: contentHost.bounds.height)
      dividerView.backgroundColor = configuration.dividerColor
      dividerView.frame = CGRect(x: masterWidth, y: 0,
                                 width: configuration.dividerWidth, height: contentHost.bounds.height)
      dividerView.isHidden = selectedSectionIndex != 0 || legacy
        || (decision.mode != .medium && decision.mode != .expanded) || configuration.dividerWidth <= 0
      for host in sectionHosts.dropFirst() {
        host.view.frame = contentHost.bounds
        // All sections choose their columns from the initial window profile.
        // Opening or returning from a child never changes a wide window's columns.
        // 统一模型：右列统一由共享 detailHost 承载，分区不再各自分栏。
        let shouldSplitSection = false
        // 与会话列表保持一致：半折叠时按折叠区划分线定位分栏边界，
        // 没有折叠区时才退回固定栏宽。
        let sectionMasterWidth = railMetrics.divisionMinX
          .map { min(max(0, $0), contentHost.bounds.width) } ?? decision.masterWidth
        host.configureSplit(masterWidth: shouldSplitSection ? sectionMasterWidth : nil,
                            dividerWidth: configuration.dividerWidth, dividerColor: configuration.dividerColor)
      }
      if decision.mode == .compact || legacy {
        // 折叠时展示"右列当前页面"；右列是空占位时才回到左列。
        // 会话分区（section 0）的右列是 conversationCoordinator，不是 sectionHosts[0]。
        // 右列栈顶变化（打开/切换会话）时清除"返回列表"标记，
        // 否则折叠后会把已经打开的聊天误判成"用户要求看列表"。
        let detailTop = conversationCoordinator.navigationController.topViewController
        if detailTop !== lastDetailTopController {
          lastDetailTopController = detailTop
          prefersConversationList = false
        }
        compactShowsDetail = selectedSectionIndex == 0
          ? (prefersConversationList ? false : !conversationCoordinator.isShowingPlaceholder)
          : !sectionHosts[selectedSectionIndex].isShowingDetailPlaceholder
        if compactShowsDetail {
          sectionHosts[0].view.isHidden = true
          detailHost.view.isHidden = false
          detailHost.view.frame = contentHost.bounds
        } else {
          sectionHosts[0].view.isHidden = false
          sectionHosts[0].view.frame = contentHost.bounds
          detailHost.view.isHidden = true
        }
      } else {
        // 展开态统一：左列=选中分区根列表，右列=共享 detail。
        sectionHosts[0].view.isHidden = selectedSectionIndex != 0
        sectionHosts[0].view.frame = CGRect(x: 0, y: 0, width: masterWidth, height: contentHost.bounds.height)
        for (index, host) in sectionHosts.enumerated().dropFirst() {
          let isSelected = index == selectedSectionIndex
          host.view.isHidden = !isSelected
          if isSelected {
            host.view.frame = CGRect(x: 0, y: 0, width: masterWidth, height: contentHost.bounds.height)
          }
        }
        detailHost.view.isHidden = false
        detailHost.view.frame = CGRect(x: masterWidth + configuration.dividerWidth, y: 0,
                                       width: max(0, contentHost.bounds.width - masterWidth - configuration.dividerWidth),
                                       height: contentHost.bounds.height)
      }
      // 右列是否有内容，每次布局幂等同步给宿主：宿主据此点亮/取消左列选中高亮。
      // 统一共享右列模型下，通讯录/我的 的子页面同样放在共享 detail 栈里，
      // 因此只有仍使用分区自有分栏时才看 sectionHost，否则一律看共享栈。
      let paired = decision.mode == .expanded || decision.mode == .medium
      let placeholder: Bool
      if !paired {
        // 折叠或降级为单栏：没有并排左列，不存在需要保留的选中高亮。
        placeholder = true
      } else if selectedSectionIndex == 0 {
        placeholder = conversationCoordinator.isShowingPlaceholder
      } else if sectionHosts.indices.contains(selectedSectionIndex),
                sectionHosts[selectedSectionIndex].splitDetail != nil {
        placeholder = sectionHosts[selectedSectionIndex].isShowingDetailPlaceholder
      } else {
        placeholder = conversationCoordinator.isShowingPlaceholder
      }
      onDetailPlaceholderChanged?(placeholder)
      // Every layout entry must preserve the selected section, including delayed navigation callbacks.
      updateVisibility()
      // Resolve the background after visibility has been applied. On the first
      // Duo layout the detail placeholder is mounted only in this pass; reading
      // the color before updateVisibility would briefly use the master list's
      // background and expose a mismatched top strip until a child is opened.
      applyContentBackground()
      // Finish the host and its child backgrounds before publishing the gap.
      // This keeps the fixed design inset visible without a transient white
      // frame while a root/detail navigation stack is being installed.
      view.layoutIfNeeded()
      contentTopMasterGap.isHidden = legacy
      contentTopDetailGap.isHidden = legacy
      if let root = conversationCoordinator.navigationController.viewControllers.first {
        onCompactChatVisibilityChanged?(root, (decision.mode == .compact || legacy) && compactShowsDetail)
      }
      // 列宽已经避让 rail，尾部安全区不应再由页面继承；否则 UIKit 会把左滑
      // 操作按钮按该安全区继续内缩，最后一颗按钮右侧出现留白。
      if legacy {
        restoreHostedTrailingSafeArea()
      } else {
        suppressHostedTrailingSafeArea()
      }
      // Reapply page-owned scroll geometry after the shell has assigned the
      // final child frames. UIKit derives safe-area/indicator values from
      // those frames and can overwrite the earlier first-pass values.
      onContentLayout?(sections + [conversationCoordinator.navigationController] + sectionHosts.compactMap(\.splitDetail))
      onGeometryChanged?(["windowWidth": view.window?.bounds.width ?? view.bounds.width,
                          "windowHeight": view.window?.bounds.height ?? view.bounds.height, "contentWidth": contentHost.bounds.width,
                          "masterWidth": decision.masterWidth, "detailWidth": detailHost.view.bounds.width,
                          "railWidth": legacy ? 0 : railWidth,
                          "mode": legacy ? "legacy" : String(describing: decision.mode!)] as NSDictionary)
      NotificationCenter.default.post(name: Notification.Name("NEAdaptiveGeometryDidChange"), object: self)
      if enteringFallback {
        legacyFallbackPending = conversationCoordinator.activeIntent != nil
        if !legacyFallbackPending { onLegacyFallback?() }
      } else if legacyFallbackPending, conversationCoordinator.activeIntent == nil {
        legacyFallbackPending = false
        onLegacyFallback?()
      }
    }

    /// Window scene updates can briefly retain the old window bounds while the
    /// shell root has already been resized to the folded screen. Resolve the
    /// mode from the same view bounds used below for frames so a stale paired
    /// decision cannot leave an empty detail column beside a compact list.
    @discardableResult
    private func syncDecisionToCurrentViewBounds() -> Bool {
      guard view.bounds.width > 0, view.bounds.height > 0 else { return false }
      let safe = view.safeAreaInsets
      let current = NEAdaptiveLayoutPolicy.resolve(
        window: .init(width: view.bounds.width, height: view.bounds.height,
                      top: safe.top, left: safe.left, bottom: safe.bottom, right: safe.right),
        configuration: configuration.policy
      )
      guard current != decision else { return false }
      let old = decision
      let wasSinglePage = old?.mode == .compact || isUsingLegacyLayout
      let enteringFallback = current.mode == nil && !isUsingLegacyLayout
      decision = current
      isUsingLegacyLayout = current.mode == nil
      if !wasSinglePage, current.mode == .compact || isUsingLegacyLayout {
        compactShowsDetail = conversationCoordinator.activeIntent != nil
      }
      return enteringFallback
    }

    /// Keep first-level chat pages in the same column as the current window
    /// mode. A compact push can occur before Duo expands; migrate that page
    /// before the paired layout is published, and restore it on folding back.
    /// 统一迁移：展开态把左列子页面移入共享右列；折叠态把右列一级页面移回
    /// 左列。唯一的例外是会话语义页面（聊天详情）：它始终留在右列，由外壳
    /// 在侧栏绘制系统返回入口（D-C），不能迁回页面导航栈。
    private func syncDetailStackAcrossPosture(paired: Bool) {
      guard !isTransferringConversationSectionChild, sections.indices.contains(selectedSectionIndex) else { return }
      let master = sections[selectedSectionIndex]
      let detail = conversationCoordinator.navigationController
      guard let masterRoot = master.viewControllers.first else { return }
      // 折叠态下正在展示的聊天必须留在右列（D-C）：返回入口由外壳绘制在侧栏，
      // 与系统 Wi-Fi 图标同轴。如果把聊天迁回左列导航栈，页面会退回自己的
      // 导航栏返回按钮，侧栏返回按钮也会被隐藏，与设计稿和交互稿不符。
      if !paired, selectedSectionIndex == 0, conversationCoordinator.activeIntent != nil {
        return
      }
      let masters = Array(master.viewControllers.dropFirst())
      let detailPages = detail.viewControllers.filter { $0 !== conversationCoordinator.currentPlaceholder }
      isTransferringConversationSectionChild = true
      UIView.performWithoutAnimation {
        if paired {
          if !masters.isEmpty {
            master.setViewControllers([masterRoot], animated: false)
            // 迁移到右列时保留占位根，否则搜索/设置等一级子页会成为栈底，
            // rail 返回没有可 pop 的目标。
            var pages = masters
            if let placeholder = conversationCoordinator.currentPlaceholder,
               !pages.contains(where: { $0 === placeholder }) {
              pages.insert(placeholder, at: 0)
            }
            detail.setViewControllers(pages, animated: false)
          }
        } else if !detailPages.isEmpty {
          detail.setViewControllers([conversationCoordinator.currentPlaceholder ?? UIViewController()], animated: false)
          master.setViewControllers([masterRoot] + detailPages, animated: false)
        }
      }
      isTransferringConversationSectionChild = false
    }

    private func syncConversationSectionChildStack(for paired: Bool) {
      guard !isTransferringConversationSectionChild,
            sections.indices.contains(0) else { return }
      // 右列页面上有 present 页面时不能迁移：迁移会 setViewControllers 重新挂载该页面，
      // UIKit 会顺带把它的弹窗关闭（表现为"折叠后新建分组自动消失"）。
      if !paired {
        let target = conversationCoordinator.navigationController
        if target.presentedViewController != nil
            || target.visibleViewController?.presentedViewController != nil {
          return
        }
      }
      let source = sections[0]
      let target = conversationCoordinator.navigationController
      // 右列当前以某个页面作根（新模型：第一个页面即导航根）：折叠时保持它可见，
      // 不做"把右列页面迁回左列"的搬运，否则会把正在展示的页面搬走。
      if !paired, !conversationCoordinator.isShowingPlaceholder, target.viewControllers.count == 1 {
        return
      }
      guard let sourceRoot = source.viewControllers.first else { return }
      let sourceChildren = Array(source.viewControllers.dropFirst())
      if paired, !sourceChildren.isEmpty, conversationCoordinator.activeIntent != nil {
        conversationCoordinator.reset()
      }
      guard let targetPlaceholder = target.viewControllers.first else { return }
      let targetChildren = Array(target.viewControllers.dropFirst())
      if paired, !sourceChildren.isEmpty {
        // A first-level page opened from the message list is the current
        // section selection. Replace any stale detail page (including a
        // retained chat intent) before moving it to the right column.
        isTransferringConversationSectionChild = true
        UIView.performWithoutAnimation {
          if !targetChildren.isEmpty {
            target.setViewControllers([targetPlaceholder], animated: false)
          }
          source.setViewControllers([sourceRoot], animated: false)
          target.setViewControllers([targetPlaceholder] + sourceChildren, animated: false)
        }
        isTransferringConversationSectionChild = false
      } else if !paired, conversationCoordinator.activeIntent == nil,
                sourceChildren.isEmpty, !targetChildren.isEmpty {
        isTransferringConversationSectionChild = true
        UIView.performWithoutAnimation {
          target.setViewControllers([targetPlaceholder], animated: false)
          source.setViewControllers([sourceRoot] + targetChildren, animated: false)
        }
        isTransferringConversationSectionChild = false
      }
    }

    private func applyContentBackground() {
      let fallback = contentBackgroundColorProvider?() ?? configuration.contentBackgroundColor
      var colors = contentBackgroundColorsProvider?() ?? (master: fallback, detail: fallback)
      // Contacts and Mine roots occupy the complete content host until a
      // child is opened. Their split detail navigation is only an empty
      // placeholder in that state, so the right side of the top breathing
      // room must use the root color as well. Otherwise the placeholder's
      // default white background flashes in the first layout pass and leaves
      // a mismatched strip beside the root page.
      if selectedSectionIndex > 0 {
        let hasSectionChild = sectionHosts.indices.contains(selectedSectionIndex)
          && (sectionHosts[selectedSectionIndex].splitDetail?.viewControllers.count ?? 1) > 1
        if !hasSectionChild { colors.detail = colors.master }
      }
      contentTopMasterGap.backgroundColor = colors.master
      contentTopDetailGap.backgroundColor = colors.detail
      view.backgroundColor = fallback
      contentHost.backgroundColor = fallback
    }

    /// Every navigation stack the shell keeps resident, including paired columns.
  private var hostedNavigations: [UINavigationController] {
    sections + [conversationCoordinator.navigationController] + sectionHosts.compactMap(\.splitDetail)
  }

  /// 切换右栏内容前，先关闭该栏上仍处于模态的页面。
  ///
  /// 文本消息详情等页面是以 `.overCurrentContext` present 在右栏导航上的，
  /// 只替换导航栈不会移除它：用户点选另一个会话时，新会话会被上一个会话
  /// 打开的详情页整栏盖住。切换会话、切换一级页面、切换分区前统一回收。
  /// 上一次布局是否处于折叠（单栏）状态，用于识别"展开 → 折叠"这一刻。
  private var lastLaidOutMode: NEAdaptiveLayoutMode?
  /// 用户主动点击"返回会话列表"后置位：布局时不再被"右列有页面"重新覆盖。
  private var prefersConversationList = false
  /// 上一次布局时右列栈顶页面；一旦变化说明有新页面被打开，需清除上面的标记。
  private weak var lastDetailTopController: UIViewController?

  /// 折叠后页面宽度变化会让行高/内容高度重算，但表格可能保留展开态的超大偏移，
  /// 可视区就落到空白处（表现为"折叠后整屏空白"）。这里做一次布局并修正越界偏移。
  private func reloadTablesAndResetOffset(in root: UIView) {
    if let table = root as? UITableView {
      table.reloadData()
      table.layoutIfNeeded()
      table.setContentOffset(.zero, animated: false)
    } else {
      for child in root.subviews { reloadTablesAndResetOffset(in: child) }
    }
  }

  private func fixOverflowingScrollOffsets(in root: UIView) {
    if let table = root as? UITableView {
      table.layoutIfNeeded()
      let maxY = max(0, table.contentSize.height - table.bounds.height + table.contentInset.bottom)
      if table.contentOffset.y > maxY + 1 {
        table.setContentOffset(CGPoint(x: table.contentOffset.x, y: maxY), animated: false)
      }
    } else if let scroll = root as? UIScrollView {
      let maxY = max(0, scroll.contentSize.height - scroll.bounds.height)
      if scroll.contentOffset.y > maxY + 1 {
        scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: maxY), animated: false)
      }
    }
    for child in root.subviews { fixOverflowingScrollOffsets(in: child) }
  }

  private func dismissColumnPresentations() {
    for navigation in hostedNavigations {
      dismissColumnPresentation(navigation.presentedViewController)
      dismissColumnPresentation(navigation.visibleViewController?.presentedViewController)
    }
  }

  /// 列内的临时呈现（搜索浮层、选择器等）随栏位变化收起；
  /// 但系统弹窗（UIAlertController）是窗口级呈现，且常由页面在出现时主动弹出
  /// （例如"群已解散"），不能在栏位重排时被顺带关闭。
  private func dismissColumnPresentation(_ presented: UIViewController?) {
    guard let presented, !presented.isBeingDismissed, !presented.isBeingPresented else { return }
    if presented is UIAlertController { return }
    presented.dismiss(animated: false)
  }

  /// 读取 Duo 的系统占位区域（折叠区/摄像头遮挡），用于替代固定的设计常量。
  ///
  /// 官方指引：custom views 需要检查 `reservedRegions` 的 frame 并据此调整布局，
  /// 而不是写死侧栏与内容的偏移。
  struct NEReservedRegionMetrics {
    /// 尾部垂直条内被系统占位区域遮挡到的最大 y，nil 表示当前没有激活的占位区。
    let railOcclusionBottom: CGFloat?
    /// 尾部占位区（状态区：时钟 / Wi-Fi）的水平中心，用于让返回按钮与其对齐。
    let railOcclusionCenterX: CGFloat?
    /// 折叠区划分出的最大 x，nil 表示未处于部分折叠状态。
    let divisionMaxX: CGFloat?
    /// 折叠区划分出的最小 x：部分折叠时用它对齐主从分栏边界。
    let divisionMinX: CGFloat?
  }

  private func reservedRegionMetrics(railMinX: CGFloat) -> NEReservedRegionMetrics {
    guard #available(iOS 27.1, *) else {
      return NEReservedRegionMetrics(railOcclusionBottom: nil, railOcclusionCenterX: nil,
                                     divisionMaxX: nil, divisionMinX: nil)
    }
    let active = view.reservedRegions(kind: .occlusion).filter(\.isActive)
    let railHits = active.filter { $0.frame.maxX > railMinX && $0.frame.minX < view.bounds.maxX }
    let divisions = view.reservedRegions(kind: .division).filter(\.isActive)
    let occlusionFrame = railHits.map(\.frame).reduce(nil as CGRect?) { partial, frame in
      partial.map { $0.union(frame) } ?? frame
    }
    return NEReservedRegionMetrics(railOcclusionBottom: railHits.map(\.frame.maxY).max(),
                                   railOcclusionCenterX: occlusionFrame.map { $0.midX },
                                   divisionMaxX: divisions.map(\.frame.maxX).max(),
                                   divisionMinX: divisions.map(\.frame.minX).min())
  }

  private func updateVisibility() {
      let messages = selectedSectionIndex == 0
      if !messages {
        // 共享右列服务所有分区，不随分区切换隐藏；只隐藏消息分区的左列宿主。
        sectionHosts[0].view.isHidden = true
      }
      let paired = decision?.mode == .medium || decision?.mode == .expanded
      sectionHosts[0].setVisible(shellVisible && messages && (paired || !compactShowsDetail))
      // 共享右列由三个分区共用：展开态通讯录/我的 的一级页面同样发布进 detailHost，
      // 因此它的 appearance 只能按"这段内容是否真的在屏幕上"转发，不能再绑定消息分区。
      // 否则这些页面收不到 viewWillAppear（页面靠它隐藏系统导航栏、配置返回与首屏数据），
      // 表现成"右列导航栏仍是系统样式"：标题左对齐、比页面自带导航栏更高且被其盖住；
      // 只有切回消息分区（例如打开会话）后右列重新收到 appearance 回调才恢复。
      // 折叠态仍由 compactShowsDetail 决定。
      detailHost.setContentVisible(shellVisible && (paired || compactShowsDetail))
      for (index, host) in sectionHosts.enumerated().dropFirst() {
        host.view.isHidden = selectedSectionIndex != index
        host.setVisible(shellVisible && selectedSectionIndex == index)
      }
    }
  }

  /// Keeps repeated triggers of the same entry on the stack only once.
  ///
  /// A page opts in by carrying a stable `restorationIdentifier`. Repeated taps
  /// then reuse the existing instance — popping back to it when it is buried —
  /// instead of pushing another copy. Pages without an identifier (user
  /// profiles, chats, ...) keep their original multi-instance behavior.
  enum NEAdaptivePageStack {
    static func reuseExistingPage(for controller: UIViewController,
                                  in navigation: UINavigationController) -> Bool {
      // 页面在 viewDidLoad 中登记自身标识，而入栈判断发生在 push 之前，
      // 因此新实例必须先加载视图，否则标识恒为 nil、去重永远不会生效。
      if controller.restorationIdentifier == nil {
        controller.loadViewIfNeeded()
      }
      guard let identity = controller.restorationIdentifier, !identity.isEmpty else { return false }
      guard let existing = navigation.viewControllers.first(where: { $0.restorationIdentifier == identity }),
            existing !== controller else { return false }
      if navigation.topViewController === existing {
        return true
      }
      navigation.popToViewController(existing, animated: true)
      return true
    }
  }
#endif
