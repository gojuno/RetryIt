//
//  UI+Utils.swift
//  RetryIt
//
//  Created by Sergey Dikovitsky on 4/4/19.
//  Copyright © 2019 SergeyDik. All rights reserved.
//

import UIKit

extension UIColor {

    static let error = UIColor(hex: 0xf62459)
    static let primary = UIColor(hex: 0x5856d6)

    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((hex & 0x00FF00) >> 8) / 0xFF
        let blue = CGFloat((hex & 0x0000FF) >> 0) / 0xFF
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
