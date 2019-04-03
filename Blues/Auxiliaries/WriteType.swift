// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

// A enum representation of a Bluetooth Low Energy write type.
public enum WriteType {
    /// A characteristic value is to be written, with a response from
    /// the peripheral to indicate whether the write was successful.
    case withResponse
    /// A characteristic value is to be written, without any response from
    /// the peripheral to indicate whether the write was successful.
    case withoutResponse

    var inner: CBCharacteristicWriteType {
        switch self {
        case .withResponse: return .withResponse
        case .withoutResponse: return .withoutResponse
        }
    }

    init(writeType: CBCharacteristicWriteType) {
        switch writeType {
        case .withResponse: self = .withResponse
        case .withoutResponse: self = .withoutResponse
        case _:
            print("Encountered unknown write-type: \(writeType), falling back to `.withResponse`.")
            self = .withResponse
        }
    }
}

// MARK: - CustomStringConvertible
extension WriteType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .withResponse: return ".withResponse"
        case .withoutResponse: return ".withoutResponse"
        }
    }
}
