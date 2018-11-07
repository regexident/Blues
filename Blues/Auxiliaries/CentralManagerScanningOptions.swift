// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

public struct CentralManagerScanningOptions {
    /// A Boolean value that specifies whether the scan
    /// should run without duplicate filtering.
    ///
    /// - Note:
    ///   If `true`, filtering is disabled and a discovery event is generated each
    ///   time the central receives an advertising packet from the peripheral.
    ///   Disabling this filtering can have an adverse effect on battery life and
    ///   should be used only if necessary.
    ///
    ///   If `false`, multiple discoveries of the same peripheral are coalesced
    ///   into a single discovery event.
    ///
    ///   The default value is `false`.
    public var allowDuplicates: Bool = false
    
    /// An array of service identifiers that you want to scan for.
    ///
    /// - Note:
    ///   Specifying this scan option causes the central manager to also scan for
    ///   peripherals soliciting any of the services contained in the array.
    public var solicitedServiceIdentifiers: [Identifier]?
    
    private enum Keys {
        static let allowDuplicates = CBCentralManagerScanOptionAllowDuplicatesKey
        static let solicitedServiceIdentifiers = CBCentralManagerScanOptionSolicitedServiceUUIDsKey
    }
    
    public init() {
        
    }
    
    internal init?(dictionary: [String: Any]) {
        let allowDuplicatesKey = Keys.allowDuplicates
        if let value = dictionary[allowDuplicatesKey] {
            guard let allowDuplicates = value as? Bool else {
                Log.shared.error("Unexpected value: \"\(value)\" for key \(allowDuplicatesKey)")
                return nil
            }
            self.allowDuplicates = allowDuplicates
        } else {
            self.allowDuplicates = false
        }
        
        let solicitedServicesKey = Keys.solicitedServiceIdentifiers
        if let value = dictionary[solicitedServicesKey] {
            guard let solicitedServiceIdentifiers = value as? [CBUUID] else {
                Log.shared.error("Unexpected value: \"\(value)\" for key \(solicitedServicesKey)")
                return nil
            }
            self.solicitedServiceIdentifiers = solicitedServiceIdentifiers.map {
                Identifier(uuid: $0)
            }
        } else {
            self.solicitedServiceIdentifiers = nil
        }
    }
    
    internal var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary[Keys.allowDuplicates] = self.allowDuplicates
        if let solicitedServiceIdentifiers = self.solicitedServiceIdentifiers {
            let identifiers = solicitedServiceIdentifiers.map { $0.core }
            dictionary[Keys.solicitedServiceIdentifiers] = identifiers
        }
        return dictionary
    }
}

extension CentralManagerScanningOptions: Equatable {
    public static func ==(lhs: CentralManagerScanningOptions, rhs: CentralManagerScanningOptions) -> Bool {
        
        if lhs.allowDuplicates != rhs.allowDuplicates {
            return false
        }
        
        switch (lhs.solicitedServiceIdentifiers, rhs.solicitedServiceIdentifiers) {
        case let (r?, l?):
            return r == l
        case (.none, .none):
            return true
        case _: return false
        }
    }
}
