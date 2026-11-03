import Foundation

/// A presentation identity and existing route parameters, without SDK model ownership.
@objcMembers public final class NEConversationOpenIntent: NSObject {
  public let key: String
  public let route: String
  public let parameters: [String: Any]
  public let requiresPresentationAction: Bool

  public init(key: String, route: String, parameters: [String: Any], requiresPresentationAction: Bool = false) {
    self.key = key
    self.route = route
    self.parameters = parameters
    self.requiresPresentationAction = requiresPresentationAction
    super.init()
  }
}

#if canImport(UIKit)
  import UIKit

  @objc public protocol NEConversationPresentationHandler: AnyObject {
    /// Returning false must have no presentation side effect; caller retains its old route.
    func openConversation(_ intent: NEConversationOpenIntent) -> Bool
  }

  /// Owns only navigation state; factories retain their existing business initialization.
  @objcMembers public final class NEConversationNavigationCoordinator: NSObject {
    public let navigationController: UINavigationController
    private let emptyViewController: UIViewController?
    public private(set) var activeIntent: NEConversationOpenIntent?
    public var controllerFactory: ((NEConversationOpenIntent) -> UIViewController?)?
    /// Apply existing location/recovery semantics to the retained chat page, without recreating it.
    public var presentationAction: ((NEConversationOpenIntent, UIViewController) -> Bool)?
    /// 当前会话页；空占位保留在栈底，返回按页面自身语义回到占位。
    private weak var activeController: UIViewController?

    public init(navigationController: UINavigationController) {
      self.navigationController = navigationController
      emptyViewController = navigationController.viewControllers.first
      currentPlaceholder = emptyViewController
      super.init()
    }

    /// 右列当前是否停留在空占位（没有打开任何页面）。
    public var isShowingPlaceholder: Bool {
      guard let top = navigationController.topViewController else { return false }
      if let current = currentPlaceholder { return top === current }
      return top === emptyViewController
    }

    /// 当前占位页（可替换为分区专属占位）。
    public private(set) var currentPlaceholder: UIViewController?

    /// 切换分区时展示该分区的占位页。
    public func showPlaceholder(_ placeholder: UIViewController) {
      activeIntent = nil
      activeController = nil
      currentPlaceholder = placeholder
      navigationController.setViewControllers([placeholder], animated: false)
    }

    public func reset() {
      activeIntent = nil
      activeController = nil
      currentPlaceholder = emptyViewController
      if let placeholder = emptyViewController {
        navigationController.setViewControllers([placeholder], animated: false)
      }
    }

    /// 用户手动返回/系统 pop 回占位后，intent 不应继续代表“右列仍打开会话”。
    @discardableResult public func syncActiveIntentWithNavigationStack() -> Bool {
      guard isShowingPlaceholder, activeIntent != nil || activeController != nil else { return false }
      activeIntent = nil
      activeController = nil
      return true
    }

    @discardableResult public func open(_ intent: NEConversationOpenIntent) -> Bool {
      precondition(Thread.isMainThread)
      guard !intent.key.isEmpty else { return false }
      if activeIntent?.key == intent.key {
        // 同一个会话：保持现状，只执行额外的定位动作
        if intent.requiresPresentationAction {
          guard let presentationAction,
                let root = activeController ?? navigationController.viewControllers.first,
                presentationAction(intent, root) else { return false }
        }
        // 定位/恢复动作作用在作为右列根的聊天页上。右列若还停在聊天之上的
        // 扩展页（历史搜索、Pin、收藏、设置等），必须同时收起扩展页回到聊天根，
        // 否则入口看起来"没有跳转"，用户手动返回后才看到已经定位到的消息。
        // 无定位动作时同样回到聊天根，与任务 P1.4"扩展页重选当前会话先回聊天根"一致。
        // 默认不做转场：跳转本身还要等聊天页异步加载锚点消息，转场会先露出旧位置。
        // 需要转场的来源（例如列表间切换）显式传入 `animated: true`。
        popExtensionsToChatRoot(animated: intent.parameters["animated"] as? Bool ?? false)
        return true
      }
      guard let controller = controllerFactory?(intent) else { return false }
      // 有占位根时把聊天压在其上，保留页面自身返回；没有占位（测试/自定义栈）时
      // 退回单页栈，避免凭空插入无意义页面。
      if let base = currentPlaceholder ?? emptyViewController, base !== controller {
        navigationController.setViewControllers([base, controller], animated: false)
      } else {
        navigationController.setViewControllers([controller], animated: false)
      }
      activeIntent = intent
      activeController = controller
      return true
    }

    /// 收起压在聊天根上的扩展页，只替换导航栈，不重建聊天根。
    private func popExtensionsToChatRoot(animated: Bool) {
      guard navigationController.viewControllers.count > 1 else { return }
      let target = activeController ?? navigationController.viewControllers.first
      guard let target, navigationController.viewControllers.contains(where: { $0 === target }) else {
        return
      }
      navigationController.popToViewController(target, animated: animated)
    }
  }
#endif
