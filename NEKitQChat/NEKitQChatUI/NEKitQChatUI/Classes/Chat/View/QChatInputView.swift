
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

protocol QChatInputViewDelegate: AnyObject {
    func sendText(text: String?)
    func willSelectItem(button: UIButton, index: Int)
}

class QChatInputView: UIView, UITextFieldDelegate {
    public weak var delegate: QChatInputViewDelegate?
    var textField = UITextField()
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonUI() {
    
        self.backgroundColor = UIColor(hexString: "#EFF1F3")
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .white
        textField.leftViewMode = .always
        textField.returnKeyType = .send
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 40))
        textField.delegate = self
        self.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 7),
            textField.topAnchor.constraint(equalTo:  self.topAnchor, constant: 6),
            textField.rightAnchor.constraint(equalTo:  self.rightAnchor, constant: -7),
            textField.heightAnchor.constraint(equalToConstant: 40)
        ])
        let imageNames = ["mic","emoji","photo","file","add"]
        var items = [UIButton]()
        for i in 0...4 {
            let button = UIButton(type: .custom)
            button.setImage(UIImage.ne_imageNamed(name: imageNames[i]), for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
            button.tag = i + 5
            items.append(button)
            if i != 2 {
                button.alpha = 0.5
            }
        }
        let stackView = UIStackView(arrangedSubviews: items)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        self.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: self.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: self.rightAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 54),
            stackView.topAnchor.constraint(equalTo: self.textField.bottomAnchor, constant: 0)
        ])
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces) else {
            return true
        }
        textField.text = ""
        self.delegate?.sendText(text: text)
        textField.resignFirstResponder()
        return true
    }
    
    @objc func buttonEvent(button: UIButton) {
        self.delegate?.willSelectItem(button: button, index: button.tag - 5)
    }

}
