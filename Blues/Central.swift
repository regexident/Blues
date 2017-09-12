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
        return self.generic.maximumUpdateValueLength
    }

    internal var generic: CoreCentralProtocol
    
    internal var core: CBCentral {
        guard let core = generic as? CBCentral else {
            fatalError()
        }
        
        return core
    }
    
    internal init(core: CoreCentralProtocol) {
        self.generic = core
    }
}
