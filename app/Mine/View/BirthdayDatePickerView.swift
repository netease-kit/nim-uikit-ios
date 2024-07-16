
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

public class BirthdayDatePickerView: UIView {
  private var selectTime: String?
  public typealias SelectTimeCallBack = (String?) -> Void
  public var timeCallBack: SelectTimeCallBack?

  lazy var cancelButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(NSLocalizedString("cancel", comment: ""), for: .normal)
    button.setTitleColor(UIColor.ne_blueText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.addTarget(self, action: #selector(removeFromSuperview), for: .touchUpInside)
    return button
  }()

  lazy var sureButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(commonLocalizable("ok"), for: .normal)
    button.setTitleColor(UIColor.ne_blueText, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.addTarget(self, action: #selector(sureBtnClick), for: .touchUpInside)
    return button
  }()

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()

  lazy var picker: UIDatePicker = {
    let datePicker = UIDatePicker(frame: CGRect.zero)
    datePicker.translatesAutoresizingMaskIntoConstraints = false
    // 将日期选择器区域设置为中文，则选择器日期显示为中文
    datePicker.locale = Locale(identifier: "zh_CN")
    datePicker.datePickerMode = .date
    datePicker.maximumDate = Date()
    if #available(iOS 13.4, *) {
      datePicker.preferredDatePickerStyle = .wheels
    }

    // 注意：action里面的方法名后面需要加个冒号“：”
    datePicker.addTarget(self, action: #selector(dateChanged),
                         for: .valueChanged)

    return datePicker
  }()

  /// 日期选择器背景视图
  public lazy var pickerBackView: UIView = {
    let pickerBackView = UIView()
    pickerBackView.translatesAutoresizingMaskIntoConstraints = false
    pickerBackView.backgroundColor = .white
    return pickerBackView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor(white: 0, alpha: 0.25)
    let tap = UITapGestureRecognizer(target: self, action: #selector(pickerBackViewClicked))
    addGestureRecognizer(tap)
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// UI 初始化
  func setupSubviews() {
    addSubview(pickerBackView)

    NSLayoutConstraint.activate([
      pickerBackView.leftAnchor.constraint(equalTo: leftAnchor),
      pickerBackView.rightAnchor.constraint(equalTo: rightAnchor),
      pickerBackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      pickerBackView.heightAnchor.constraint(equalToConstant: 229),
    ])

    pickerBackView.addSubview(cancelButton)
    pickerBackView.addSubview(sureButton)
    pickerBackView.addSubview(bottomLine)
    pickerBackView.addSubview(picker)

    NSLayoutConstraint.activate([
      cancelButton.leftAnchor.constraint(equalTo: pickerBackView.leftAnchor, constant: 15),
      cancelButton.topAnchor.constraint(equalTo: pickerBackView.topAnchor, constant: 8),
      cancelButton.widthAnchor.constraint(equalToConstant: 45),
      cancelButton.heightAnchor.constraint(equalToConstant: 20),
    ])

    NSLayoutConstraint.activate([
      sureButton.rightAnchor.constraint(equalTo: pickerBackView.rightAnchor, constant: -15),
      sureButton.topAnchor.constraint(equalTo: pickerBackView.topAnchor, constant: 8),
      sureButton.widthAnchor.constraint(equalToConstant: 45),
      sureButton.heightAnchor.constraint(equalToConstant: 20),
    ])

    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: pickerBackView.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: pickerBackView.rightAnchor),
      bottomLine.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 8),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    NSLayoutConstraint.activate([
      picker.leftAnchor.constraint(equalTo: pickerBackView.leftAnchor),
      picker.rightAnchor.constraint(equalTo: pickerBackView.rightAnchor),
      picker.bottomAnchor.constraint(equalTo: pickerBackView.bottomAnchor),
      picker.topAnchor.constraint(equalTo: bottomLine.bottomAnchor),
    ])
  }

  @objc func pickerBackViewClicked() {
    removeFromSuperview()
  }

  @objc func dateChanged(datePicker: UIDatePicker) {
    // 更新提醒时间文本框
    let formatter = DateFormatter()
    // 日期样式
    formatter.dateFormat = "yyyy-MM-dd"
    let time = formatter.string(from: datePicker.date)
    selectTime = time
  }

  @objc func sureBtnClick(sender: UIButton) {
    removeFromSuperview()
    weak var weakSelf = self
    if let time = selectTime {
      if let block = timeCallBack {
        block(time)
      }
    } else {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      selectTime = formatter.string(from: picker.date)
      if let block = timeCallBack {
        block(weakSelf?.selectTime)
      }
    }
  }
}
