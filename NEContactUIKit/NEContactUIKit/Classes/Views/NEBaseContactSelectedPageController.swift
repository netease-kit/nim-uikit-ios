//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseContactSelectedPageController: NEContactBaseViewController, FusionContactSelectedDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  /// 选择数量限制，默认选择10， 可从外部传入
  public var limit = 10 {
    didSet {
      for controller in childrenControllers {
        controller.limit = limit
      }
    }
  }

  /// page view 视图控制器
  public var childrenControllers = [NEBaseFusionContactSelectedController]()

  /// 选择确定按钮
  public var selectedSureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 76, height: 32))
  /// 防重变量
  var isRequesting = false

  public var userId: String?

  /// 内容controller集合
  public var contentControllers = [NEBaseFusionContactSelectedController]()

  /// 选择记录
  public var selectArray = [NEFusionContactCellModel]()

  /// 显示选中背景
  public lazy var selectCollectionBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.layer.cornerRadius = 4
    view.isHidden = true
    return view
  }()

  /// 显示选中列表
  public lazy var selectCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collectView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    collectView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    collectView.accessibilityIdentifier = "id.selected"
    return collectView
  }()

  var collectionBackViewTopMargin: CGFloat = 0
  var collectionBackViewHeight: CGFloat = 52
  public var collectionBackViewTopAnchor: NSLayoutConstraint?
  var pagingViewControllerTopAnchor: NSLayoutConstraint?

  public init(filterUsers: Set<String>? = nil) {
    super.init(nibName: nil, bundle: nil)
    if let controllers = getContentControllers(filterUsers) {
      contentControllers.append(contentsOf: controllers)
    }
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    title = localizable("select")
    setupNavSureItem()
    setupPageContent()
  }

  /// 获取page view 内容，在子类中实现
  /// - Parameter filterUsers: 用户过滤
  open func getContentControllers(_ filterUsers: Set<String>? = nil) -> [NEBaseFusionContactSelectedController]? {
    nil
  }

  /// UI 初始化
  open func setupPageContent() {
    view.addSubview(selectCollectionBackView)
    collectionBackViewTopAnchor = selectCollectionBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + collectionBackViewTopMargin)
    collectionBackViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      selectCollectionBackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
      selectCollectionBackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
      selectCollectionBackView.heightAnchor.constraint(equalToConstant: collectionBackViewHeight),
    ])

    selectCollectionView.backgroundColor = .clear
    selectCollectionView.delegate = self
    selectCollectionView.dataSource = self
    selectCollectionView.allowsMultipleSelection = false
    selectCollectionView.translatesAutoresizingMaskIntoConstraints = false
    selectCollectionBackView.addSubview(selectCollectionView)
    NSLayoutConstraint.activate([
      selectCollectionView.centerYAnchor.constraint(equalTo: selectCollectionBackView.centerYAnchor),
      selectCollectionView.leftAnchor.constraint(equalTo: selectCollectionBackView.leftAnchor),
      selectCollectionView.rightAnchor.constraint(equalTo: selectCollectionBackView.rightAnchor),
      selectCollectionView.heightAnchor.constraint(equalToConstant: collectionBackViewHeight),
    ])
  }

  /// 设置选择确定按钮样式
  open func setupNavSureItem() {
    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      let rightItem = UIBarButtonItem(customView: selectedSureButton)
      navigationItem.rightBarButtonItem = rightItem
      selectedSureButton.addTarget(self, action: #selector(selectSureClick(_:)), for: .touchUpInside)
      selectedSureButton.setTitle(localizable("alert_sure"), for: .normal)
      selectedSureButton.setTitleColor(.white, for: .normal)
      selectedSureButton.layer.cornerRadius = 4
      selectedSureButton.contentHorizontalAlignment = .center
      selectedSureButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    } else {
      navigationView.setMoreButtonTitle(localizable("alert_sure"))
      navigationView.moreButton.setTitleColor(.white, for: .normal)
      navigationView.moreButton.layer.cornerRadius = 4
      navigationView.moreButton.contentHorizontalAlignment = .center
      navigationView.addMoreButtonTarget(target: self, selector: #selector(selectSureClick(_:)))
      selectedSureButton = navigationView.moreButton
      navigationView.backgroundColor = .white
    }
  }

  /// 确定按钮点击
  /// - Parameter sender: 确定按钮
  open func selectSureClick(_ sender: UIButton) {
    // 防止多次点击确定按钮会多次回调
    if isRequesting {
      return
    }

    if selectArray.count <= 0 {
      showToast(localizable("select_contact"))
      return
    }

    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(localizable("network_error"))
      return
    }

    isRequesting = true
    var accids = [String]()
    var names = [String]()
    let group = DispatchGroup()
    var mine: NEUserWithFriend?

    if let mineInfo = NEFriendUserCache.shared.getFriendInfo(IMKitClient.instance.account()) {
      mine = mineInfo
    } else {
      group.enter()
      ContactRepo.shared.getUserListFromCloud(accountIds: [IMKitClient.instance.account()]) { users, error in
        mine = users?.first
        group.leave()
      }
    }

    group.notify(queue: .main) { [weak self] in
      let myName = mine?.showName() ?? IMKitClient.instance.account()
      names.append(myName)
      var users = [V2NIMUser]()
      self?.selectArray.forEach { model in
        accids.append(model.getAccountId())

        let name = model.getShowName()
        let accountId = model.getAccountId()
        if names.count > 0 {
          names.append(name)
        } else if accountId.count > 0 {
          names.append(accountId)
        }
        if let user = model.user?.user {
          users.append(user)
        } else if let user = model.aiUser {
          users.append(user)
        }
      }

      if let uid = self?.userId {
        accids.append(uid)
      }

      let nameString = names.joined(separator: "、")
      print("name string : ", nameString)
      Router.shared.use(
        ContactSelectedUsersRouter,
        parameters: ["accids": accids, "names": nameString, "im_user": users],
        closure: nil
      )
      self?.navigationController?.popViewController(animated: true)
      self?.isRequesting = false
    }
  }

  /// 选择成员列表回调
  /// - Parameter user: 用户对象
  open func didSelectedUser(_ model: NEFusionContactCellModel) -> Bool {
    if selectArray.count >= limit {
      return false
    }
    selectArray.append(model)
    didChangeSelectUser()
    return true
  }

  /// 取消选择成员列表回调
  /// - Parameter user: 用户对象
  open func didUnselectedUser(_ model: NEFusionContactCellModel) {
    selectArray.removeAll { selectModel in
      let selectAccountId = selectModel.getAccountId()
      let rmAccountId = model.getAccountId()
      if selectAccountId.count > 0, rmAccountId == selectAccountId {
        return true
      }
      return false
    }
    didChangeSelectUser()
  }

  /// 选择用户变更统一处理
  open func didChangeSelectUser() {
    if selectArray.count > 0 {
      selectedSureButton.setTitle("\(localizable("alert_sure"))(\(selectArray.count))", for: .normal)
    } else {
      selectedSureButton.setTitle(localizable("alert_sure"), for: .normal)
    }
    if selectArray.count <= 0 {
      selectCollectionBackView.isHidden = true
      pagingViewControllerTopAnchor?.constant = topConstant
    } else {
      selectCollectionBackView.isHidden = false
      pagingViewControllerTopAnchor?.constant = topConstant + collectionBackViewHeight + collectionBackViewTopMargin * 2
    }
    selectCollectionView.reloadData()
  }

  /// 顶部反向取消选中
  open func didUnselect(_ model: NEFusionContactCellModel) {
    for controller in childrenControllers {
      controller.unselectModel(model)
    }
    didUnselectedUser(model)
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */

  // MARK: Collection View Delegate

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    selectArray.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    UICollectionViewCell()
  }

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let model = selectArray[indexPath.row]
    didUnselect(model)
  }

  open func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 46, height: collectionBackViewHeight)
  }
}
