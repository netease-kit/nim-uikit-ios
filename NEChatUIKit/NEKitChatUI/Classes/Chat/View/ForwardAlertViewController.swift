
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCommon
import NEKitCommonUI

public class ForwardItem {
  var name: String?
  var uid: String?
  var avatar: String?
  public init() {}
}

public class ForwardUserCell: UICollectionViewCell {
  lazy var userHeader: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.titleLabel.font = NEConstant.defaultTextFont(11.0)
    header.clipsToBounds = true
    header.layer.cornerRadius = 16.0
    return header
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(userHeader)
    NSLayoutConstraint.activate([
      userHeader.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      userHeader.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      userHeader.widthAnchor.constraint(equalToConstant: 32.0),
      userHeader.heightAnchor.constraint(equalToConstant: 32.0),
    ])
  }
}

public class ForwardAlertViewController: UIViewController {
  var datas = [ForwardItem]()

  typealias ForwardCallBack = () -> Void
  var cancelBlock: ForwardCallBack?
  var sureBlock: ForwardCallBack?
  var context = ""

  lazy var userCollection: UICollectionView = {
    let flow = UICollectionViewFlowLayout()
    flow.scrollDirection = .horizontal
    flow.minimumLineSpacing = 9.5
    flow.minimumInteritemSpacing = 9.5
    let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.delegate = self
    collection.dataSource = self
    collection.backgroundColor = .clear
    collection.showsHorizontalScrollIndicator = false
    return collection
  }()

  lazy var contentView: UIView = {
    let back = UIView()
    back.backgroundColor = .white
    back.translatesAutoresizingMaskIntoConstraints = false
    back.clipsToBounds = true
    back.layer.cornerRadius = 8.0
    return back
  }()

  lazy var oneUserHead: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.clipsToBounds = true
    header.layer.cornerRadius = 16.0
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  lazy var oneUserName: UILabel = {
    let name = UILabel()
    name.textColor = .ne_darkText
    name.font = NEConstant.defaultTextFont(14.0)
    name.translatesAutoresizingMaskIntoConstraints = false
    return name
  }()

