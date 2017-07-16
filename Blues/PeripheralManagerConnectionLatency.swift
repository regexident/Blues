//
//  PeripheralManagerConnectionLatency.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

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
