//
//  PeripheralHandling.swift
//  Blues
//
//  Created by Vincent Esche on 29/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

struct DiscoverServicesMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let uuids: [Identifier]?

    func sendToHandler(_ handler: Handler) -> Output {
        let uuids = self.uuids?.map { $0.core }
        return handler.discover(services: uuids)
    }
}

struct DiscoverIncludedServicesMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let uuids: [Identifier]?
    let service: Service

    func sendToHandler(_ handler: Handler) -> Output {
        let uuids = self.uuids?.map { $0.core }
        return self.service.core.andThen {
            handler.discover(includedServices: uuids, for: $0)
        }
    }
}

struct DiscoverCharacteristicsMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let uuids: [Identifier]?
    let service: Service

    func sendToHandler(_ handler: Handler) -> Output {
        let uuids = self.uuids?.map { $0.core }
        return self.service.core.andThen {
            handler.discover(characteristics: uuids, for: $0)
        }
    }
}

struct DiscoverDescriptorsMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let characteristic: Characteristic

    func sendToHandler(_ handler: Handler) -> Output {
        return self.characteristic.core.andThen {
            handler.discoverDescriptors(for: $0)
        }
    }
}

struct ReadValueForCharacteristicMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let characteristic: Characteristic

    func sendToHandler(_ handler: Handler) -> Output {
        return self.characteristic.core.andThen {
            handler.readData(for: $0)
        }
    }
}

struct ReadValueForDescriptorMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let descriptor: Descriptor

    func sendToHandler(_ handler: Handler) -> Output {
        return self.descriptor.core.andThen {
            handler.readData(for: $0)
        }
    }
}

struct WriteValueForCharacteristicMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let data: Data
    let characteristic: Characteristic
    let type: WriteType

    func sendToHandler(_ handler: Handler) -> Output {
        return self.characteristic.core.andThen {
            handler.write(data: self.data, for: $0, type: self.type)
        }
    }
}

struct WriteValueForDescriptorMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let data: Data
    let descriptor: Descriptor

    func sendToHandler(_ handler: Handler) -> Output {
        return self.descriptor.core.andThen {
            handler.write(data: self.data, for: $0)
        }
    }
}

struct SetNotifyValueForCharacteristicMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    let notifyValue: Bool
    let characteristic: Characteristic

    func sendToHandler(_ handler: Handler) -> Output {
        return self.characteristic.core.andThen {
            handler.set(notifyValue: self.notifyValue, for: $0)
        }
    }
}

struct ReadRSSIMessage: Message {
    typealias Handler = PeripheralHandling
    typealias Output = Result<(), PeripheralError>

    func sendToHandler(_ handler: Handler) -> Output {
        return handler.readRSSI()
    }
}

protocol PeripheralHandling {
    func discover(services: [CBUUID]?) -> Result<(), PeripheralError>
    func discover(includedServices: [CBUUID]?, for service: CBService)
        -> Result<(), PeripheralError>
    func discover(characteristics: [CBUUID]?, for service: CBService) -> Result<(), PeripheralError>
    func discoverDescriptors(for characteristic: CBCharacteristic) -> Result<(), PeripheralError>

    func readData(for characteristic: CBCharacteristic) -> Result<(), PeripheralError>
    func readData(for descriptor: CBDescriptor) -> Result<(), PeripheralError>

    func write(data: Data, for characteristic: CBCharacteristic, type: WriteType)
        -> Result<(), PeripheralError>
    func write(data: Data, for descriptor: CBDescriptor) -> Result<(), PeripheralError>

    func set(notifyValue: Bool, for characteristic: CBCharacteristic) -> Result<(), PeripheralError>

    func readRSSI() -> Result<(), PeripheralError>
}
