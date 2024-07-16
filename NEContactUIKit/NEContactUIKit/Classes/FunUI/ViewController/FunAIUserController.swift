//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunAIUserController: NEBaseAIUserController {
  public var searchGrayBackViewTopAnchor: NSLayoutConstraint?

  let searchGrayBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.funContactBackgroundColor
    return view
  }()

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    searchGrayBackViewTopAnchor?.constant = topConstant
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funContactBackgroundColor
    aiUserTableView.register(FunAIUserListCell.self, forCellReuseIdentifier: "\(FunAIUserListCell.self)")
    view.insertSubview(searchGrayBackView, belowSubview: backView)
    searchGrayBackViewTopAnchor = searchGrayBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    searchGrayBackViewTopAnchor?.isActive = true
    NSLayoutConstraint.activate([
      searchGrayBackView.leftAnchor.constraint(equalTo: view.leftAnchor),
      searchGrayBackView.rightAnchor.constraint(equalTo: view.rightAnchor),
      searchGrayBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      searchGrayBackView.bottomAnchor.constraint(equalTo: aiUserTableView.topAnchor),
    ])
    backView.backgroundColor = UIColor.white
    searchAIUserTextField.backgroundColor = UIColor.white

    aiUserEmptyView.setEmptyImage(name: "fun_user_empty")
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(FunAIUserListCell.self)",
      for: indexPath
    ) as? FunAIUserListCell {
      if let model = getRealAIUserModel(indexPath.row) {
        cell.configure(model)

        if isLastAIUser(indexPath.row) {
          cell.dividerLine.isHidden = true
        } else {
          cell.dividerLine.isHidden = false
        }

        return cell
      }
    }
    return UITableViewCell()
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    64.0
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
