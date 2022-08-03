
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM
import IQKeyboardManagerSwift
import NIMSDK
import MJRefresh
import AVFoundation
import NEKitCommon
import NEKitCore
import NEKitCommonUI
import WebKit

@objcMembers
open class ChatViewController: NEBaseViewController, UINavigationControllerDelegate, ChatInputViewDelegate, ChatViewModelDelegate, NIMMediaManagerDelegate,MessageOperationViewDelegate, UIGestureRecognizerDelegate {
    
    private let tag = "ChatViewController"
    public var viewmodel:ChatViewModel
    private var inputViewTopConstraint: NSLayoutConstraint?
    private var tableViewBottomConstraint: NSLayoutConstraint?
    public var menuView: ChatInputView = ChatInputView()
    public var operationView: MessageOperationView?
    private var playingCell: ChatAudioCell?
    private var atUsers = [NSRange]()
    private var timer: Timer?
    var replyView = ReplyView()
    
    var titleContent = ""

    public init(session: NIMSession) {
        self.viewmodel = ChatViewModel(session: session, anchor: nil)
        super.init(nibName: nil, bundle: nil)
        self.viewmodel.delegate = self
        IQKeyboardManager.shared.enable = false
        IQKeyboardManager.shared.enableAutoToolbar = false
        NIMSDK.shared().mediaManager.add(self)
        NIMSDK.shared().mediaManager.setNeedProximityMonitor(viewmodel.getHandSetEnable())
        //注册自定义消息的解析器
        NIMCustomObject.registerCustomDecoder(CustomAttachmentDecoder())
    }
        
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        commonUI()
        addObseve()
        loadData()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        if NIMSDK.shared().mediaManager.isPlaying() {
            NIMSDK.shared().mediaManager.stopPlay()
        }
    }
    //MARK: 子类可重写方法
    //load data的时候会调用
    open func getSessionInfo(session: NIMSession) {}

    
    /// 点击头像回调
    /// - Parameter model: cell模型
    open func didTapHeadPortrait(model:MessageContentModel?){
        
        if let isOut = model?.message?.isOutgoingMsg, isOut {
            Router.shared.use(MeSettingRouter, parameters: ["nav": navigationController as Any], closure: nil)
            return
        }
        if let uid = model?.message?.from {
            UserInfoProvider.shared.fetchUserInfo([uid]) {[weak self] error, users in
                if let u = users?.first {
                    Router.shared.use(ContactUserInfoPageRouter, parameters: ["nav": self?.navigationController as Any, "user" : u], closure: nil)
                }
            }
        }
    }
    
    /// 长按消息内容
    /// - Parameters:
    ///   - cell: 长按cell
    ///   - model: cell模型
    open func didLongTouchMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
        operationView?.removeFromSuperview()
        // get operations
        guard let items = viewmodel.avalibleOperationsForMessage(model) else {
            return
        }
        self.viewmodel.operationModel = model
        
//        size
        let w = items.count <= 5 ? 60.0 * Double(items.count) + 16.0 : 60.0 * 5 + 16.0
        let h = items.count <= 5 ? 56.0 + 16.0 : 56.0 * 2 + 16.0

        if let index = self.tableView.indexPath(for: cell) {
            let rectInTableView = self.tableView.rectForRow(at: index)
            let rectInView = self.tableView.convert(rectInTableView, to: self.tableView.superview)
            let topOffset = UIApplication.shared.statusBarFrame.size.height + self.navigationController!.navigationBar.frame.size.height
            var operationY = 0.0
            if topOffset + h > rectInView.origin.y {
//                under the cell
                operationY = rectInView.origin.y  + rectInView.size.height
            }else {
                operationY = rectInView.origin.y  - h
                
            }
            let frame = CGRect(x: 0, y: operationY, width: w, height: h)
            operationView = MessageOperationView(frame: frame)
            operationView!.delegate = self
            operationView!.items = items
            self.view.addSubview(operationView!)
        }
    }
    
    //MARK: lazy Method
    private lazy var brokenNetworkView:ChatBrokenNetworkView = {
        let view = ChatBrokenNetworkView.init(frame: CGRect.init(x: 0, y: kNavigationHeight + KStatusBarHeight, width: kScreenWidth, height: 36))
        return view
    }()
    
    private lazy var tableView:UITableView = {
        let tableView = UITableView.init(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(loadMoreData))
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    
    //MARK: UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        print("touch.view:\(touch.view)")
        guard let view = touch.view else {
            return true
        }
        if view.bounds.size.width == 60 {
            return false
        }
        // 点击重发按钮
        //点击撤回重新编辑按钮
        if view.isKind(of: UIButton.self) {
            return false
        }
        if view.isKind(of: UIImageView.self) {
            return false
        }
        return true
    }
    
    public func remoteUserEditing() {
        title = "正在输入中..."
        trigerEndTimer()
    }
    
    public func remoteUserEndEditing() {
        title = titleContent
    }
    
    @objc func timeoutEndEditing(){
        remoteUserEndEditing()
    }
    
    func trigerEndTimer(){
        if let t = timer, t.isValid == true {
            t.invalidate()
            timer = nil
        }
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(timeoutEndEditing), userInfo: nil, repeats: false)
    }
    
