
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

public class BirthdayDatePickerView: UIView {

    private var selectTime:String?
    public typealias SelectTimeCallBack = (String?) -> Void
    public var timeCallBack:SelectTimeCallBack?
    
    lazy var sureBtn:UIButton = {
        let button = UIButton.init(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("确认", for: .normal)
        button.setTitleColor(UIColor.ne_blueText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.addTarget(self, action: #selector(sureBtnClick), for: .touchUpInside)
        return button
    }()
    
    lazy var picker:UIDatePicker = {
        let datePicker = UIDatePicker(frame: CGRect.zero)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        //将日期选择器区域设置为中文，则选择器日期显示为中文
        datePicker.locale = Locale(identifier: "zh_CN")
        datePicker.datePickerMode = .date
        //注意：action里面的方法名后面需要加个冒号“：”
        datePicker.addTarget(self, action: #selector(dateChanged),
                             for: .valueChanged)
        
        return datePicker
    }()
    
    lazy var cancelBtn:UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor.ne_blueText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)

        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews(){
        //创建日期选择器
        self.addSubview(cancelBtn)
        self.addSubview(sureBtn)
        self.addSubview(bottomLine)
        self.addSubview(picker)

        NSLayoutConstraint.activate([
            cancelBtn.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 15),
            cancelBtn.topAnchor.constraint(equalTo: self.topAnchor,constant: 8),
            cancelBtn.widthAnchor.constraint(equalToConstant: 45)
        ])
        
        
        NSLayoutConstraint.activate([
            sureBtn.rightAnchor.constraint(equalTo: self.rightAnchor,constant: -15),
            sureBtn.topAnchor.constraint(equalTo: self.topAnchor,constant: 8),
            sureBtn.widthAnchor.constraint(equalToConstant: 45)
        ])
        
        
        NSLayoutConstraint.activate([
            bottomLine.leftAnchor.constraint(equalTo: self.leftAnchor),
            bottomLine.rightAnchor.constraint(equalTo: self.rightAnchor),
            bottomLine.topAnchor.constraint(equalTo: cancelBtn.bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        
        NSLayoutConstraint.activate([
            picker.leftAnchor.constraint(equalTo: self.leftAnchor),
            picker.rightAnchor.constraint(equalTo: self.rightAnchor),
            picker.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            picker.topAnchor.constraint(equalTo: bottomLine.bottomAnchor)
        ])

    }
    
    
    @objc func dateChanged(datePicker : UIDatePicker){
        //更新提醒时间文本框
        let formatter = DateFormatter()
        //日期样式
        formatter.dateFormat = "yyyy-MM-dd"
        let time = formatter.string(from: datePicker.date)
        selectTime = time
    }
    


    @objc func sureBtnClick(sender:UIButton) {
        self.removeFromSuperview()
        weak var weakSelf = self
        if let time = selectTime {
            if let block = timeCallBack {
                block(time)
            }
        }else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            selectTime = formatter.string(from: picker.date)
            if let block = timeCallBack {
                block(weakSelf?.selectTime)
            }
        }
    }
    
    @objc func cancelBtnClick(sender:UIButton) {
        self.removeFromSuperview()
    }
    
    private lazy var bottomLine:UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.init(hexString: "0xDBE0E8")
        return view
    }()
    
}
