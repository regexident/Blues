// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// Represents a remote central.
public class Central {
    /// The Bluetooth-specific identifier of the central.
    public let identifier: Identifier
    
    /// The maximum amount of data, in bytes, that can be received by the central in a
    /// single notification or indication.
    public var maximumUpdateValueLength: Int {
        return self.core.maximumUpdateValueLength
    }

    internal var core: CBCentralProtocol
    
    internal var concrete: CBCentral {
        guard let core = self.core as? CBCentral else {
            fatalError()
        }
        
        return core
    }
    
    internal init(core: CBCentralProtocol) {
        self.identifier = Identifier(uuid: core.identifier)
        self.core = core
    }
}
