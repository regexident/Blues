// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

open class DefaultPeripheralManager:
    PeripheralManager, DelegatedPeripheralManagerProtocol
{
    public weak var delegate: PeripheralManagerDelegate?
    
    public init(
        delegate: PeripheralManagerDelegate? = nil,
        queue: DispatchQueue = .global(),
        options: [String : Any]? = nil
    ) {
        self.delegate = delegate
        super.init(queue: queue, options: options)
    }
    
    internal override init(core: CBPeripheralManagerProtocol) {
        super.init(core: core)
    }
}
