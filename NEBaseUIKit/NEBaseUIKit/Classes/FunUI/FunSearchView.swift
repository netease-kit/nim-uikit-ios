// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

@objcMembers
open class SearchSessionBaseView: UITableViewHeaderFooterView {
  override public init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(bottomLine)
  }

  open func setUpTitle(title: String) {
    titleLabel.text = title
  }

  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_emptyTitleColor
    label.font = .systemFont(ofSize: 14)
    label.textAlignment = .left
    return label
  }()

  public lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()
}

@objcMembers
open class FunSearchSessionHeaderView: SearchSessionBaseView {
  override open func setupUI() {
    super.setupUI()
    contentView.backgroundColor = .white
    NSLayoutConstraint.activate([
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
    ])

    NSLayoutConstraint.activate([
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}

public class FunSearchView: UIView {
  public lazy var backView: UIView = {
    let backView = UIView()
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.backgroundColor = .white
    backView.layer.cornerRadius = 4
    return backView
  }()

  public lazy var searchButton: UIButton = {
    let searchButton = UIButton()
    searchButton.translatesAutoresizingMaskIntoConstraints = false
    searchButton.setImage(coreLoader.loadImage("fun_search"), for: .normal)
    searchButton.setTitle(commonLocalizable("search"), for: .normal)
    searchButton.setTitleColor(.black, for: .normal)
    searchButton.titleLabel?.alpha = 0.3
    searchButton.layoutButtonImage(style: .left, space: 8)
    searchButton.isUserInteractionEnabled = false
    searchButton.accessibilityIdentifier = "id.titleBarSearchImg"
    return searchButton
  }()

  var searchButtonLeftConstant: CGFloat = 0
  var searchButtonRightConstant: CGFloat = 0

  public init(searchButtonLeftConstant: CGFloat = 0, searchButtonRightConstant: CGFloat = 0) {
    super.init(frame: .zero)
    self.searchButtonLeftConstant = searchButtonLeftConstant
    self.searchButtonRightConstant = searchButtonRightConstant
    setupSubViews()
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupSubViews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupSubViews() {
    addSubview(backView)
    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: leftAnchor),
      backView.rightAnchor.constraint(equalTo: rightAnchor),
      backView.topAnchor.constraint(equalTo: topAnchor),
      backView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    backView.addSubview(searchButton)
    NSLayoutConstraint.activate([
      searchButton.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
      searchButton.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: searchButtonLeftConstant),
      searchButton.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -searchButtonRightConstant),
    ])
  }

  /// 更新搜索按钮左右布局约束
  /// - Parameters:
  ///   - searchButtonLeftConstant: 左侧约束
  ///   - searchButtonRightConstant: 右侧约束
  open func updateSearchButtonConstant(searchButtonLeftConstant: CGFloat? = nil, searchButtonRightConstant: CGFloat? = nil) {
    if let leftConstant = searchButtonLeftConstant {
      backView.updateLayoutConstraint(firstItem: searchButton, secondItem: backView, attribute: .left, constant: leftConstant)
    }

    if let rightConstant = searchButtonRightConstant {
      backView.updateLayoutConstraint(firstItem: searchButton, secondItem: backView, attribute: .right, constant: rightConstant)
    }
  }
}
