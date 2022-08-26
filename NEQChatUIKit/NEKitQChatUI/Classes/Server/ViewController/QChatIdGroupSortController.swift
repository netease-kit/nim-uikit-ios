
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCoreIM

// typealias SortCompletion = (_ array: NSMutableArray) -> Void

typealias SortChange = () -> Void

public class QChatIdGroupSortController: NEBaseTableViewController,UITableViewDelegate, UITableViewDataSource,ViewModelDelegate {
  var serverId: UInt64?

  var isOwer = false

  let viewmodel = IdGroupSortViewModel()

//    let dataArray = NSMutableArray()

  var didDelete = false

  var completion: SortChange?

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(back)
    )
    viewmodel.isOwner = isOwer
    viewmodel.delegate = self
    viewmodel.getData(serverId)
    setupUI()
  }

  func setupUI() {
    setupTable()
    title = localizable("qchat_id_group_sort")
    addRightAction(localizable("qchat_save"), #selector(saveSort), self)
    tableView.backgroundColor = .white
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(QChatSortCell.self, forCellReuseIdentifier: "\(QChatSortCell.self)")
    tableView.isEditing = true
    tableView.allowsSelectionDuringEditing = true
  }

  @objc func saveSort() {
    view.makeToastActivity(.center)
    weak var weakSelf = self
    viewmodel.saveSort(serverId) {
      weakSelf?.view.hideToastActivity()
      if let block = weakSelf?.completion {
        block()
      }
      print("save success")
      weakSelf?.navigationController?.popViewController(animated: true)
    }
  }

  @objc func back() {
    if didDelete == true, let block = completion {
      block()
    }
    navigationController?.popViewController(animated: true)
  }

    //MARK: UITableViewDelegate, UITableViewDataSource, ViewModelDelegate
    public func dataDidChange() {
      tableView.reloadData()
    }

    public func dataDidError(_ error: Error) {
      view.hideToastActivity()
      showToast(error.localizedDescription)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
      1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
  //        if section == 0 {
  //            return viewmodel.lockData.count
  //        }else if section == 1 {
  //            return viewmodel.datas.count
  //        }
      viewmodel.datas.count
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell: QChatSortCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatSortCell.self)",
        for: indexPath
      ) as! QChatSortCell
  //        if indexPath.section == 0 {
  //            let model = viewmodel.lockData[indexPath.row]
  //            cell.configure(model)
  //            cell.tailImage.isHighlighted = true
  //        }else if indexPath.section == 1 {
  //            if let model = viewmodel.datas[indexPath.row] as? IdGroupModel {
  //                cell.configure(model)
  //                cell.tailImage.isHighlighted = !model.hasPermission
  //            }
  //        }
      if let model = viewmodel.datas[indexPath.row] as? IdGroupModel {
        cell.configure(model)
        cell.tailImage.isHighlighted = !model.hasPermission
      }

      return cell
    }

    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
                          to destinationIndexPath: IndexPath) {
      print("source :", sourceIndexPath.row, " destionation :", destinationIndexPath.row)

      if sourceIndexPath.row > destinationIndexPath.row {
        let src_model = viewmodel.datas.object(at: sourceIndexPath.row)
        viewmodel.datas.remove(src_model)
        viewmodel.datas.insert(src_model, at: destinationIndexPath.row)
      } else {
        let src_model = viewmodel.datas.object(at: sourceIndexPath.row)
        viewmodel.datas.insert(src_model, at: destinationIndexPath.row + 1)
        viewmodel.datas.removeObject(at: sourceIndexPath.row)
      }

      viewmodel.datas.forEach { user in
        if let u = user as? IdGroupModel {
          print("change name : ", u.idName as Any)
          print("change p: ", u.role?.priority as Any)
        }
      }
    }

    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
      60
    }

    public func tableView(_ tableView: UITableView,
                          shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
      false
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if let model = viewmodel.datas[indexPath.row] as? IdGroupModel {
        weak var weakSelf = self
        if model.hasPermission == true {
          showAlert(message: "确定删除 \(model.idName ?? "当前身份组")?") {
            weakSelf?.view.makeToastActivity(.center)
            weakSelf?.viewmodel.removeRole(weakSelf?.serverId, model.role?.roleId, model) {
              weakSelf?.didDelete = true
              weakSelf?.view.hideToastActivity()
            }
          }
        }
      }
    }

    public func tableView(_ tableView: UITableView,
                          targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                          toProposedIndexPath proposedDestinationIndexPath: IndexPath)
      -> IndexPath {
      if isOwer == true {
        return proposedDestinationIndexPath
      } else {
        if let model = viewmodel.datas[proposedDestinationIndexPath.row] as? IdGroupModel {
          if model.hasPermission == true {
            return proposedDestinationIndexPath
          }
        }
      }
      return sourceIndexPath
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
      if let model = viewmodel.datas[indexPath.row] as? IdGroupModel {
        return model.hasPermission
      }
      return true
    }

    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
      if let model = viewmodel.datas[indexPath.row] as? IdGroupModel {
        return model.hasPermission
      }
      return true
    }

    public func tableView(_ tableView: UITableView,
                          editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
      UITableViewCell.EditingStyle.none
    }
}


