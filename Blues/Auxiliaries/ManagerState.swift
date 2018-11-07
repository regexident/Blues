// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// Abstraction layer around `CBManagerState`.
@available(iOS 10.0, *)
@available(iOSApplicationExtension 10.0, *)
public enum ManagerState {
    /// The current state of the manager is unknown; an update is imminent.
    case unknown
    /// The connection with the system service was momentarily lost; an update is imminent.
    case resetting
    /// The platform does not support Bluetooth low energy.
    case unsupported
    /// The app is not authorized to use Bluetooth low energy.
    case unauthorized
    /// Bluetooth is currently powered off.
    case poweredOff
    /// Bluetooth is currently powered on and available to use.
    case poweredOn

    init(from state: CBManagerState) {
        switch state {
        case .unknown: self = .unknown
        case .resetting: self = .resetting
        case .unsupported: self = .unsupported
        case .unauthorized: self = .unauthorized
        case .poweredOff: self = .poweredOff
        case .poweredOn: self = .poweredOn
        }
    }
}
