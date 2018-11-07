// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// The latency of a peripheral-central connection controls how frequently messages can be exchanged.
///
/// - low: Prioritizes rapid communication over battery life.
/// - medium: A balance between communication frequency and battery life.
/// - high: Prioritizes extending battery life over rapid communication.
public enum PeripheralManagerConnectionLatency {
    case low
    case medium
    case high

    internal var core: CBPeripheralManagerConnectionLatency {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }
}
