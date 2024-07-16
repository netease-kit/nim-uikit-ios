//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import UIKit

@objc public enum FusionContactType: NSInteger {
  case FusionContactTypeUser
  case FusionContactTypeAIUser
}

@objc public protocol FusionContactSelectedDelegate: NSObjectProtocol {
  /// 选择成员列表回调
  /// - Parameter model: 成员model
  @objc func didSelectedUser(_ model: NEFusionContactCellModel) -> Bool
  /// 取消选择成员列表回调
  /// - Parameter model: 成员model
  @objc func didUnselectedUser(_ model: NEFusionContactCellModel)
}

@objcMembers
open class NEBaseFusionContactSelectedController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  /// 数据管理
  let viewModel = FusionContactSelectedViewModel()

  /// cell 注册表
  public var fusionRegisterCellDic = [0: NEBaseFusionContactSelectedCell.self]

  /// 选择器代理
  public weak var delegate: FusionContactSelectedDelegate?

  /// 选择人数限制
  var limit = 10
  ///  当前类型
  var fusionType: FusionContactType?
  /// 过滤存在用户
  var filterSet: Set<String>?

  public init(filterIds: Set<String>? = nil, type: FusionContactType) {
    super.init(nibName: nil, bundle: nil)
    fusionType = type
    filterSet = filterIds
    if fusionType == .FusionContactTypeUser {
      title = localizable("contact_friend")
    } else if fusionType == .FusionContactTypeAIUser {
      title = localizable("contact_ai_user")
    }
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 选择器成员列表
  public lazy var fusionContactTableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.backgroundColor = .clear
    tableView.delegate = self
    tableView.dataSource = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .onDrag

    if #available(iOS 11.0, *) {
      tableView.estimatedRowHeight = 0
      tableView.estimatedSectionHeaderHeight = 0
      tableView.estimatedSectionFooterHeight = 0
    }
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  /// 空占位图
  public lazy var fusionEmptyView: NEEmptyDataView = {
    let emptyView = NEEmptyDataView(
      imageName: "user_empty",
      content: "",
      frame: CGRect.zero
    )
    emptyView.setText(localizable("no_friend"))
    emptyView.translatesAutoresizingMaskIntoConstraints = false
    emptyView.isUserInteractionEnabled = false
    emptyView.isHidden = true
    return emptyView
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    setupFusionContactSelectedUI()
  }

  /// UI 初始化
  open func setupFusionContactSelectedUI() {
    view.addSubview(fusionContactTableView)
    NSLayoutConstraint.activate([
      fusionContactTableView.topAnchor.constraint(equalTo: view.topAnchor),
      fusionContactTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      fusionContactTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      fusionContactTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    for (key, value) in fusionRegisterCellDic {
      fusionContactTableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    view.addSubview(fusionEmptyView)
    NSLayoutConstraint.activate([
      fusionEmptyView.topAnchor.constraint(equalTo: fusionContactTableView.topAnchor),
      fusionEmptyView.bottomAnchor.constraint(equalTo: fusionContactTableView.bottomAnchor),
      fusionEmptyView.leftAnchor.constraint(equalTo: fusionContactTableView.leftAnchor),
      fusionEmptyView.rightAnchor.constraint(equalTo: fusionContactTableView.rightAnchor),
    ])

    weak var weakSelf = self
    if fusionType == .FusionContactTypeUser {
      viewModel.loadMemberDatas(filterSet) { error in
        if let err = error {
          weakSelf?.view.makeToast(err.localizedDescription)
        } else {
          weakSelf?.fusionContactTableView.reloadData()
          if weakSelf?.viewModel.memberDatas.count ?? 0 <= 0 {
            weakSelf?.fusionEmptyView.isHidden = false
          }
        }
      }
    } else if fusionType == .FusionContactTypeAIUser {
      fusionEmptyView.setText(localizable("no_ai_user"))
      viewModel.loadAIUserData(filterSet)
      fusionContactTableView.reloadData()
      if viewModel.memberDatas.count <= 0 {
        fusionEmptyView.isHidden = false
      }
    }

    view.backgroundColor = .white
  }

  open func setupFusionContactUI() {}

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.memberDatas.count
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellModel = viewModel.memberDatas[indexPath.row]
    if let cell = tableView.dequeueReusableCell(withIdentifier: "\(cellModel.type)", for: indexPath) as? NEBaseFusionContactSelectedCell {
      cell.configFusionModel(cellModel)
      return cell
    }
    return UITableViewCell()
  }

  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    56
  }

  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cellModel = viewModel.memberDatas[indexPath.row]
    if cellModel.selected == false {
      if delegate?.didSelectedUser(cellModel) == true {
        cellModel.selected = !cellModel.selected
        if let cell = tableView.cellForRow(at: indexPath) as? NEBaseFusionContactSelectedCell {
          cell.configFusionModel(cellModel)
        }
      } else {
        view.makeToast(String(format: localizable("exceeded_limit"), limit))
      }
    } else {
      delegate?.didUnselectedUser(cellModel)
      cellModel.selected = !cellModel.selected
      if let cell = tableView.cellForRow(at: indexPath) as? NEBaseFusionContactSelectedCell {
        cell.configFusionModel(cellModel)
      }
    }
  }

  func getCellModelUser(_ cellModel: NEFusionContactCellModel) -> V2NIMUser? {
    if fusionType == .FusionContactTypeUser {
      return cellModel.user?.user
    } else if fusionType == .FusionContactTypeAIUser {
      return cellModel.aiUser
    }
    return nil
  }

  /// 外部触发反选操作
  /// - Parameter model: 数据模型
  public func unselectModel(_ model: NEFusionContactCellModel) {
    for memberModel in viewModel.memberDatas {
      if memberModel.getAccountId() == model.getAccountId() {
        memberModel.selected = false
        fusionContactTableView.reloadData()
      }
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */
}
