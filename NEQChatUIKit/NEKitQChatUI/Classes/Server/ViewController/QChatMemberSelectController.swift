
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import MJRefresh

typealias SelectMemeberCompletion = ([UserInfo]) -> Void
typealias FilterMembersBlock = ([UserInfo]) -> [UserInfo]?

public protocol QChatMemberSelectControllerDelegate: AnyObject {
  func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void)
}

// enum SelectType {
//    case ServerMember
//    case ChannelMember
// }

public class QChatMemberSelectController: NEBaseTableViewController, MemberSelectViewModelDelegate,UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,UITableViewDelegate,UITableViewDataSource,ViewModelDelegate {
  let viewmodel = MemberSelectViewModel()
  var filterBlock: FilterMembersBlock?
  var completion: SelectMemeberCompletion?

//    var selectType =  SelectType.ServerMember

  var serverId: UInt64?

  var limit = 10

  public weak var delegate: QChatMemberSelectControllerDelegate?

  lazy var collection: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let collect = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    collect.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    return collect
  }()

  var collectionHeight: NSLayoutConstraint?

  var selectArray = [UserInfo]()

  override public func viewDidLoad() {
    super.viewDidLoad()
    viewmodel.delegate = self
    loadData()
    setupUI()
  }

  func setupUI() {
    edgesForExtendedLayout = []
    addRightAction(localizable("qchat_sure"), #selector(sureClick), self)
    title = localizable("qchat_select")
    view.addSubview(collection)
    collection.delegate = self
    collection.dataSource = self
    collection.allowsMultipleSelection = false
    collection.translatesAutoresizingMaskIntoConstraints = false
    collectionHeight = collection.heightAnchor.constraint(equalToConstant: 0)
    collectionHeight?.isActive = true
    collection.backgroundColor = UIColor(hexString: "F2F4F5")
    NSLayoutConstraint.activate([
      collection.topAnchor.constraint(equalTo: view.topAnchor),
      collection.leftAnchor.constraint(equalTo: view.leftAnchor),
      collection.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    collection.register(
      QChatUserUnCheckCell.self,
      forCellWithReuseIdentifier: "\(NSStringFromClass(QChatUserUnCheckCell.self))"
    )

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      tableView.topAnchor.constraint(equalTo: collection.bottomAnchor),
    ])
    if #available(iOS 13.0, *) {
      tableView.automaticallyAdjustsScrollIndicatorInsets = false
    } else {
      // Fallback on earlier versions
    }
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatSelectedCell.self,
      forCellReuseIdentifier: "\(QChatSelectedCell.self)"
    )

    if #available(iOS 11.0,*) {
      tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior
        .never
    } else {
      automaticallyAdjustsScrollViewInsets = false
    }
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
//        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(loadData))
  }

  @objc func sureClick() {
    if selectArray.count <= 0 {
      view.makeToast(localizable("qchat_not_empty_select_memeber"))
      return
    }
    if let block = completion {
      block(selectArray)
    }
    navigationController?.popViewController(animated: true)
  }

  @objc func loadData() {
    viewmodel.loadFirst(serverId: serverId) { [weak self] error, users in
      if error != nil {
        self?.view.makeToast(error?.localizedDescription)
      } else {
        self?.tableView.reloadData()
        self?.tableView.mj_footer?.resetNoMoreData()
        self?.tableView.mj_header?.endRefreshing()
      }
    }
  }

  @objc func loadMoreData() {
    viewmodel.loadMore(serverId: serverId) { [weak self] error, users in
      if error != nil {
        self?.view.makeToast(error?.localizedDescription)
      } else {
        if users?.count ?? 0 > 0 {
          self?.tableView.reloadData()
          self?.tableView.mj_footer?.endRefreshing()
        } else {
          self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        }
      }
    }
  }
    //MARK:
    public func dataDidError(_ error: Error) {
      view.makeToast(error.localizedDescription)
    }

    public func dataDidChange() {
      tableView.reloadData()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
      selectArray.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let user = selectArray[indexPath.row]
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "\(NSStringFromClass(QChatUserUnCheckCell.self))",
        for: indexPath
      ) as? QChatUserUnCheckCell
      cell?.configure(user)
      return cell ?? UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
      let user = selectArray[indexPath.row]
      didUnselectContact(user)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
      CGSize(width: 46, height: 52)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      viewmodel.datas.count
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell: QChatSelectedCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatSelectedCell.self)",
        for: indexPath
      ) as! QChatSelectedCell
      let user = viewmodel.datas[indexPath.row]
      cell.user = user
      return cell
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      62
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let user = viewmodel.datas[indexPath.row]
      let cell = tableView.cellForRow(at: indexPath) as? QChatSelectedCell

      if user.select == true {
        cell?.setUnselect()
        didUnselectContact(user)
      } else {
        if selectArray.count >= limit {
          // view.makeToast("超出\(limit)人限制")
          showToast(
            "\(localizable("exceed"))\(limit)\(localizable("person"))\(localizable("limit"))"
          )
          return
        }
        cell?.setSelect()
        didSelectContact(user)
      }
  //        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func didSelectContact(_ user: UserInfo) {
      user.select = true
      if selectArray.contains(where: { c in
        user === c
      }) == false {
        selectArray.append(user)
        if let height = collectionHeight?.constant, height <= 0 {
          collectionHeight?.constant = 52
        }
      }
      collection.reloadData()
      tableView.reloadData()
      refreshSelectCount()
    }

    func didUnselectContact(_ user: UserInfo) {
      user.select = false
      selectArray.removeAll { c in
        user === c
      }
      if selectArray.count <= 0 {
        collection.reloadData()
        collectionHeight?.constant = 0
      }
      collection.reloadData()
      tableView.reloadData()
      refreshSelectCount()
    }

    func refreshSelectCount() {
      if selectArray.count > 0 {
        rightNavBtn.setTitle("\(localizable("qchat_sure"))(\(selectArray.count))", for: .normal)
      } else {
        rightNavBtn.setTitle(localizable("qchat_sure"), for: .normal)
      }
    }

    public func tableView(_ tableView: UITableView,
                          heightForHeaderInSection section: Int) -> CGFloat {
      0
    }

  //    MARK: MemberSelectViewModelDelegate

    func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void) {
  //        查询需要筛选的用户
      delegate?.filterMembers(accid: accid, filterMembers)
    }
}


