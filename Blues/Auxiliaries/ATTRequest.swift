// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// Represents a read or write request from a central.
public class ATTRequest {
    //    /// The central that originated the request.
    //    open var central: Central
    //
    //    /// The characteristic whose value will be read or written.
    //    open var characteristic: Characteristic
    //
    //    /// The zero-based index of the first byte for the read or write.
    //    open var offset: Int
    //
    //    /// The data being read or written. For read requests, _value_ will be nil and should be set
    //    /// before responding via `respondToRequest:withResult:`. For write requests, _value_ will
    //    /// contain the data to be written.
    //    open var value: Data?

    internal var core: CoreATTRequestProtocol

    init(core: CoreATTRequestProtocol) {
        self.core = core
    }
}
