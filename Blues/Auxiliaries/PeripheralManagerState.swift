// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// Represents the current state of a PeripheralManager.
///
/// - unknown: State unknown, update imminent.
/// - resetting: The connection with the system service was momentarily lost, update imminent.
/// - unsupported: The platform doesn't support the Bluetooth Low Energy Peripheral/Server role.
/// - unauthorized: The application is not authorized to use the Bluetooth Low Energy Peripheral/Server role.
/// - poweredOff: Bluetooth is currently powered off.
/// - poweredOn: Bluetooth is currently powered on and available to use.
public enum PeripheralManagerState {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn

    internal var core: CBManagerState {
        switch self {
        case .unknown: return .unknown
        case .resetting: return .resetting
        case .unsupported: return .unsupported
        case .unauthorized: return .unauthorized
        case .poweredOff: return .poweredOff
        case .poweredOn: return .poweredOn
        }
    }
}
