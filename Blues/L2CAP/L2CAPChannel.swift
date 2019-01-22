//
//  L2CAPChannel.swift
//  Blues
//
//  Created by Vincent Esche on 1/22/19.
//  Copyright © 2019 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

@available(iOS 8.0, *)
public protocol PeerProtocol {
    var identifier: Identifier { get }
}

extension Peripheral: PeerProtocol {}
extension Central: PeerProtocol {}

@available(iOS 11.0, watchOS 4.0, macOS 10.13, tvOS 11.0, *)
public class L2CAPChannel {
    private let core: CBL2CAPChannel
    
    /// The peer connected to the channel
    public let peer: PeerProtocol

    /// An `InputStream` used for reading data from the remote peer
    public var inputStream: InputStream! {
        return self.core.inputStream
    }

    /// An `OutputStream` used for writing data to the peer
    public var outputStream: OutputStream! {
        return self.core.outputStream
    }

    /// The PSM (Protocol/Service Multiplexer) of the channel
    public var psm: L2CAPPSM {
        return L2CAPPSM(core: self.core.psm)
    }
    
    internal init(core: CBL2CAPChannel, peer: PeerProtocol) {
        self.peer = peer
        self.core = core
    }
}
