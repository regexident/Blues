//
//  Extensions.swift
//  Blues
//
//  Created by Vincent Esche on 30/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

extension Data {
    var hexString: String? {
        return self.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) -> String? in
            let charA = UInt8(UnicodeScalar("a").value)
            let char0 = UInt8(UnicodeScalar("0").value)

            func itoh(value: UInt8) -> UInt8 {
                return (value > 9) ? (charA + value - 10) : (char0 + value)
            }

            var string = ""
            for i in 0 ..< self.count {
                if i > 0 {
                    string.append(" ")
                }
                string.append(Character(UnicodeScalar(itoh(value: (buffer[i] >> 4) & 0xF))))
                string.append(Character(UnicodeScalar(itoh(value: (buffer[i]) & 0xF))))
            }
            return string
        }
    }
}
