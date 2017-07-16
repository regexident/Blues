//
//  AttributePermissions.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct AttributePermissions: OptionSet {

    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let readable: AttributePermissions = AttributePermissions(
        rawValue: CBAttributePermissions.readable.rawValue
    )

    public static let writeable: AttributePermissions = AttributePermissions(
        rawValue: CBAttributePermissions.writeable.rawValue
    )

    public static let readEncryptionRequired: AttributePermissions = AttributePermissions(
        rawValue: CBAttributePermissions.readEncryptionRequired.rawValue
    )

    public static let writeEncryptionRequired: AttributePermissions = AttributePermissions(
        rawValue: CBAttributePermissions.writeEncryptionRequired.rawValue
    )

    internal var core: CBAttributePermissions {
        return CBAttributePermissions(rawValue: self.rawValue)
    }
}
