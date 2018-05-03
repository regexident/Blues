//
//  Central.swift
//  Blues
//
//  Created by Vincent Esche on 7/16/17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Represents a remote central.
public class Central {
    /// The maximum amount of data, in bytes, that can be received by the central in a
    /// single notification or indication.
    public var maximumUpdateValueLength: Int {
        return self.core.maximumUpdateValueLength
    }

    internal var core: CoreCentralProtocol
    
    internal var concrete: CBCentral {
        guard let core = core as? CBCentral else {
            fatalError()
        }
        
        return core
    }
    
    internal init(core: CoreCentralProtocol) {
        self.core = core
    }
}