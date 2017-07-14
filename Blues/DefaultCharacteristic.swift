//
//  DefaultCharacteristic.swift
//  Blues
//
//  Created by Vincent Esche on 10.05.17.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation

import Result

/// Default implementation of `Characteristic` protocol.
open class DefaultCharacteristic:
    Characteristic, DelegatedCharacteristicProtocol, DataSourcedCharacteristicProtocol {
    public weak var delegate: CharacteristicDelegate?
    public weak var dataSource: CharacteristicDataSource?
}

// MARK: - CharacteristicDataSource
extension DefaultCharacteristic: CharacteristicDataSource {
    public func descriptor(
        with identifier: Identifier,
        for characteristic: Characteristic
    ) -> Descriptor {
        if let dataSource = self.dataSource {
            return dataSource.descriptor(with: identifier, for: characteristic)
        } else {
            return DefaultDescriptor(identifier: identifier, characteristic: characteristic)
        }
    }
}

// MARK: - CharacteristicReadingDelegate
extension DefaultCharacteristic: CharacteristicReadingDelegate {
    public func didUpdate(
        data: Result<Data, Error>,
        for characteristic: Characteristic
    ) {
        guard let delegate = self.delegate as? CharacteristicReadingDelegate else {
            return
        }
        delegate.didUpdate(data: data, for: characteristic)
    }
}

// MARK: - CharacteristicWritingDelegate
extension DefaultCharacteristic: CharacteristicWritingDelegate {
    public func didWrite(
        data: Result<Data, Error>,
        for characteristic: Characteristic
    ) {
        guard let delegate = self.delegate as? CharacteristicWritingDelegate else {
            return
        }
        delegate.didWrite(data: data, for: characteristic)
    }
}

// MARK: - CharacteristicNotificationStateDelegate
extension DefaultCharacteristic: CharacteristicNotificationStateDelegate {
    public func didUpdate(
        notificationState isNotifying: Result<Bool, Error>,
        for characteristic: Characteristic
    ) {
        guard let delegate = self.delegate as? CharacteristicNotificationStateDelegate else {
            return
        }
        delegate.didUpdate(notificationState: isNotifying, for: characteristic)
    }
}

// MARK: - CharacteristicDiscoveryDelegate
extension DefaultCharacteristic: CharacteristicDiscoveryDelegate {
    public func didDiscover(
        descriptors: Result<[Descriptor], Error>,
        for characteristic: Characteristic
    ) {
        guard let delegate = self.delegate as? CharacteristicDiscoveryDelegate else {
            return
        }
        delegate.didDiscover(descriptors: descriptors, for: characteristic)
    }
}
