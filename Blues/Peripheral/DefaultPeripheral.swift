// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Default implementation of `Peripheral` protocol.
open class DefaultPeripheral: Peripheral {
    public weak var delegate: PeripheralDelegate?
    public weak var dataSource: PeripheralDataSource?
}

extension DefaultPeripheral: DelegatedPeripheralProtocol {}
extension DefaultPeripheral: DataSourcedPeripheralProtocol {}