//    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.operationView?.removeFromSuperview()
//        if self.menuView.textField.isFirstResponder {
//            self.menuView.textField.resignFirstResponder()
//        }else {
//            self.layoutInputView(offset: 0)
//        }
//    }
    
    deinit {
        print("will deinit")
        
    }

}

//MARK: ChatBaseCellDelegate

extension ChatViewController: ChatBaseCellDelegate {

    func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
        didTapHeadPortrait(model: model)
    }
    
    func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
        if model?.type == .audio {
            if let audio = model?.message?.messageObject as? NIMAudioObject {
                self.startPlay(cell: cell as? ChatAudioCell, audio: audio)
            }
        }else if model?.type == .image {
            if let imageObject = model?.message?.messageObject as? NIMImageObject {
                var imageUrl = ""
                
                if let url = imageObject.url {
                    imageUrl = url
                }else {
                    if let path = imageObject.path, FileManager.default.fileExists(atPath: path) {
                        imageUrl = path
                    }
                }
                if imageUrl.count > 0 {
                    let showController = PhotoBrowserController(urls: viewmodel.getUrls(), url: imageUrl)
                    showController.modalPresentationStyle = .overFullScreen
                    self.present(showController, animated: false, completion: nil)
                }
                
//                if let url = imageObject.url {
//                    let showController = PhotoBrowserController(urls: viewmodel.getUrls(), url: url)
//                    showController.modalPresentationStyle = .overFullScreen
//                    self.present(showController, animated: false, completion: nil)
//                }
            }

        }else if model?.type == .video, let object = model?.message?.messageObject as? NIMVideoObject {
            print("video click")
            weak var weakSelf = self
            let videoPlayer = VideoPlayerViewController()
            videoPlayer.modalPresentationStyle = .overFullScreen
            if let path = object.path, FileManager.default.fileExists(atPath: path) == true {
                let url = URL(fileURLWithPath: path)
                videoPlayer.videoUrl = url
                videoPlayer.totalTime = object.duration
                print("video url : ", videoPlayer.videoUrl as Any)
                present(videoPlayer, animated: true, completion: nil)
            }else if let urlString = object.url, let path = object.path, let videoModel = model as? MessageVideoModel {
                print("fetch message attachment")
                
                videoModel.state = .Downalod
                if let left = cell as? ChatVideoLeftCell {
                    left.setModel(videoModel)
                }else if let right = cell as? ChatVideoRightCell {
                    right.setModel(videoModel)
                }
                
                viewmodel.downLoad(urlString, path) { progress in
                    videoModel.progress = progress
                    if progress >= 1.0 {
                        videoModel.state = .Success
                    }
                    videoModel.cell?.uploadProgress(progress)
                } _: { error in
                    if let err = error as NSError? {
                        weakSelf?.showToast(err.localizedDescription)
                    }
                }
            }
        }else if model?.type == .text {
//            location at replied message
            if model?.replyedModel != nil {
                if model?.message?.repliedMessageId != nil {
                    var index = -1
                    for (i, m) in self.viewmodel.messages.enumerated() {
                        if model?.message?.repliedMessageServerId == m.message?.serverID {
                            index = i
                            break
                        }
                    }
                    if index >= 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
                    }
                }
            }
        }else {
            print("else")
        }
    }
    
    func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
       didLongTouchMessageView(cell, model)
    }
    
    func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
        if let msg = model?.message {
            viewmodel.resendMessage(message: msg)
        }
    }
    
    func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?) {
        if model?.type == .revoke, model?.message?.messageType == .text {
            self.menuView.textField.text = model?.message?.text
            self.menuView.textField.becomeFirstResponder()
        }
    }
    
    func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?) {
        if let msg = model?.message, msg.session?.sessionType == .team {
            let readVC = ReadViewController(message: msg)
            self.navigationController?.pushViewController(readVC, animated: true)
        }
    }
}

