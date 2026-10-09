// Standalone UIKit reproduction of accessibility-triggered history pagination.
// This is a reduced fixture, not a build of NEChatUIKit or the IM Demo.
import UIKit

var events = [[String: Any]]()
var pendingFlush = false
func log(_ name: String, _ fields: [String: Any] = [:]) {
    var e = fields
    e["event"] = name
    e["time"] = ProcessInfo.processInfo.systemUptime
    events.append(e)
    if !pendingFlush {
        pendingFlush = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("events.json")
            try! JSONSerialization.data(withJSONObject: events, options: [.sortedKeys]).write(to: url)
            pendingFlush = false
        }
    }
}
class ProbeWindow: UIWindow {
    override func sendEvent(_ event: UIEvent) {
        for touch in event.allTouches ?? [] {
            let p = touch.location(in: self)
            log("touch", ["phase": touch.phase.rawValue, "x": p.x, "y": p.y])
        }
        super.sendEvent(event)
    }
}
class ProbeTable: UITableView {
    override func setContentOffset(_ offset: CGPoint, animated: Bool) {
        log("setOffset", ["y": offset.y, "animated": animated, "stack": Thread.callStackSymbols])
        super.setContentOffset(offset, animated: animated)
    }
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        log("scrollRect", ["rect": NSCoder.string(for: rect), "stack": Thread.callStackSymbols])
        super.scrollRectToVisible(rect, animated: animated)
    }
}
class ProbeText: UITextView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool { false }
    override func becomeFirstResponder() -> Bool {
        log("becomeFirstResponder", ["row": tag])
        return super.becomeFirstResponder()
    }
}
class Bubble: UITableViewCell, UITextViewDelegate {
    let label = ProbeText()
    var selectedTextRange: NSRange?
    var showMenu: ((Bubble) -> Void)?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        label.isEditable = false
        label.isSelectable = true
        label.isScrollEnabled = false
        label.delegate = self
        label.textContainerInset = .zero
        label.contentInset = .zero
        label.textContainer.lineFragmentPadding = 0
        label.font = .systemFont(ofSize: 16)
        label.backgroundColor = .systemCyan.withAlphaComponent(0.3)
        label.dataDetectorTypes = [.link, .phoneNumber]
        contentView.addSubview(label)
        label.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(selectAllRange(_:))))
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: bounds.width - 192, y: 22, width: 142, height: 38)
    }
    @objc func selectAllRange(_ gesture: UILongPressGestureRecognizer) {
        log("longPress", ["state": gesture.state.rawValue, "row": tag])
        let range = NSRange(location: 0, length: label.text.utf16.count)
        label.selectedRange = range
        selectedTextRange = range
        showMenu?(self)
        _ = label.becomeFirstResponder()
    }
    func textViewDidChangeSelection(_ textView: UITextView) {
        log("selection", ["row": tag, "range": NSStringFromRange(textView.selectedRange)])
        if textView.selectedRange.length > 0 && selectedTextRange != nil {
            selectedTextRange = textView.selectedRange
            showMenu?(self)
            _ = label.becomeFirstResponder()
        }
    }
}
class ProbeController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let table = ProbeTable()
    let menu = UILabel()
    var messages = Array(0..<120)
    var ready = false
    var loadedHistory = false
    let guardVisibility = ProcessInfo.processInfo.arguments.contains("--guard-visibility")
    var displayed = Set<String>()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        table.frame = CGRect(x: 0, y: 95, width: view.bounds.width, height: view.bounds.height - 195)
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 76
        table.separatorStyle = .none
        table.register(Bubble.self, forCellReuseIdentifier: "bubble")
        view.addSubview(table)
        table.panGestureRecognizer.addTarget(self, action: #selector(panned(_:)))
        menu.backgroundColor = .darkGray
        menu.textColor = .white
        menu.textAlignment = .center
        menu.text = "Copy   Reply   Forward"
        menu.isHidden = true
        view.addSubview(menu)
        let title = UILabel(frame: CGRect(x: 20, y: 55, width: 340, height: 35))
        title.text = "Selection probe — 3 second hold"
        view.addSubview(title)
        table.reloadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let nearTop = ProcessInfo.processInfo.arguments.contains("--near-top")
        table.scrollToRow(at: IndexPath(row: nearTop ? 12 : messages.count - 1, section: 0), at: nearTop ? .top : .bottom, animated: false)
        ready = true
        log("ready", ["offset": table.contentOffset.y, "size": NSCoder.string(for: view.bounds.size)])
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bubble", for: indexPath) as! Bubble
        cell.tag = indexPath.row
        cell.label.tag = indexPath.row
        cell.label.text = "Message \(messages[indexPath.row])"
        cell.showMenu = { [weak self] cell in
            guard let self else { return }
            let rect = cell.convert(cell.bounds, to: self.view)
            self.menu.frame = CGRect(x: 20, y: rect.minY - 72, width: self.view.bounds.width - 40, height: 65)
            self.menu.isHidden = false
            log("menu", ["row": cell.tag, "offset": self.table.contentOffset.y])
        }
        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let intersects = tableView.rectForRow(at: indexPath).intersects(tableView.bounds)
        if displayed.insert("\(indexPath.row)-\(intersects)").inserted {
            log("willDisplay", ["row": indexPath.row, "intersectsViewport": intersects,
                                "stack": indexPath.row == 0 ? Thread.callStackSymbols : []])
        }
        // Mirrors ChatViewController.willDisplay history preloading. The network
        // response is a local, delayed insertion; there is no gesture-specific trigger.
        guard ready, messages.count >= 100, !loadedHistory, indexPath.row <= 10 else { return }
        if guardVisibility && !tableView.rectForRow(at: indexPath).intersects(tableView.bounds) {
            return
        }
        loadedHistory = true
        log("preload", ["row": indexPath.row, "offset": tableView.contentOffset.y])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let count = 50
            self.messages.insert(contentsOf: Array(-50..<0), at: 0)
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: indexPath.row + count - 1, section: 0), at: .top, animated: false)
            log("historyRestore", ["offset": tableView.contentOffset.y])
        }
    }
    @objc func panned(_ gesture: UIPanGestureRecognizer) {
        let p = gesture.translation(in: view)
        log("pan", ["state": gesture.state.rawValue, "dx": p.x, "dy": p.y])
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        log("scroll", ["offset": scrollView.contentOffset.y, "dragging": scrollView.isDragging,
                       "tracking": scrollView.isTracking, "decelerating": scrollView.isDecelerating,
                       "stack": Thread.callStackSymbols])
    }
}
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = ProbeWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = ProbeController()
        window!.makeKeyAndVisible()
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
