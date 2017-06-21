//
//  PeripheralHandling.swift
//  Blues
//
//  Created by Vincent Esche on 29/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

import Result

struct DiscoverServicesMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let uuids: [Identifier]?

    func sendToHandler(_ handler: Handler) -> Output {
        let uuids = self.uuids?.map { $0.core }
        return handler.discover(services: uuids)
    }
}

struct DiscoverIncludedServicesMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let uuids: [Identifier]?
    let service: Service

    func sendToHandler(_ handler: Handler) -> Output {
        let uuids = self.uuids?.map { $0.core }
        return handler.discover(includedServices: uuids, for: self.service.core)
    }
}

struct DiscoverCharacteristicsMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let uuids: [Identifier]?
    let service: Service

    func sendToHandler(_ handler: Handler) -> Output {
        let uuids = self.uuids?.map { $0.core }
        return handler.discover(characteristics: uuids, for: self.service.core)
    }
}

struct DiscoverDescriptorsMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let characteristic: Characteristic

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.discoverDescriptors(for: self.characteristic.core)
    }
}

struct ReadValueForCharacteristicMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let characteristic: Characteristic

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.readData(for: self.characteristic.core)
    }
}

struct ReadValueForDescriptorMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let descriptor: Descriptor

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.readData(for: self.descriptor.core)
    }
}

struct WriteValueForCharacteristicMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let data: Data
    let characteristic: Characteristic
    let type: WriteType

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.write(data: self.data, for: self.characteristic.core, type: self.type)
    }
}

struct WriteValueForDescriptorMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let data: Data
    let descriptor: Descriptor

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.write(data: self.data, for: self.descriptor.core)
    }
}

struct SetNotifyValueForCharacteristicMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    let notifyValue: Bool
    let characteristic: Characteristic

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.set(notifyValue: self.notifyValue, for: self.characteristic.core)
    }
}

struct ReadRSSIMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = ()

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.readRSSI()
    }
}

protocol PeripheralHandling {
    func discover(services: [CBUUID]?)
    func discover(includedServices: [CBUUID]?, for service: CBService)
    func discover(characteristics: [CBUUID]?, for service: CBService)
    func discoverDescriptors(for characteristic: CBCharacteristic)

    func readData(for characteristic: CBCharacteristic)
    func readData(for descriptor: CBDescriptor)

    func write(data: Data, for characteristic: CBCharacteristic, type: WriteType)
    func write(data: Data, for descriptor: CBDescriptor)

    func set(notifyValue: Bool, for characteristic: CBCharacteristic)

    func readRSSI()
}