//MARK: UITableViewDataSource,UITableViewDelegate
extension ChatViewController:UITableViewDataSource,UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewmodel.messages.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewmodel.messages[indexPath.row]
        var reuseId = ""
        if let isSend = model.message?.isOutgoingMsg, isSend {
            if model.replyedModel != nil {
                reuseId = "\(ChatReplyRightCell.self)"
            }else {
                switch model.type {
                case .text:
                    reuseId = "\(ChatTextRightCell.self)"
                case .image:
                    reuseId = "\(ChatImageRightCell.self)"
                case .audio:
                    reuseId = "\(ChatAudioRightCell.self)"
                case .video:
                    reuseId = "\(ChatVideoRightCell.self)"
                case .time, .tip, .notification:
                    reuseId = "\(ChatTimeTableViewCell.self)"
                case .revoke:
                    reuseId = "\(ChatRevokeRightCell.self)"
                default:
                    reuseId = "\(ChatBaseRightCell.self)"
                }
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
            if let c = cell as? ChatTimeTableViewCell {
                if let m = model as? MessageTipsModel {
                    c.setModel(m)
                }
                return c
            }else if let c = cell as? ChatBaseRightCell {
                c.delegate = self
                if let m = model as? MessageContentModel {
                    c.setModel(m)
                }
                return c
            }else {
                return ChatBaseRightCell()
            }
        }else {
            if model.replyedModel != nil {
                reuseId = "\(ChatReplyLeftCell.self)"
            }else {
                switch model.type {
                case .text:
                    reuseId = "\(ChatTextLeftCell.self)"
                case .image:
                    reuseId = "\(ChatImageLeftCell.self)"
                case .audio:
                    reuseId = "\(ChatAudioLeftCell.self)"
                case .video:
                    reuseId = "\(ChatVideoLeftCell.self)"
                case .time, .tip, .notification:
                    reuseId = "\(ChatTimeTableViewCell.self)"
                case .revoke:
                    reuseId = "\(ChatRevokeLeftCell.self)"
                default:
                    reuseId = "\(ChatBaseLeftCell.self)"
                }
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
            if let c = cell as? ChatTimeTableViewCell {
                if let m = model as? MessageTipsModel {
                    c.setModel(m)
                }
                return c
            }else if let c = cell as? ChatBaseLeftCell {
                c.delegate = self
                if let m = model as? MessageContentModel {
                    c.setModel(m)
                }
                return c
            }else {
                return ChatBaseLeftCell()
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("did select row ")
        self.operationView?.removeFromSuperview()
        if self.menuView.textField.isFirstResponder {
            self.menuView.textField.resignFirstResponder()
        }else {
            self.layoutInputView(offset: 0)
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let m = viewmodel.messages[indexPath.row];
        print("text:\(m.message?.text) height:\(m.height)")
        return CGFloat(m.height)
    }
}

//MARK: private method
extension ChatViewController {
    open func commonUI() {
        self.title = viewmodel.session.sessionId
        self.view.addSubview(tableView)
        self.tableViewBottomConstraint = tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -100)
        self.tableViewBottomConstraint?.isActive = true
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor,constant: kNavigationHeight + KStatusBarHeight),
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
        tableView.register(ChatTimeTableViewCell.self, forCellReuseIdentifier: "\(ChatTimeTableViewCell.self)")
        
        tableView.register(ChatBaseLeftCell.self, forCellReuseIdentifier: "\(ChatBaseLeftCell.self)")
        tableView.register(ChatBaseRightCell.self, forCellReuseIdentifier: "\(ChatBaseRightCell.self)")
        tableView.register(ChatTextRightCell.self, forCellReuseIdentifier: "\(ChatTextRightCell.self)")
        tableView.register(ChatTextLeftCell.self, forCellReuseIdentifier: "\(ChatTextLeftCell.self)")
        tableView.register(ChatAudioLeftCell.self, forCellReuseIdentifier: "\(ChatAudioLeftCell.self)")
        tableView.register(ChatAudioRightCell.self, forCellReuseIdentifier: "\(ChatAudioRightCell.self)")
        tableView.register(ChatImageLeftCell.self, forCellReuseIdentifier: "\(ChatImageLeftCell.self)")
        tableView.register(ChatImageRightCell.self, forCellReuseIdentifier: "\(ChatImageRightCell.self)")
        
        tableView.register(ChatRevokeLeftCell.self, forCellReuseIdentifier: "\(ChatRevokeLeftCell.self)")
        tableView.register(ChatRevokeRightCell.self, forCellReuseIdentifier: "\(ChatRevokeRightCell.self)")

        tableView.register(ChatVideoLeftCell.self, forCellReuseIdentifier: "\(ChatVideoLeftCell.self)")
        tableView.register(ChatVideoRightCell.self, forCellReuseIdentifier: "\(ChatVideoRightCell.self)")
        
        tableView.register(ChatReplyRightCell.self, forCellReuseIdentifier: "\(ChatReplyRightCell.self)")
        tableView.register(ChatReplyLeftCell.self, forCellReuseIdentifier: "\(ChatReplyLeftCell.self)")

        self.menuView.translatesAutoresizingMaskIntoConstraints = false
        self.menuView.delegate = self
        self.view.addSubview(self.menuView)
        
        self.inputViewTopConstraint = self.menuView.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100)
        NSLayoutConstraint.activate([
            self.menuView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.menuView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.menuView.heightAnchor.constraint(equalToConstant: 304),
        ])
        self.inputViewTopConstraint?.isActive = true
        
        weak var weakSelf = self
        NEChatDetectNetworkTool.shareInstance.netWorkReachability() { status in
            if status == .notReachable,let networkView = weakSelf?.brokenNetworkView{
                weakSelf?.view.addSubview(networkView)
            }else {
                weakSelf?.brokenNetworkView.removeFromSuperview()
            }
        }
        addRightAction(UIImage.ne_imageNamed(name: "three_point"), #selector(toSetting), self)
    }
    
    func loadData() {
//        title
        self.getSessionInfo(session: self.viewmodel.session)
        weak var weakSelf = self
      
         viewmodel.queryRoamMsgHasMoreTime_v2 { error, historyEnd, newEnd, models, index in
             if let ms = models, ms.count > 0 {
                 if let messages = weakSelf?.viewmodel.messages {
                     for index in 0..<messages.count {
                         let message = messages[index]
                         if message.message?.messageId == weakSelf?.viewmodel.anchor?.messageId {
                             print("messages real index : ", index)
                             print("messages text : ", message.message?.text as Any)
                         }
                     }
                 }
                 weakSelf?.tableView.reloadData()
                 if weakSelf?.viewmodel.isHistoryChat == true {
                     let indexPath = IndexPath(row: index, section: 0)
                     print("queryRoamMsgHasMoreTime_v2 index : ", index)
                     weakSelf?.tableView.scrollToRow(at: indexPath, at: .none, animated: false)
                     if newEnd <= 0 {
                         weakSelf?.addBottomLoadMore()
                     }
                 }else {
                     if let tempArray = weakSelf?.viewmodel.messages,tempArray.count > 0 {
                         weakSelf?.tableView.reloadData()
                         weakSelf?.tableView.scrollToRow(at: IndexPath(row: tempArray.count - 1, section: 0), at: .bottom, animated: false)
                     }
                 }
                 
             }else if let err = error {
                 weakSelf?.showToast(err.localizedDescription)
             }
         }
         
        
//        if viewmodel.isHistoryChat == false {
//            viewmodel.getMessageHistory({[weak self] error,isEmpty,messages in
//                if let err = error {
//                    NELog.errorLog(self?.tag ?? "ChatViewController", desc: "❌getMessageHistory error, error:\(err)")
//                }else {
//                    if let tempArray = weakSelf?.viewmodel.messages,tempArray.count > 0 {
//                        weakSelf?.tableView.reloadData()
//                        weakSelf?.tableView.scrollToRow(at: IndexPath(row: tempArray.count - 1, section: 0), at: .bottom, animated: false)
//                    }
//                }
//            })
//        }else {
//            print("queryRoamMsgHasMoreTime")
//            viewmodel.queryRoamMsgHasMoreTime_v2 { error, historyEnd, newEnd, models, index in
//                if let ms = models, ms.count > 0 {
//                    if let messages = weakSelf?.viewmodel.messages {
//                        for index in 0..<messages.count {
//                            let message = messages[index]
//                            if message.message?.messageId == weakSelf?.viewmodel.anchor?.messageId {
//                                print("messages real index : ", index)
//                                print("messages text : ", message.message?.text as Any)
//                            }
//                        }
//                    }
//                    let indexPath = IndexPath(row: index, section: 0)
//                    weakSelf?.tableView.reloadData()
//                    print("queryRoamMsgHasMoreTime_v2 index : ", index)
//                    weakSelf?.tableView.scrollToRow(at: indexPath, at: .none, animated: false)
//                    if newEnd <= 0 {
//                        weakSelf?.addBottomLoadMore()
//                    }
//                }else if let err = error {
//                    weakSelf?.showToast(err.localizedDescription)
//                }
//            }
//        }

    }
    
    @objc func loadMoreData(){
        weak var weakSelf = self
        viewmodel.dropDownRemoteRefresh { error, count, messages in
            print("dropDownRemoteRefresh messages count ", messages?.count as Any)
            
            weakSelf?.tableView.reloadData()
            if count>0 {
                weakSelf?.tableView.scrollToRow(at: IndexPath(row:count, section: 0), at: .top, animated: false)
            }
            weakSelf?.tableView.mj_header?.endRefreshing()
        }

//        viewmodel.getMoreMessageHistory { error, isEmpty, messageFrames in
//            weakSelf?.tableView.reloadData()
//            weakSelf?.tableView.mj_header?.endRefreshing()
//        }
    }
    
    @objc func loadFartherToNowData(){
        
    }
    
    @objc func loadCloserToNowData(){
        weak var weakSelf = self
        viewmodel.pullRemoteRefresh { error, end, datas in
            if end > 0 {
                weakSelf?.removeBottomLoadMore()
            }else {
                weakSelf?.tableView.mj_footer?.endRefreshing()
                weakSelf?.tableView.reloadData()
            }
        }
    }
    
    
    
    func addObseve() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyBoardWillShow(_ :)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyBoardWillHide(_ :)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
//        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTap))
//        tap.delegate = self
//        self.view.addGestureRecognizer(tap)
    }
    
    func addBottomLoadMore(){
        tableView.mj_footer = MJRefreshBackNormalFooter(refreshingTarget: self, refreshingAction: #selector(loadCloserToNowData))
    }
    
    func removeBottomLoadMore(){
        tableView.mj_footer?.endRefreshingWithNoMoreData()
        tableView.mj_footer = nil
        viewmodel.isHistoryChat = false //转为普通聊天页面
    }
    

    
//    MARK:键盘通知相关操作
    @objc func keyBoardWillShow(_ notification:Notification) {
        if self.menuView.currentType != .text {
            return
        }
        let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.layoutInputView(offset: keyboardRect.size.height)
        
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        })
        self.scrollTableViewToBottom()
    }

    @objc func keyBoardWillHide(_ notification:Notification) {
        if self.menuView.currentType != .text {
            return
        }
        if operationView?.superview != nil {
            operationView?.removeFromSuperview()
        }
        self.layoutInputView(offset: 0)
        self.scrollTableViewToBottom()
    }
    
    private func scrollTableViewToBottom() {
        print("self.viewmodel.messages.count\(self.viewmodel.messages.count)")
        print("self.tableView.numberOfRows(inSection: 0)\(self.tableView.numberOfRows(inSection: 0))")
        if self.viewmodel.messages.count > 0 {
            let indexPath = IndexPath(row: self.viewmodel.messages.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
//    offset：value which from self.view.bottom to inputView.bottom
    private func layoutInputView(offset: CGFloat) {
        self.inputViewTopConstraint?.constant = -100 - offset
        self.tableViewBottomConstraint?.constant = -100 - offset
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        })
    }

//    MARK:ChatInputViewDelegate
    public func sendText(text: String?) {
        guard let content = text, content.count > 0 else {
            self.showToast(localizable("text_is_nil"))
            return
        }
        if viewmodel.isReplying, let msg = self.viewmodel.operationModel?.message {
            
            viewmodel.replyMessage(MessageUtils.textMessage(text: content), msg) {[weak self] error  in
                if error != nil {
                    self?.view.makeToast(error?.localizedDescription)
                }else {
                    self?.viewmodel.isReplying = false
                    self?.replyView.removeFromSuperview()
                }
            }
            
        }else {
            viewmodel.sendTextMessage(text: content, {[weak self] error in
                if error != nil {
                    self?.view.makeToast(error?.localizedDescription)
                }
            })
        }
    }
    
    public func textChanged(text: String) -> Bool {
        if text == "@" {
            //做p2p类型判断
            if self.viewmodel.session.sessionType == .P2P {
                return true
            }else {
                showUserSelectVC(text: text)
                return false
            }
            
        }else {
            return true
        }
    }
    
    public func textDelete(range: NSRange, text: String) -> Bool {
        var index = -1
        var removeRange: NSRange?
        for (i, r) in atUsers.enumerated() {
            let rightIndex = r.location + r.length - 1
            if rightIndex == range.location {
                index = i
                removeRange = r
                break
            }
        }
        if index >= 0 {
            atUsers.remove(at: index)
            if let text = self.menuView.textField.text {
                self.menuView.textField.text = text.substring(to: text.index(text.startIndex, offsetBy: removeRange!.location))
            }
            return false
        }
        return true
    }
    
    public func textFieldDidChange(_ textField: UITextView){
        if let text = textField.text {
            if text.count > 0 {
                viewmodel.sendInputTypingState()
            }else {
                viewmodel.sendInputTypingEndState()
            }
        }
    }

    
    public func textFieldDidEndEditing(_ textField: UITextView){
        viewmodel.sendInputTypingEndState()
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextView){
        if let count = textField.text?.count, count > 0 {
            viewmodel.sendInputTypingState()
        }
    }
    
    public func willSelectItem(button: UIButton, index: Int) {
        if index == 0 {
            self.layoutInputView(offset: 204)
            self.scrollTableViewToBottom()
        }else if index == 1 {
            self.layoutInputView(offset: 204)
            self.scrollTableViewToBottom()
        }else if index == 2 {
//            showMenue(sourceView: view)
            //showBottomAlert(self, false)
            goPhotoAlbumWithVideo(self)
        }else if index == 3 {
            showBottomVideoAction(self, false)
        }else {
            self.showToast(localizable("open_soon"))
        }
    }
    
    func showMenue(sourceView: UIView) {
        let alert = UIAlertController(title: localizable("请选择"), message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        let camera = UIAlertAction(title: localizable("拍照"), style: .default) { action in
            self.takePhoto()
        }
        let photo = UIAlertAction(title: localizable("从相册选择"), style: .default) { action in
            self.willSelectImage()
        }
        
        let cancel = UIAlertAction(title: "取消", style: .cancel) { action in
            
        }
    
        alert.addAction(camera)
        alert.addAction(photo)
        alert.addAction(cancel)
        let popover = alert.popoverPresentationController
        if popover != nil {
            popover?.sourceView = sourceView
            popover?.permittedArrowDirections = .any
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func willSelectImage() {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.delegate = self
        imagePickerVC.allowsEditing = false
        imagePickerVC.sourceType = .photoLibrary
        self.present(imagePickerVC, animated: true) {
        }
    }
    
    func takePhoto() {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.delegate = self
        imagePickerVC.allowsEditing = false
        imagePickerVC.sourceType = .camera
        self.present(imagePickerVC, animated: true) {
        }
    }
    
//    MARK:UIImagePickerControllerDelegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        send message
        
        picker.dismiss(animated: true, completion: nil)

        
        if let url = info[.mediaURL] as? URL {
            // video
            print("image picker video : url", url)
//            NELog.infoLog("send video message", desc: error?.localizedDescription ?? "no error")
            weak var weakSelf = self
            viewmodel.sendVideoMessage(url: url) { error in
                
                if let err = error {
                    NELog.errorLog("send video message", desc: err.localizedDescription)
                    weakSelf?.showToast(err.localizedDescription)
                }
            }
            return
        }
        
        guard let image = info[.originalImage] as? UIImage else {
            self.showToast(localizable("image_is_nil"))
            return
        }
        viewmodel.sendImageMessage(image: image, {[weak self] error in
            NELog.infoLog("send image message", desc: error?.localizedDescription ?? "no error")
            if error != nil {
                self?.view.makeToast(error?.localizedDescription)
            }else {
                
            }
        })
    }
    
//    MARK: ChatViewModelDelegate
    public func onRecvMessages(_ messages: [NIMMessage]) {
        insertRows()
        self.viewmodel.markRead(messages: messages) { error in
            print("mark read \(error?.localizedDescription)")
        }
    }
    
    public func willSend(_ message: NIMMessage) {
        insertRows()
    }
    
    public func send(_ message: NIMMessage, progress: Float) {
    
    }
    
    public func send(_ message: NIMMessage, didCompleteWithError error: Error?) {
        if self.indexPathsWithMessags([message]).count > 0 {
            self.tableViewReloadIndexs(self.indexPathsWithMessags([message]))
        }
    }
        
    private func indexPathsWithMessags(_ messages:[NIMMessage]) -> [IndexPath] {
        var indexPaths = [IndexPath]()
        for messageModel in messages {
            for (i, model) in self.viewmodel.messages.enumerated() {
                if model.message?.messageId == messageModel.messageId {
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
            }
        }
        return indexPaths
    }

    
    public func onDeleteMessage(_ message: NIMMessage, atIndexs: [IndexPath]) {
        if atIndexs.isEmpty {
            return
        }
//        self.tableView.reloadData()
        tableViewDeleteIndexs(atIndexs)
    }
    
    public func updateDownloadProgress(_ message: NIMMessage, atIndex: IndexPath, progress: Float) {
        tableViewUpdateDownload(atIndex)
    }
    
    public func onRevokeMessage(_ message: NIMMessage, atIndexs: [IndexPath]) {
        if atIndexs.isEmpty {
            return
        }
        tableViewReloadIndexs(atIndexs)
    }
    
    public func onAddMessagePin(_ message: NIMMessage, atIndexs: [IndexPath]) {
        tableViewReloadIndexs(atIndexs)
    }
    
    public func onRemoveMessagePin(_ message: NIMMessage, atIndexs: [IndexPath]) {
        tableViewReloadIndexs(atIndexs)
    }
        
    public func tableViewDeleteIndexs(_ indexs:[IndexPath]) {
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: indexs, with: .none)
        self.tableView.endUpdates()
    }
    
    public func tableViewReloadIndexs(_ indexs:[IndexPath]) {
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: indexs, with: .none)
        self.tableView.endUpdates()
    }
    
    public func didReadedMessageIndexs() {
        if let indexPaths = self.tableView.indexPathsForVisibleRows, indexPaths.count > 0 {
            self.tableView.beginUpdates()
    //        self.tableView.reloadRows(at: indexs, with: .none)
            self.tableView.reloadRows(at: indexPaths, with: .none)
            self.tableView.endUpdates()
        }
    }
    
    public func tableViewUpdateDownload(_ index: IndexPath){
        tableView.beginUpdates()
        tableView.reloadRows(at: [index], with: .none)
        tableView.endUpdates()
    }
    
    
    // record audio
    public func startRecord() {
        let dur = 60.0
        if NEAuthManager.hasAudioAuthoriztion() {
            NIMSDK.shared().mediaManager.record(forDuration: dur)
        }else {
            NEAuthManager.requestAudioAuthorization { granted in
                if granted {
                }else {
                    DispatchQueue.main.async {
                        self.showToast(localizable("没有麦克风权限"))
                    }
                }
            }
        }
    }
    
    public func moveOutView() {
        
    }
    
    public func moveInView() {
        
    }
    
    public func endRecord(insideView: Bool) {
        print("[record] stop:\(insideView)")
        if insideView {
//            send
            NIMSDK.shared().mediaManager.stopRecord()
        }else {
//            cancel
            NIMSDK.shared().mediaManager.cancelRecord()
        }
    }
    
    @objc func viewTap(tap:UITapGestureRecognizer) {
        self.operationView?.removeFromSuperview()
        if self.menuView.textField.isFirstResponder {
            self.menuView.textField.resignFirstResponder()
        }else {
            self.layoutInputView(offset: 0)
        }
    }
    
    //MARK: audio play
    private func startPlay(cell: ChatAudioCell?, audio: NIMAudioObject) {
        if cell?.isPlaying == true {
            self.stopPlay()
        }else {
            self.stopPlay()
            self.playingCell = cell
            self.playingCell?.startAnimation()
            if let url = audio.path {
                NIMSDK.shared().mediaManager.switch(.speaker)
                NIMSDK.shared().mediaManager.play(url)
            }
        }
    }
    
    private func stopPlay() {
        if NIMSDK.shared().mediaManager.isPlaying() {
            self.playingCell?.startAnimation()
            NIMSDK.shared().mediaManager.stopPlay()
        }
    }

//    private func startPlay() {
//        if NIMSDK.shared().mediaManager.isPlaying() {
//            self.playingCell?.startAnimation()
//            NIMSDK.shared().mediaManager.stopPlay()
//        }
//    }
//    MARK: NIMMediaManagerDelegate
//    play
    public func playAudio(_ filePath: String, didBeganWithError error: Error?) {
        print(#function + "\(error)")
        if let e = error {
            self.showToast(e.localizedDescription)
            // stop
            self.playingCell?.stopAnimation()
        }
    }
    
    public func playAudio(_ filePath: String, didCompletedWithError error: Error?) {
        print(#function + "\(error)")
        if let e = error {
            self.showToast(e.localizedDescription)
        }
        // stop
        self.playingCell?.stopAnimation()
    }
    
    public func stopPlayAudio(_ filePath: String, didCompletedWithError error: Error?) {
        print(#function + "\(error)")
        if let e = error {
            self.showToast(e.localizedDescription)
        }
        self.playingCell?.stopAnimation()
    }
    
    public func playAudio(_ filePath: String, progress value: Float) {
    }
    
    public func playAudioInterruptionEnd() {
        print(#function )
    }
    
    public func playAudioInterruptionBegin() {
        print(#function )
        //stop play
        self.playingCell?.stopAnimation()
    }
    
//    record
    public func recordAudio(_ filePath: String?, didBeganWithError error: Error?) {
        print("[record] sdk Began error:\(error)")

    }
    
    public func recordAudio(_ filePath: String?, didCompletedWithError error: Error?) {
        print("[record] sdk Completed error:\(error)")
        self.menuView.stopRecordAnimation()
        guard let fp = filePath else {
            self.showToast(error?.localizedDescription ?? "")
            return
        }
        let dur = recordDuration(filePath: fp)
        
        print("dur:\(dur)")
        if dur > 1 {
            self.viewmodel.sendAudioMessage(filePath: fp, { error in
                if let e = error {
                    self.showToast(e.localizedDescription)
                }else {
                    
                }
            })
        }else {
            self.showToast(localizable("录音时间太短"))
        }
    }
    
    public func recordAudioDidCancelled() {
        print("[record] sdk cancel")
    }
    
    public func recordAudioProgress(_ currentTime: TimeInterval) {
         
    }
    public func recordAudioInterruptionBegin() {
        print(#function )
    }
    
//    MARK: Private Method
    private func recordDuration(filePath: String) -> Float64 {
        let avAsset = AVURLAsset(url: URL(fileURLWithPath: filePath))
        return CMTimeGetSeconds(avAsset.duration)
    }

    private func insertRows() {
        let oldRows = self.tableView.numberOfRows(inSection: 0)
        if oldRows == 0 {
            self.tableView.reloadData()
            return
        }
        if oldRows == self.viewmodel.messages.count {
            self.tableView.reloadData()
            return
        }
        var indexs = [IndexPath]()
        for (i, model) in self.viewmodel.messages.enumerated() {
            if i >= oldRows {
                indexs.append(IndexPath(row: i, section: 0))
            }
        }
        
        print("oo indexs:\(indexs)")
        print("oo:\(self.viewmodel.messages.count)")
        if !indexs.isEmpty {
            self.tableView.insertRows(at: indexs, with: .none)
            tableView.scrollToRow(at: IndexPath(row: viewmodel.messages.count - 1, section: 0), at: .bottom, animated: false)
        }

    }
    
    private func showUserSelectVC(text: String) {
        let selectVC = SelectUserViewController(sessionId: self.viewmodel.session.sessionId)
        selectVC.modalPresentationStyle = .formSheet
        selectVC.selectedBlock = { [weak self] index, model in
            var resultText = ""
            var location = 0
            var length = 0
            if let t = self?.menuView.textField.text, t.count > 0 {
                resultText = t
                location = t.count
            }
            if index == 0 {
                let addText = text + localizable("user_select_all") + " "
                resultText = resultText + addText
                length = addText.count
                let range = NSRange(location: location, length: length)
                self?.atUsers.append(range)
            }else {
                if let m  = model {
                    let addText = text + m.atNameInTeam() + " "
                    resultText = resultText + addText
                    length = addText.count
                    let range = NSRange(location: location, length: length)
                    self?.atUsers.append(range)
                }
            }
            self?.menuView.textField.text = resultText
        }
        self.present(selectVC, animated: true, completion: nil)
    }

//    MARK: MessageOperationViewDelegate
    public func didSelectedItem(item: OperationItem) {
        switch item.type {
        case .copy:
            copyMessage()
        case .delete:
            deleteMessage()
        case .reply:
            showReplyMessageView()
        case .recall:
            recallMessage()
        case .collection:
            collectionMessage()
        case .forward:
            forwardMessage()
        case .pin:
            pinMessage()
        case .removePin:
            removePinMessage()
        default:
            doNothing()
        }
    }
    
    private func doNothing() {
        
    }
    
    private func copyMessage() {
        if let model = viewmodel.operationModel as? MessageTextModel, let text = model.attributeStr {
            let pasteboard = UIPasteboard.general
            pasteboard.string = text.string
            self.showToast(localizable("copy_success"))
        }
    }
    
    private func deleteMessage() {
        self.showAlert(message: localizable("message_delete_comfirm")) {
            if let message = self.viewmodel.operationModel?.message {
                self.viewmodel.deleteMessage(message: message)
            }
        }
    }
    
    private func showReplyMessageView() {
        viewmodel.isReplying = true
        self.view.addSubview(self.replyView)
        self.replyView.closeButton.addTarget(self, action: #selector(cancelReply), for: .touchUpInside)
        self.replyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.replyView.leadingAnchor.constraint(equalTo: self.menuView.leadingAnchor),
            self.replyView.trailingAnchor.constraint(equalTo: self.menuView.trailingAnchor),
            self.replyView.bottomAnchor.constraint(equalTo: self.menuView.topAnchor),
            self.replyView.heightAnchor.constraint(equalToConstant: 36)
        ])
        if let message = viewmodel.operationModel?.message {
            var text = localizable("msg_reply")
            if let name = viewmodel.operationModel?.shortName  {
                text = text + name
            }
            text = text + ":"
            switch message.messageType {
            case .text:
                if let t = message.text {
                    text = text + t
                }
            case .image:
                text = text + localizable("msg_image")
            case .audio:
                text = text + localizable("msg_audio")
            case .video:
                text = text + localizable("msg_video")
            default:
                text = text + ""
            }
            self.replyView.textLabel.text = text
        }
    }
    
     @objc private func cancelReply(button: UIButton) {
        self.replyView.removeFromSuperview()
        self.viewmodel.isReplying = false
    }
    
    private func recallMessage() {
        self.showAlert(message: localizable("message_revoke_confim")) {
            if let message = self.viewmodel.operationModel?.message {
                self.viewmodel.revokeMessage(message: message) { error in
                    if error != nil {
                        self.showToast(error!.localizedDescription)
                    }else {
    //                    自己撤回成功 & 收到对方撤回 都会走回调方法 onRevokeMessage
                        // 撤回成功的逻辑统一在代理方法中处理 onRevokeMessage
                    }
                }
            }
        }

    }
    
    private func collectionMessage() {
        if let message = viewmodel.operationModel?.message {
            viewmodel.addColletion(message) { error, info in
                if error != nil {
                    self.showToast(error!.localizedDescription)
                }else {
                    self.showToast(localizable("collection_success"))
                }
            }
        }
    }
    
    private func forwardMessage() {
        if let message = viewmodel.operationModel?.message {
            weak var weakSelf = self
            let userAction = UIAlertAction(title: localizable("contact_user"), style: .default) { action in
                
                Router.shared.register(ContactSelectedUsersRouter) { param in
                    print("user setting accids : ", param)
                    var items = [ForwardItem]()
                    
                    
                    if let users = param["im_user"] as? [NIMUser] {
                        users.forEach { user in
                            let item = ForwardItem()
                            item.uid = user.userId
                            item.avatar = user.userInfo?.avatarUrl
                            item.name = user.userInfo?.nickName
                            items.append(item)
                        }
                        
                        let forwardAlert = ForwardAlertViewController()
                        forwardAlert.setItems(items)
                        if let senderName = message.senderName{
                            forwardAlert.context = senderName
                        }
                        weakSelf?.addChild(forwardAlert)
                        weakSelf?.view.addSubview(forwardAlert.view)
                        
                        forwardAlert.sureBlock = {
                            print("sure click ")
                            weakSelf?.viewmodel.forwardUserMessage(message, users)
                        }
                    }
                   

                }
                var param = [String: Any]()
                param["nav"] = weakSelf?.navigationController as Any
                param["limit"] = 6
                if let session = weakSelf?.viewmodel.session, session.sessionType == .P2P {
                    var filters = Set<String>()
                    filters.insert(session.sessionId)
                    param["filters"] = filters
                }
                Router.shared.use(ContactUserSelectRouter, parameters: param, closure: nil)

            }
            
            let teamAction = UIAlertAction(title: localizable("team"), style: .default) { action in
                
                Router.shared.register(ContactTeamDataRouter) { param in
                    if let team = param["team"] as? NIMTeam {
                        let item = ForwardItem()
                        item.avatar = team.avatarUrl
                        item.name = team.getShowName()
                        item.uid = team.teamId
                        
                        let forwardAlert = ForwardAlertViewController()
                        forwardAlert.setItems([item])
                        if let senderName = message.senderName{
                            forwardAlert.context = senderName
                        }
                        weakSelf?.addChild(forwardAlert)
                        weakSelf?.view.addSubview(forwardAlert.view)
                        weakSelf?.viewmodel.forwardTeamMessage(message, team)
                    }
                }
                
                Router.shared.use(ContactTeamListRouter, parameters: ["nav": weakSelf?.navigationController as Any], closure: nil)
            }
            
            let cancelAction = UIAlertAction(title: localizable("cancel"), style: .cancel) { action in
                
            }
            
            showActionSheet([userAction, teamAction, cancelAction])
        }
    }
    
    private func pinMessage() {
        if let message = self.viewmodel.operationModel?.message {
            viewmodel.pinMessage(message) {[weak self] error, pinItem, index in
                if error != nil {
                    self?.view.makeToast(error?.localizedDescription)
                }else {
//                    update UI
                    if index >= 0 {
                        self?.tableViewReloadIndexs([IndexPath(row: index, section: 0)])
                    }
                }
 
            }
        }
    }
    
    private func removePinMessage() {
        if let message = self.viewmodel.operationModel?.message {
            viewmodel.removePinMessage(message) { [weak self] error, pinItem, index in
                if error != nil {
                    self?.view.makeToast(error?.localizedDescription)
                }else {
//                    update UI
                    if index >= 0 {
                        self?.tableViewReloadIndexs([IndexPath(row: index, section: 0)])
                    }
                }
            }
        }
    }
}

extension ChatViewController {
    @objc func toSetting() {
        if viewmodel.session.sessionType == .team {
            Router.shared.use(TeamSettingViewRouter, parameters: ["nav": navigationController as Any, "teamid": viewmodel.session.sessionId], closure: nil)
        }else if viewmodel.session.sessionType == .P2P {
            let userSetting = UserSettingViewController()
            userSetting.userId = viewmodel.session.sessionId
            navigationController?.pushViewController(userSetting, animated: true)
        }
    }
}
