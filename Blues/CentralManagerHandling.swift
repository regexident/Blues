//
//  CentralManagerHandling.swift
//  Blues
//
//  Created by Vincent Esche on 29/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

struct ConnectPeripheralMessage: Message {
    typealias Handler = CentralManagerHandling
    typealias Output = Result<(), PeripheralError>

    let peripheral: Peripheral
    let options: ConnectionOptions?

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.connect(peripheral: self.peripheral, options: self.options)
    }
}

struct DisconnectPeripheralMessage: Message {
    typealias Handler = CentralManagerHandling
    typealias Output = Result<(), PeripheralError>

    let peripheral: Peripheral

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.disconnect(peripheral: self.peripheral)
    }
}

protocol CentralManagerHandling {
    func connect(peripheral: Peripheral, options: ConnectionOptions?) -> Result<(), PeripheralError>
    func disconnect(peripheral: Peripheral) -> Result<(), PeripheralError>
}
