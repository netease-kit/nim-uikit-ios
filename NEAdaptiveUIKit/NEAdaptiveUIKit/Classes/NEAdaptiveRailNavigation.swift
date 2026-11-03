#if canImport(UIKit)
  import ObjectiveC
  import UIKit

  /// 侧栏右侧操作按钮的中立描述。
  ///
  /// 外壳只读取页面导航栏当前的文本、图片、计数和启用态，点击仍转发给页面自己的
  /// 按钮，因此数量、权限、禁用态和业务回调始终只有页面一个权威来源。
  @objcMembers public final class NEAdaptiveRailAction: NSObject {
    /// 按钮文本；有文本时优先展示文本（产品稿要求右侧按钮保留原文案）。
    public var title: String?
    /// 文本尾部计数拆出的角标（如「确定(10)」中的 10）。
    public var badge: String?
    public var image: UIImage?
    /// 供侧栏按钮读取的无障碍文案（NSObject 已占用 `accessibilityLabel`）。
    public var accessibilityText: String?
    public var isEnabled: Bool = true
    public var identifier: String?
    /// Objective-C 接入方的转发目标；Swift 接入方可直接设置 `handler`。
    public weak var target: AnyObject?
    public var selector: Selector?
    public var handler: (() -> Void)?

    public init(title: String? = nil, badge: String? = nil, image: UIImage? = nil,
                accessibilityText: String? = nil, isEnabled: Bool = true,
                identifier: String? = nil, handler: (() -> Void)? = nil) {
      self.title = title
      self.badge = badge
      self.image = image
      self.accessibilityText = accessibilityText
      self.isEnabled = isEnabled
      self.identifier = identifier
      self.handler = handler
      super.init()
    }

    /// 与页面原按钮完全一致的点击语义。
    public func perform() {
      if let handler {
        handler()
        return
      }
      guard let selector else { return }
      NEAdaptiveActionInvocation.invoke(selector, on: target, sender: nil)
    }
  }

  /// 直接调用页面按钮原本的 selector 目标。
  ///
  /// 侧栏按钮不是页面原按钮，不能依赖 `UIControl.sendActions` 的命中态判断；
  /// 这里按 `allTargets` 解析页面登记的回调，保证隐藏原入口后点击语义不变。
  enum NEAdaptiveActionInvocation {
    static func invoke(_ selector: Selector, on target: AnyObject?, sender: AnyObject?) {
      guard let object = target as? NSObject,
            let cls = object_getClass(object) else { return }
      guard let method = class_getInstanceMethod(cls, selector) else {
        _ = object.perform(selector, with: sender)
        return
      }
      // 参数个数包含 self 与 _cmd；带 sender 的回调需要额外一个参数。
      if method_getNumberOfArguments(method) >= 3 {
        _ = object.perform(selector, with: sender)
      } else {
        _ = object.perform(selector)
      }
    }

    /// 把控件当前的 touchUpInside 目标逐个转发一次。
    static func forward(_ control: UIControl) {
      var invoked = false
      for target in control.allTargets {
        let object = target.base
        let selectors = control.actions(forTarget: object, forControlEvent: .touchUpInside) ?? []
        for name in selectors {
          invoke(NSSelectorFromString(name), on: object as AnyObject, sender: control)
          invoked = true
        }
      }
      // UIAction 风格的按钮没有 selector 目标，退回控件自身派发。
      if !invoked { control.sendActions(for: .touchUpInside) }
    }
  }

  /// 页面按钮文案的计数拆分。
  ///
  /// IMUIKit 的数量型操作按钮沿用「确定(10)」这类文案；侧栏把计数拆到角标，
  /// 文本只保留操作名，既保留原文案也避免圆形按钮被数字撑开。
  enum NEAdaptiveRailTitle {
    private static let countPattern = try? NSRegularExpression(
      pattern: "^(.+?)\\s*[（(]\\s*(\\d+)\\s*[)）]\\s*$")

    static func split(_ title: String?) -> (text: String?, badge: String?) {
      guard let title, !title.isEmpty else { return (nil, nil) }
      let range = NSRange(title.startIndex..., in: title)
      guard let match = countPattern?.firstMatch(in: title, range: range),
            match.numberOfRanges == 3,
            let textRange = Range(match.range(at: 1), in: title),
            let badgeRange = Range(match.range(at: 2), in: title) else {
        return (title, nil)
      }
      let text = String(title[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
      let badge = String(title[badgeRange])
      return (text.isEmpty ? nil : text, badge)
    }
  }

  /// 页面导航栏动作来源。
  ///
  /// 支持三类既有来源：
  /// - `NENavigationView` 及其子类（IMKit 标准自绘标题栏）；
  /// - 系统 `UINavigationItem`；
  /// - 页面自绘标题栏（使用 `NEUnifiedBackButton`，或 `id.arrowDown` 的收起入口）。
  /// 找到的控件只做透明转移（隐藏原入口、转发点击），不复制业务状态；外壳
  /// 不依赖具体业务模块。
  final class NEAdaptiveRailPageNavigation {
    private weak var page: UIViewController?
    /// 自绘标题栏；页面隐藏标题栏时不再向侧栏投影任何入口。
    private weak var customBar: UIView?
    /// 页面自绘头部（非 NENavigationView）：使用统一返回按钮或收起入口。
    private var usesCustomHeader = false
    private weak var customBackControl: UIButton?
    private var customTrailingControls: [UIButton] = []
    private var systemBackItem: UIBarButtonItem?
    private var systemTrailingItems: [UIBarButtonItem] = []
    private var systemHidesBackButtonBeforeSuppression: Bool?
    private var suppressesSystemNavigation = false
    private var suppressedSystemItems = false
    private var hiddenControls: [(control: UIButton, alpha: CGFloat)] = []
    private var observations: [NSKeyValueObservation] = []
    private var isSuppressed = false
    /// 页面导航栏自身状态变化（标题、启用态、显隐）时通知外壳刷新侧栏。
    var onChange: (() -> Void)?

    private init(page: UIViewController) {
      self.page = page
    }

    /// 解析页面当前的导航栏动作；页面没有可迁移入口时返回 nil。
    static func make(for page: UIViewController) -> NEAdaptiveRailPageNavigation? {
      // 只要求视图已加载：页面在布局中可能还没完成 window 挂载，
      // 但外壳已经把它作为当前承载页，入口归属是确定的。
      guard page.isViewLoaded else { return nil }
      let navigation = NEAdaptiveRailPageNavigation(page: page)
      if let bar = customNavigationBar(in: page) {
        navigation.customBar = bar
        navigation.customBackControl = firstControl(in: bar, identifiers: ["id.backArrow"])
        // 标准标题栏同时支持内置 moreButton（id.threePoint）与页面追加的
        // 自定义右侧按钮（如 Bot 子会话的 id.createTopic），按横坐标保持页面顺序。
        let trailing = controls(in: bar, identifiers: ["id.threePoint", "id.createTopic"])
        navigation.customTrailingControls = trailing.sorted {
          $0.convert($0.bounds, to: bar).minX < $1.convert($1.bounds, to: bar).minX
        }
        if navigation.customBackControl != nil || !navigation.customTrailingControls.isEmpty {
          return navigation
        }
      }
      if let custom = customHeaderSource(in: page) {
        navigation.usesCustomHeader = true
        navigation.customBackControl = custom.back
        navigation.customTrailingControls = custom.trailing
        return navigation
      }
      if let system = systemNavigationSource(for: page) {
        navigation.customBar = nil
        navigation.customBackControl = nil
        navigation.customTrailingControls = []
        navigation.systemBackItem = system.backItem
        navigation.systemTrailingItems = system.trailingItems
        navigation.suppressesSystemNavigation = true
        navigation.suppressedSystemItems = false
        return navigation
      }
      return nil
    }

    // MARK: - 来源解析

    private static func customNavigationBar(in page: UIViewController) -> UIView? {
      var match: UIView?
      func walk(_ view: UIView) {
        if match != nil { return }
        if isNavigationBarView(view), !view.isHidden, view.superview != nil {
          match = view
          return
        }
        for child in view.subviews {
          walk(child)
        }
      }
      walk(page.view)
      return match
    }

    /// `NENavigationView` 是 IMUIKit 各模块共用的自绘标题栏；聊天模块使用它的
    /// 子类 `ChatNavigationView`（收藏、Pin、设置等页面）。
    /// 这里沿继承链按类名识别，避免让公共组件反向依赖 UI 模块，也兼容后续子类。
    private static func isNavigationBarView(_ view: UIView) -> Bool {
      var cls: AnyClass? = type(of: view)
      while let current = cls {
        let name = NSStringFromClass(current)
        if name == "NENavigationView" || name.hasSuffix(".NENavigationView") {
          return true
        }
        cls = class_getSuperclass(current)
      }
      return false
    }

    /// 自绘标题栏的接入约定：
    /// - 返回入口使用 `NEBaseUIKit.NEUnifiedBackButton`（按类名识别）；
    /// - 兼容 @ 人员选择等面板的 `id.arrowDown` 收起入口；
    /// - 右侧操作使用 `id.sureButton` / `id.multiSelect` / `id.adaptiveAction`，
    ///   且必须与返回入口位于同一行头部区域，避免误识别内容区按钮。
    private static func customHeaderSource(in page: UIViewController)
      -> (back: UIButton?, trailing: [UIButton])? {
      guard page.isViewLoaded else { return nil }
      let back = unifiedBackButton(in: page.view)
        ?? controls(in: page.view, identifiers: ["id.arrowDown", "id.adaptiveBack"]).first
      let trailingIdentifiers = ["id.sureButton", "id.multiSelect", "id.adaptiveAction", "id.createTopic"]
      var trailing = controls(in: page.view, identifiers: trailingIdentifiers)
      if let back {
        // 页面在 viewWillAppear 阶段可能还没完成 Auto Layout；此时不做行过滤，
        // 避免把尚未定位的右侧按钮误判为内容区按钮。
        if back.bounds.width > 0, back.bounds.height > 0 {
          let backFrame = back.convert(back.bounds, to: page.view)
          trailing = trailing.filter {
            abs($0.convert($0.bounds, to: page.view).midY - backFrame.midY) <= 40
          }
        }
      } else {
        trailing = trailing.filter {
          $0.convert($0.bounds, to: page.view).minY < 160
        }
      }
      guard back != nil || !trailing.isEmpty else { return nil }
      return (back, trailing)
    }

    private static func unifiedBackButton(in root: UIView) -> UIButton? {
      var found: UIButton?
      func walk(_ view: UIView) {
        if found != nil { return }
        if let button = view as? UIButton,
           isUnifiedBackButton(button),
           button.superview != nil {
          found = button
          return
        }
        for child in view.subviews {
          walk(child)
        }
      }
      walk(root)
      return found
    }

    private static func isUnifiedBackButton(_ view: UIView) -> Bool {
      guard view is UIButton else { return false }
      var cls: AnyClass? = type(of: view)
      while let current = cls {
        let name = NSStringFromClass(current)
        if name == "NEUnifiedBackButton" || name.hasSuffix(".NEUnifiedBackButton") {
          return true
        }
        cls = class_getSuperclass(current)
      }
      return false
    }

    private static func firstControl(in root: UIView, identifiers: [String]) -> UIButton? {
      controls(in: root, identifiers: identifiers).first
    }

    /// 按标识收集按钮；不要求当前可见，页面后续展示由绑定观察并实时过滤。
    private static func controls(in root: UIView, identifiers: [String]) -> [UIButton] {
      var found: [UIButton] = []
      func walk(_ view: UIView) {
        if let button = view as? UIButton,
           let identifier = button.accessibilityIdentifier,
           identifiers.contains(identifier),
           button.superview != nil {
          found.append(button)
        }
        for child in view.subviews {
          walk(child)
        }
      }
      walk(root)
      return found
    }

    private static func systemNavigationSource(for page: UIViewController)
      -> (backItem: UIBarButtonItem?, trailingItems: [UIBarButtonItem])? {
      guard let navigation = page.navigationController, !navigation.isNavigationBarHidden else { return nil }
      let backItem = page.navigationItem.leftBarButtonItem
      let trailingItems = page.navigationItem.rightBarButtonItems ?? []
      guard backItem != nil || !trailingItems.isEmpty else { return nil }
      return (backItem, trailingItems)
    }

    /// 页面当前是否展示自己的标题栏。
    ///
    /// 自绘整窗页头且没有统一返回入口的页面由页面自己承担返回，外壳不再补一个
    /// 侧栏返回，避免同一屏出现两个返回。
    static func hasVisibleTitleBar(in page: UIViewController) -> Bool {
      guard page.isViewLoaded else { return false }
      if customNavigationBar(in: page) != nil { return true }
      if unifiedBackButton(in: page.view) != nil { return true }
      if !controls(in: page.view, identifiers: ["id.arrowDown", "id.adaptiveBack"]).isEmpty { return true }
      if let navigation = page.navigationController, !navigation.isNavigationBarHidden { return true }
      return false
    }

    // MARK: - 动作描述

    /// 返回动作：页面自己配置了返回入口时原样转发，保证“取消”“返回”等
    /// 页面自定义返回语义（清理未读、二次确认等）不被外壳替换。
    func backAction() -> NEAdaptiveRailAction? {
      if let control = customBackControl, isCustomBarVisible, !control.isHidden {
        return Self.action(for: control)
      }
      if let item = systemBackItem, isSystemBarAvailable {
        return Self.action(for: item)
      }
      return nil
    }

    /// 页面当前可见的全部右侧操作。
    func trailingActions() -> [NEAdaptiveRailAction] {
      var actions: [NEAdaptiveRailAction] = []
      // 原入口由外壳按透明度隐藏，这里只认页面自己的显隐与可交互状态。
      if isCustomBarVisible {
        let visible = customTrailingControls.filter { !$0.isHidden && $0.isUserInteractionEnabled }
        // 侧栏从上到下对应页面从左到右：优先按页面横坐标，未完成布局时按已知入口语义排序。
        let ordered = visible.sorted { lhs, rhs in
          let host = page?.view ?? lhs
          let left = lhs.convert(lhs.bounds, to: host).minX
          let right = rhs.convert(rhs.bounds, to: host).minX
          if abs(left - right) > 0.5 { return left < right }
          return Self.trailingOrder(lhs) < Self.trailingOrder(rhs)
        }
        for control in ordered {
          actions.append(Self.action(for: control))
        }
      }
      if isSystemBarAvailable {
        // rightBarButtonItems 的第一个是最右侧，倒序后才是页面从左到右。
        for item in systemTrailingItems.reversed() {
          actions.append(Self.action(for: item))
        }
      }
      return actions.filter {
        ($0.title?.isEmpty == false) || $0.image != nil || ($0.badge?.isEmpty == false)
      }
    }

    private var isCustomBarVisible: Bool {
      if usesCustomHeader {
        let controls = ([customBackControl] + customTrailingControls).compactMap { $0 }
        return controls.contains { $0.superview != nil && !$0.isHidden }
      }
      guard let customBar else { return false }
      return !customBar.isHidden && customBar.superview != nil
    }

    private var isSystemBarAvailable: Bool {
      guard let navigation = page?.navigationController else { return false }
      return !navigation.isNavigationBarHidden
    }

    private static func trailingOrder(_ button: UIButton) -> Int {
      switch button.accessibilityIdentifier {
      case "id.createTopic": return 0
      case "id.threePoint": return 1
      case "id.sureButton", "id.multiSelect": return 2
      case "id.adaptiveAction": return 3
      default: return 4
      }
    }

    private static func action(for button: UIButton) -> NEAdaptiveRailAction {
      let rawTitle = button.title(for: .normal) ?? button.currentTitle
      let split = NEAdaptiveRailTitle.split(rawTitle)
      let image = split.text == nil ? button.image(for: .normal) : nil
      let action = NEAdaptiveRailAction(
        title: split.text,
        badge: split.badge,
        image: image,
        accessibilityText: rawTitle ?? button.accessibilityLabel ?? split.text,
        isEnabled: button.isEnabled,
        identifier: button.accessibilityIdentifier
      )
      action.handler = { [weak button] in
        guard let button else { return }
        NEAdaptiveActionInvocation.forward(button)
      }
      return action
    }

    private static func action(for item: UIBarButtonItem) -> NEAdaptiveRailAction {
      if let button = item.customView as? UIButton {
        return action(for: button)
      }
      let split = NEAdaptiveRailTitle.split(item.title)
      let image = split.text == nil ? item.image : nil
      let action = NEAdaptiveRailAction(
        title: split.text,
        badge: split.badge,
        image: image,
        accessibilityText: item.title ?? item.accessibilityLabel ?? split.text,
        isEnabled: item.isEnabled,
        identifier: item.accessibilityIdentifier
      )
      action.target = item.target
      action.selector = item.action
      if let control = item.customView as? UIControl, !(control is UIButton) {
        action.handler = { [weak control] in
          guard let control else { return }
          NEAdaptiveActionInvocation.forward(control)
        }
      }
      return action
    }

    /// 绑定是否仍是页面当前的导航入口来源。
    ///
    /// 页面在首次出现时可能在自绘标题栏与系统导航之间切换（例如系统导航开关），
    /// 此前的绑定必须失效并重新解析，否则旧入口会留在页面上。
    func isValid(for page: UIViewController) -> Bool {
      guard self.page === page else { return false }
      if usesCustomHeader {
        let controls = ([customBackControl] + customTrailingControls).compactMap { $0 }
        return controls.contains { $0.superview != nil }
      }
      if customBackControl != nil || !customTrailingControls.isEmpty {
        return isCustomBarVisible
      }
      return isSystemBarAvailable
    }

    // MARK: - 原入口的隐藏与恢复

    /// 把页面导航栏上的入口转移给侧栏：自定义标题栏按透明度隐藏（保留布局，
    /// 页面自身的 hidden 仍是唯一语义来源）；系统导航项取出并清空，退出时归还。
    func suppress() {
      guard !isSuppressed else { return }
      isSuppressed = true
      for control in ([customBackControl] + customTrailingControls).compactMap({ $0 }) {
        hiddenControls.append((control, control.alpha))
        control.alpha = 0
      }
      if suppressesSystemNavigation, let page {
        let item = page.navigationItem
        let needsSystemSuppression = systemBackItem != nil || !systemTrailingItems.isEmpty
          || (page.navigationController?.viewControllers.count ?? 0) > 1
        if needsSystemSuppression {
          systemHidesBackButtonBeforeSuppression = item.hidesBackButton
          item.leftBarButtonItem = nil
          item.rightBarButtonItems = []
          item.hidesBackButton = true
          suppressedSystemItems = true
        }
      }
      observeChanges()
    }

    /// 系统导航项可能在页面重新出现时被页面再次写入。页面配置仍是权威来源：
    /// 把新写入的项纳入缓存后立即再次移交给侧栏，避免导航栏与侧栏重复露出。
    func refreshSuppressedSystemItems() {
      guard isSuppressed, suppressedSystemItems, let page else { return }
      let item = page.navigationItem
      if let back = item.leftBarButtonItem {
        systemBackItem = back
        item.leftBarButtonItem = nil
      }
      if let right = item.rightBarButtonItems, !right.isEmpty {
        systemTrailingItems = right
        item.rightBarButtonItems = []
      }
      item.hidesBackButton = true
    }

    /// 页面不再由侧栏承载时归还入口，避免影响折叠回单栏或旧版布局。
    func restore() {
      guard isSuppressed else { return }
      isSuppressed = false
      observations = []
      for entry in hiddenControls {
        entry.control.alpha = entry.alpha
      }
      hiddenControls = []
      if suppressedSystemItems, let page {
        if let back = systemBackItem {
          page.navigationItem.leftBarButtonItem = back
        }
        if let hides = systemHidesBackButtonBeforeSuppression {
          page.navigationItem.hidesBackButton = hides
        }
        if !systemTrailingItems.isEmpty {
          page.navigationItem.rightBarButtonItems = systemTrailingItems
        }
        suppressedSystemItems = false
      }
      systemBackItem = nil
      systemTrailingItems = []
      systemHidesBackButtonBeforeSuppression = nil
    }

    private func observeChanges() {
      // UIKit 的按钮标题不走 KVO；文案变化由页面调用 `NENavigationView.notifyActionsChanged()`
      // 或 `refreshRailNavigation()` 刷新。这里只观察可靠的启用态与显隐。
      if let customBar {
        observations.append(customBar.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
          self?.notifyChange()
        })
      }
      for control in ([customBackControl] + customTrailingControls).compactMap({ $0 }) {
        observations.append(control.observe(\.isEnabled, options: [.new]) { [weak self] _, _ in
          self?.notifyChange()
        })
        observations.append(control.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
          self?.notifyChange()
        })
      }
      for item in systemTrailingItems {
        observations.append(item.observe(\.title, options: [.new]) { [weak self] _, _ in
          self?.notifyChange()
        })
        observations.append(item.observe(\.isEnabled, options: [.new]) { [weak self] _, _ in
          self?.notifyChange()
        })
      }
    }

    private func notifyChange() {
      let handler = onChange
      DispatchQueue.main.async { handler?() }
    }
  }
#endif
