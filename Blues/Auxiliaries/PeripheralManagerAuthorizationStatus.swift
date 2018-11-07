// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// Represents the current state of a PeripheralManager.
public enum PeripheralManagerAuthorizationStatus {
    /// The user has not yet made a choice regarding whether this app
    /// can share data using Bluetooth services while in the background state.
    case notDetermined
    /// This app is not authorized to share data using Bluetooth services while in the background state.
    /// The user cannot change this app’s status, possibly due to active restrictions
    /// such as parental controls being in place.
    case restricted
    /// The user explicitly denied this app from sharing data using
    /// Bluetooth services while in the background state.
    case denied
    /// This app is authorized to share data using Bluetooth services while in the background state.
    case authorized
    
    init(from status: CBPeripheralManagerAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        case .denied: self = .denied
        case .authorized: self = .authorized
        }
    }
}
