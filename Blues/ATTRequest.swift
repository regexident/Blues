//
//  ATTRequest.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

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

    internal var core: CBATTRequest

    init(core: CBATTRequest) {
        self.core = core
    }
}
