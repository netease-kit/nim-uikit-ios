
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCore
import NEKitChatUI

public enum EditType:Int {
    case nickName = 0
    case cellphone
    case email
    case specialSign
}

class InputPersonInfoController: NEBaseViewController {

    
    typealias ResultCallBack = (String) -> Void
    public var contentText:String? {
        didSet {
            self.textField.text = contentText
        }
    }
    public var callBack:ResultCallBack?
    private var limitNumberCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        initialConfig()
    }
    
    func setupSubviews(){

        view.addSubview(textfieldBgView)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                textfieldBgView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
                textfieldBgView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
                textfieldBgView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
                textfieldBgView.heightAnchor.constraint(equalToConstant: 50)
            ])
        }else {
            NSLayoutConstraint.activate([
                textfieldBgView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
                textfieldBgView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
                textfieldBgView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
                textfieldBgView.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
       
        textfieldBgView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leftAnchor.constraint(equalTo: textfieldBgView.leftAnchor, constant: 16),
            textField.rightAnchor.constraint(equalTo: textfieldBgView.rightAnchor, constant: -12),
            textField.topAnchor.constraint(equalTo: textfieldBgView.topAnchor, constant: 0),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        
        
    }
    
    func initialConfig(){
        addRightAction("保存", #selector(saveName), self)
        view.backgroundColor = UIColor.init(hexString: "0xF1F1F6")
    }

    @objc func saveName(){
        weak var weakSelf = self
        if let block = callBack {
            block(textField.text ?? "")
            weakSelf?.navigationController?.popViewController(animated: true)
        }
    }

    func configTitle(editType:EditType) {
        switch editType {
        case .nickName:
            self.title = "昵称"
            limitNumberCount = 30
            break
        case .cellphone:
            self.title = "手机"
            limitNumberCount = 11
            break
        case .email:
            self.title = "邮箱"
            limitNumberCount = 30
            break
        case .specialSign:
            self.title = "个性签名"
            limitNumberCount = 50
            break
        }
    }
    
    
    
    //MARK: lazy Method
    
    lazy var textField: UITextField = {
        let text = UITextField()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.textColor = UIColor.init(hexString: "0x333333")
        text.font = UIFont.systemFont(ofSize: 14)
        text.delegate = self
        text.clearButtonMode = .always
        text.becomeFirstResponder()
        return text
    }()
    
    lazy var textfieldBgView:UIView = {
        let backView = UIView()
        backView.backgroundColor = .white
        backView.clipsToBounds = true
        backView.layer.cornerRadius = 8.0
        backView.translatesAutoresizingMaskIntoConstraints = false
        return backView
    }()

}

extension InputPersonInfoController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string), text.count > limitNumberCount {
            showToast("最多只能输入\(limitNumberCount)个字符哦")
            return false
        }
        return true
    }
}
