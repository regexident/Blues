// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
