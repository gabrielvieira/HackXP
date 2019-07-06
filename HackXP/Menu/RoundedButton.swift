//
//  RoundedButton.swift
//  HackXP
//
//  Created by Gabriel vieira on 7/6/19.
//  Copyright © 2019 Gabriel vieira. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.config()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.config()
    }
    
    private func config() {
//        self.backgroundColor = Color.red
        self.layer.cornerRadius = 25
        self.layer.borderColor = UIColor.white.cgColor
//        self.setTitleColor(Color.white, for: .normal)
    }
    
    func enableButton(enable: Bool) {
        
        if enable {
//            self.backgroundColor = Color.red
            self.isUserInteractionEnabled = true
        } else {
//            self.backgroundColor = Color.inactiveRed
            self.isUserInteractionEnabled = false
        }
    }
}
