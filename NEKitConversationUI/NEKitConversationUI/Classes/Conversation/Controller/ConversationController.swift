
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCommonUI
import NEKitCore


@objcMembers
open class ConversationController: UIViewController {
    
    let viewmodel = ConversationViewModel()
    private var listCtrl = ConversationListViewController()

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    func setupSubviews(){
        
//        NEKitConversationConfig.shared.ui.avatarType = .rectangle
        
        listCtrl.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChild(listCtrl)
        self.view.addSubview(navView)
        self.view.addSubview(listCtrl.view)

        NSLayoutConstraint.activate([
            navView.topAnchor.constraint(equalTo: self.view.topAnchor),
            navView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            navView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            navView.heightAnchor.constraint(equalToConstant:NEConstant.navigationHeight + NEConstant.statusBarHeight + 16)
        ])
        
        NSLayoutConstraint.activate([
            listCtrl.view.topAnchor.constraint(equalTo: navView.bottomAnchor),
            listCtrl.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            listCtrl.view.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            listCtrl.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    //MARK: lazyMethod
    private lazy var navView:ConversationNavView = {
        let nav = ConversationNavView.init(frame: CGRect.zero)
        nav.translatesAutoresizingMaskIntoConstraints = false
        nav.backgroundColor = .white
        nav.delegate = self
        
        nav.isHidden = NEKitConversationConfig.shared.ui.hiddenNav
        return nav
    }()
    
    public lazy var popListController: PopListViewController = {
        let popController = PopListViewController()
        return popController
    }()

}

extension ConversationController: ConversationNavViewDelegate {
    
    func searchAction(){
        let ctrl = ConversationSearchController()
        self.navigationController?.pushViewController(ctrl, animated: true)
    }
    
    func didClickAddBtn() {
        print("add click")
        
        if self.children.contains(popListController) == false {
            popListController.itemDatas = getPopListItems()
            self.addChild(popListController)
            popListController.view.frame = listCtrl.view.frame
        }
        if popListController.view.superview != nil {
            popListController.removeSelf()
        }else {
            view.addSubview(popListController.view)
        }
    }
    
    func getPopListItems() -> [PopListItem]{
        
        weak var weakSelf = self
        var items = [PopListItem]()
        let addFriend = PopListItem()
        addFriend.showName = localizable("add_friend")
        addFriend.image = UIImage.ne_imageNamed(name: "add_friend")
        addFriend.completion = {
            Router.shared.use(ContactSearchUserRouter, parameters: ["nav": self.navigationController as Any]) { obj, routerState, str in
            }
        }
        items.append(addFriend)
        
        let createGroup = PopListItem()
        createGroup.showName = localizable("create_discussion_group")
        createGroup.image = UIImage.ne_imageNamed(name: "create_discussion")
        createGroup.completion = {
            weakSelf?.createDiscussGroup()
        }
        items.append(createGroup)
        
        let createDicuss = PopListItem()
        createDicuss.showName = localizable("create_senior_group")
        createDicuss.image =  UIImage.ne_imageNamed(name: "create_group")
        createDicuss.completion = {
            weakSelf?.createSeniorGroup()
        }
        items.append(createDicuss)
        
        return items
    }
    
    func createDiscussGroup(){
        Router.shared.register(ContactSelectedUsersRouter) { param in
            print("user setting accids : ", param)
            Router.shared.use(TeamCreateDisuss, parameters: param, closure: nil)
        }
        Router.shared.use(ContactUserSelectRouter, parameters: ["nav": navigationController as Any, "limit": 200], closure: nil)
        weak var weakSelf = self
        Router.shared.register(TeamCreateDiscussResult) { param in
            print("create discuss ", param)
            if let code = param["code"] as? Int, let teamid = param["teamId"] as? String, code == 0 {
                let session = weakSelf?.viewmodel.repo.createTeamSession(teamid)
                Router.shared.use(ChatPushGroupVC, parameters: ["nav": weakSelf?.navigationController as Any, "session" : session as Any], closure: nil)
            }else if let msg = param["msg"] as? String {
                weakSelf?.showToast(msg)
            }
        }
    }
    
    func createSeniorGroup(){
        Router.shared.register(ContactSelectedUsersRouter) { param in
            Router.shared.use(TeamCreateSenior, parameters: param, closure: nil)
        }
        Router.shared.use(ContactUserSelectRouter, parameters: ["nav": navigationController as Any, "limit": 200], closure: nil)
        weak var weakSelf = self
        Router.shared.register(TeamCreateSeniorResult) { param in
            print("create senior : ", param)
            if let code = param["code"] as? Int, let teamid = param["teamId"] as? String, code == 0 {
                let session = weakSelf?.viewmodel.repo.createTeamSession(teamid)
                Router.shared.use(ChatPushGroupVC, parameters: ["nav": weakSelf?.navigationController as Any, "session" : session as Any], closure: nil)
            }else if let msg = param["msg"] as? String {
                weakSelf?.showToast(msg)
            }
        }
    }
}