  lazy var contentText: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(14.0)
    label.textColor = .ne_darkText
    label.numberOfLines = 0
    return label
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    setupUI()
  }

  public func setupUI() {
    view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.4)
    view.addSubview(contentView)
    NSLayoutConstraint.activate([
      contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      contentView.widthAnchor.constraint(equalToConstant: 276),
    ])

    let tip = UILabel()
    tip.translatesAutoresizingMaskIntoConstraints = false
    tip.font = NEConstant.defaultTextFont(16.0)
    tip.textColor = .ne_darkText
    tip.text = localizable("send_to")
    contentView.addSubview(tip)
    NSLayoutConstraint.activate([
      tip.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      tip.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      tip.heightAnchor.constraint(equalToConstant: 18.0),
    ])

    contentView.addSubview(oneUserHead)
    NSLayoutConstraint.activate([
      oneUserHead.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      oneUserHead.topAnchor.constraint(equalTo: tip.bottomAnchor, constant: 16),
      oneUserHead.widthAnchor.constraint(equalToConstant: 32.0),
      oneUserHead.heightAnchor.constraint(equalToConstant: 32.0),
    ])

    contentView.addSubview(oneUserName)
    NSLayoutConstraint.activate([
      oneUserName.leftAnchor.constraint(equalTo: oneUserHead.rightAnchor, constant: 8.0),
      oneUserName.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
      oneUserName.centerYAnchor.constraint(equalTo: oneUserHead.centerYAnchor),
    ])

    contentView.addSubview(userCollection)
    NSLayoutConstraint.activate([
      userCollection.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      userCollection.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -16.0
      ),
      userCollection.heightAnchor.constraint(equalToConstant: 32.0),
      userCollection.topAnchor.constraint(equalTo: oneUserHead.topAnchor),
    ])

    let textBack = UIView()
    textBack.translatesAutoresizingMaskIntoConstraints = false
    textBack.backgroundColor = NEConstant.hexRGB(0xF2F4F5)
    textBack.clipsToBounds = true
    textBack.layer.cornerRadius = 4.0
    contentView.addSubview(textBack)
    NSLayoutConstraint.activate([
      textBack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
      textBack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
      textBack.topAnchor.constraint(equalTo: oneUserHead.bottomAnchor, constant: 12.0),
    ])

    textBack.addSubview(contentText)
    NSLayoutConstraint.activate([
      contentText.leftAnchor.constraint(equalTo: textBack.leftAnchor, constant: 12),
      contentText.rightAnchor.constraint(equalTo: textBack.rightAnchor, constant: -12),
      contentText.topAnchor.constraint(equalTo: textBack.topAnchor, constant: 7),
      contentText.bottomAnchor.constraint(equalTo: textBack.bottomAnchor, constant: -7),
    ])
    contentText.text = "[转发]\(context)的会话记录"

    let verticalLine = UIView()
    verticalLine.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(verticalLine)
    verticalLine.backgroundColor = NEConstant.hexRGB(0xE1E6E8)
    NSLayoutConstraint.activate([
      verticalLine.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      verticalLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      verticalLine.widthAnchor.constraint(equalToConstant: 1.0),
      verticalLine.heightAnchor.constraint(equalToConstant: 51),
      verticalLine.topAnchor.constraint(equalTo: textBack.bottomAnchor, constant: 16.0),
    ])

    let horizontalLine = UIView()
    horizontalLine.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(horizontalLine)
    horizontalLine.backgroundColor = NEConstant.hexRGB(0xE1E6E8)
    NSLayoutConstraint.activate([
      horizontalLine.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      horizontalLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      horizontalLine.heightAnchor.constraint(equalToConstant: 1),
      horizontalLine.bottomAnchor.constraint(equalTo: verticalLine.topAnchor),
    ])

    let canceBtn = UIButton()
    canceBtn.translatesAutoresizingMaskIntoConstraints = false
    canceBtn.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
    canceBtn.setTitle("取消", for: .normal)
    canceBtn.setTitleColor(.ne_greyText, for: .normal)

    let sureBtn = UIButton()
    sureBtn.translatesAutoresizingMaskIntoConstraints = false
    sureBtn.addTarget(self, action: #selector(sureClick), for: .touchUpInside)
    sureBtn.setTitle("确定", for: .normal)
    sureBtn.setTitleColor(.ne_blueText, for: .normal)

    contentView.addSubview(canceBtn)
    NSLayoutConstraint.activate([
      canceBtn.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      canceBtn.bottomAnchor.constraint(equalTo: verticalLine.bottomAnchor),
      canceBtn.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor),
      canceBtn.rightAnchor.constraint(equalTo: verticalLine.leftAnchor),
    ])

    contentView.addSubview(sureBtn)
    NSLayoutConstraint.activate([
      sureBtn.bottomAnchor.constraint(equalTo: verticalLine.bottomAnchor),
      sureBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      sureBtn.topAnchor.constraint(equalTo: horizontalLine.bottomAnchor),
      sureBtn.leftAnchor.constraint(equalTo: verticalLine.rightAnchor),
    ])

    userCollection.register(
      ForwardUserCell.self,
      forCellWithReuseIdentifier: "\(ForwardUserCell.self)"
    )
  }

  public func setItems(_ items: [ForwardItem]) {
    datas.append(contentsOf: items)
    if datas.count == 1 {
      let item = datas[0]
      if let name = item.name {
        oneUserHead.setTitle(name)
        oneUserName.text = name
      } else if let uid = item.uid {
        oneUserHead.setTitle(uid)
        oneUserName.text = uid
      }
      if let url = item.avatar {
        oneUserHead.sd_setImage(with: URL(string: url), completed: nil)
        oneUserHead.titleLabel.text = ""
      } else {
        oneUserHead.backgroundColor = UIColor.colorWithString(string: item.uid)
        oneUserHead.image = nil
      }
      userCollection.isHidden = true
    } else {
      oneUserHead.isHidden = true
      oneUserName.isHidden = true
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

  @objc func sureClick() {
    if let block = sureBlock {
      block()
    }
    removeSelf()
  }

  @objc func cancelClick() {
    if let block = cancelBlock {
      block()
    }
    removeSelf()
  }

  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    removeSelf()
  }

  func removeSelf() {
    view.removeFromSuperview()
    removeFromParent()
  }
}

extension ForwardAlertViewController: UICollectionViewDelegate, UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout {
  public func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
    datas.count
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "\(ForwardUserCell.self)",
      for: indexPath
    ) as? ForwardUserCell {
      let item = datas[indexPath.row]
      if let url = item.avatar {
        cell.userHeader.sd_setImage(with: URL(string: url), completed: nil)
        cell.userHeader.titleLabel.text = ""
      } else {
        cell.userHeader.backgroundColor = UIColor.colorWithString(string: item.uid)
        cell.userHeader.image = nil
        if let name = item.name {
          cell.userHeader.setTitle(name)
        } else if let uid = item.uid {
          cell.userHeader.setTitle(uid)
        }
      }
      return cell
    }
    return UICollectionViewCell()
  }

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
    CGSize(width: 32.0, height: 32)
  }
}
