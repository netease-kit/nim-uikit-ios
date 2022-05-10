
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

protocol QChatMemberInfoViewDelegate: AnyObject {
    func didClickUserHeader(_ accid: String?)
}

class QChatMemberInfoView: UIView {
    var contentView: UIView = UIView()
    public var avatar = UIImageView()
    public var shortName = UILabel()
    public var name = UILabel()
    public var groupView = UIView()

//    private var onlineView = UIView()
    private var originY: CGFloat = 0
    private var originMaxY: CGFloat = 0
    private var topConstaint: NSLayoutConstraint = NSLayoutConstraint()
//    var online:Bool {
//        get {
//            return onlineView.backgroundColor == .ne_greenColor
//        }
//        set {
//            onlineView.backgroundColor = newValue ? .ne_greenColor : .ne_greyText
//        }
//    }
    
    public var labelsWidth:CGFloat = 0
    public var maxWidth:CGFloat = kScreenWidth-2*kScreenInterval
    public var labelMargin:CGFloat = 6
    public var labelHeight:CGFloat = 25
    public var isFirstRow = true
    public weak var delegate: QChatMemberInfoViewDelegate?
    
    public var accid: String?
    
    init(inView: UIView) {
        super.init(frame: inView.bounds)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor(white: 0, alpha: 0.4)
        inView.addSubview(self)
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: inView.topAnchor),
            self.leftAnchor.constraint(equalTo: inView.leftAnchor),
            self.rightAnchor.constraint(equalTo: inView.rightAnchor),
            self.bottomAnchor.constraint(equalTo: inView.bottomAnchor),
        ])
        commonUI()
        addPanGesture()
        originMaxY = inView.frame.size.height - 360
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonUI() {
        self.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        topConstaint = contentView.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
//        topConstaint = contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 360)
        NSLayoutConstraint.activate([
            topConstaint,
            contentView.leftAnchor.constraint(equalTo: self.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: self.rightAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 360)
        ])
        
        let indicatorView = UIView()
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.backgroundColor = .white
        indicatorView.layer.cornerRadius = 4
        contentView.addSubview(indicatorView)
        NSLayoutConstraint.activate([
            indicatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            indicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: 41),
            indicatorView.heightAnchor.constraint(equalToConstant: 4)
        ])

        let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "bgImage"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: 5),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 70)
        ])
        let whiteBgView = UIView()
        whiteBgView.backgroundColor = .white
        whiteBgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(whiteBgView)
        NSLayoutConstraint.activate([
            whiteBgView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -5),
            whiteBgView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            whiteBgView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            whiteBgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.backgroundColor = .ne_defautAvatarColor
        avatar.layer.borderWidth = 2
        avatar.layer.borderColor = UIColor.white.cgColor
        avatar.layer.cornerRadius = 30
        avatar.clipsToBounds = true
        contentView.addSubview(avatar)
        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: 50),
            avatar.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            avatar.heightAnchor.constraint(equalToConstant: 60),
            avatar.widthAnchor.constraint(equalToConstant: 60)
        ])
        avatar.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        avatar.addGestureRecognizer(tap)
        tap.addTarget(self, action: #selector(headerClick))

//        onlineView.translatesAutoresizingMaskIntoConstraints = false
//        onlineView.backgroundColor = .ne_greenColor
//        onlineView.layer.borderWidth = 2
//        onlineView.layer.borderColor = UIColor.white.cgColor
//        onlineView.layer.cornerRadius = 7
//        onlineView.clipsToBounds = true
//        contentView.addSubview(onlineView)
//        NSLayoutConstraint.activate([
//            onlineView.centerXAnchor.constraint(equalTo: avatar.centerXAnchor, constant: 23),
//            onlineView.centerYAnchor.constraint(equalTo: avatar.centerYAnchor, constant: 23),
//            onlineView.heightAnchor.constraint(equalToConstant: 14),
//            onlineView.widthAnchor.constraint(equalToConstant: 14)
//        ])

        shortName.translatesAutoresizingMaskIntoConstraints = false
        shortName.font = .systemFont(ofSize: 22)
        shortName.textColor =  .white
        shortName.textAlignment = .center
        contentView.addSubview(shortName)
        NSLayoutConstraint.activate([
            shortName.topAnchor.constraint(equalTo: avatar.topAnchor),
            shortName.leftAnchor.constraint(equalTo: avatar.leftAnchor),
            shortName.rightAnchor.constraint(equalTo: avatar.rightAnchor),
            shortName.bottomAnchor.constraint(equalTo: avatar.bottomAnchor)
        ])

        name.translatesAutoresizingMaskIntoConstraints = false
        name.font = .boldSystemFont(ofSize: 24)
        name.textColor =  .ne_darkText
        contentView.addSubview(name)
        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: avatar.bottomAnchor,constant: 14),
            name.leftAnchor.constraint(equalTo: avatar.leftAnchor),
            name.rightAnchor.constraint(equalTo: contentView.rightAnchor,constant: -20),
            name.heightAnchor.constraint(equalToConstant: 30)
        ])

        let groupName = UILabel()
        groupName.translatesAutoresizingMaskIntoConstraints = false
        groupName.font = .systemFont(ofSize: 14)
        groupName.text = localizable("qchat_id_group")
        groupName.textColor =  .ne_darkText
        contentView.addSubview(groupName)
        NSLayoutConstraint.activate([
            groupName.topAnchor.constraint(equalTo: name.bottomAnchor,constant: 30),
            groupName.leftAnchor.constraint(equalTo: name.leftAnchor),
            groupName.rightAnchor.constraint(equalTo: contentView.rightAnchor,constant: -20),
            groupName.heightAnchor.constraint(equalToConstant: 20)
        ])

        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = .ne_greyLine
        contentView.addSubview(line)
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: groupName.bottomAnchor,constant: 8),
            line.leftAnchor.constraint(equalTo: name.leftAnchor),
            line.rightAnchor.constraint(equalTo: name.rightAnchor),
            line.heightAnchor.constraint(equalToConstant: 1)
        ])

        groupView.translatesAutoresizingMaskIntoConstraints = false
        groupView.backgroundColor = .white
        contentView.addSubview(groupView)
        NSLayoutConstraint.activate([
            groupView.topAnchor.constraint(equalTo: line.bottomAnchor,constant: 2),
            groupView.leftAnchor.constraint(equalTo: name.leftAnchor),
            groupView.rightAnchor.constraint(equalTo: name.rightAnchor),
            groupView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        
    }
    
    
    public func setupRoles(dataArray: [String]) {
        for i in (0 ..< dataArray.count) {
            let label = IDGroupLable(content: dataArray[i])
            label.textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            label.translatesAutoresizingMaskIntoConstraints = false
            groupView.addSubview(label)
            let labelSize = label.sizeThatFits(CGSize.init(width: maxWidth, height: labelHeight))
            
            //剩余宽度是否满足，下一个lable的宽度，如不满足则换行
            if (maxWidth-labelsWidth) >= labelSize.width && isFirstRow{
                NSLayoutConstraint.activate([
                    i == 0 ? label.leftAnchor.constraint(equalTo: groupView.leftAnchor,constant: kScreenInterval) : label.leftAnchor.constraint(equalTo: groupView.leftAnchor,constant: kScreenInterval+labelsWidth),
                    label.topAnchor.constraint(equalTo: groupView.topAnchor,constant: 8),
                    label.widthAnchor.constraint(equalToConstant: labelSize.width),
                    label.heightAnchor.constraint(equalToConstant:labelSize.height),
                ])
            }else {
                
                //换行重置，labels总宽度
                if isFirstRow {
                    labelsWidth = kScreenInterval
                }
                isFirstRow = false
                NSLayoutConstraint.activate([
                    label.leftAnchor.constraint(equalTo: groupView.leftAnchor,constant: labelsWidth),
                    label.topAnchor.constraint(equalTo: groupView.topAnchor,constant: 8+labelHeight+labelMargin),
                    label.widthAnchor.constraint(equalToConstant: labelSize.width),
                    label.heightAnchor.constraint(equalToConstant:labelSize.height)
                ])
            }
            
//            if i == dataArray.count - 1 {
//                NSLayoutConstraint.activate([
//                    label.bottomAnchor.constraint(equalTo: groupView.bottomAnchor)
//                ])
//            }
            labelsWidth+=(labelSize.width + labelMargin)
        }
    }
    
    func addPanGesture() {
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pan)))
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    }
    
    @objc func tap(pan:UIPanGestureRecognizer) {
        dismiss()
    }
    
    @objc func pan(pan:UIPanGestureRecognizer) {
        let position = pan.translation(in: self.superview)
        let velocity = pan.velocity(in: self.superview)
        print("velocity:\(velocity) position:\(position)")
        switch pan.state {
        case .began:
            print("start pan")
            originY = self.contentView.frame.origin.y
            
        case .changed:
            if (originY + position.y) > originMaxY  {
                self.contentView.frame.origin.y = originY + position.y
            }
            
        case .ended:
            print("ended pan")
            if velocity.y > 600 || self.contentView.frame.origin.y > originMaxY + 160 {
                dismiss()
            }
            
        default:
            print("default pan")
        }
    }
    
    func present() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.topConstaint.constant = -360
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            } completion: { result in

            }
        }
    }
    
    func dismiss() {
        if (self.superview == nil) {
            return
        }
        topConstaint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        } completion: { result in
            self.removeFromSuperview()
        }
    }
    
    public func setup(accid: String?, nickName: String?) {
        let name = nickName?.count ?? 0 > 0 ? nickName : accid
        self.name.text = name
        self.accid = accid
        guard let n = name else { return }
        self.shortName.text = n.count > 2 ? String(n[n.index(n.endIndex, offsetBy: -2)...]) : n
        self.avatar.backgroundColor = UIColor.colorWithString(string: accid)
    }
    
    @objc func headerClick(){
        delegate?.didClickUserHeader(accid)
        self.removeFromSuperview()
    }
}
