// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

/// A descriptor of a peripheral’s characteristic,
/// providing further information about its value.
open class Descriptor: DescriptorProtocol {
    /// The Bluetooth-specific identifier of the descriptor.
    public let identifier: Identifier

    /// The descriptor's name.
    ///
    /// - Note:
    ///   Default implementation returns the identifier.
    ///   Override this property to provide a name for your custom type.
    open var name: String? {
        return nil
    }

    /// The characteristic that this descriptor belongs to.
    ///
    /// - Note:
    ///   This property is made `open` to allow for subclasses
    ///   to override getters to return a specialized characteristic:
    ///   ```
    ///   open var characteristic: CustomCharacteristic {
    ///       return super.characteristic as! CustomCharacteristic
    ///   }
    ///   ```
    open var characteristic: Characteristic {
        return self._characteristic
    }

    private unowned var _characteristic: Characteristic

    /// The service that this characteristic belongs to.
    ///
    /// - Note:
    ///   This property is made `open` to allow for subclasses
    ///   to override getters to return a specialized service:
    ///   ```
    ///   open var service: CustomService {
    ///       return super.service as! CustomService
    ///   }
    ///   ```
    open var service: ServiceProtocol {
        return self.characteristic.service
    }

    /// The peripheral that this descriptor belongs to.
    ///
    /// - Note:
    ///   This property is made `open` to allow for subclasses
    ///   to override getters to return a specialized peripheral:
    ///   ```
    ///   open var peripheral: CustomPeripheral {
    ///       return super.peripheral as! CustomPeripheral
    ///   }
    ///   ```
    open var peripheral: Peripheral {
        return self.service.peripheral
    }

    /// The value of the descriptor, or an error.
    public var any: Any? {
        return self.core.value
    }

    internal var core: CBDescriptor!

    public required init(identifier: Identifier, characteristic: Characteristic) {
        self.identifier = identifier
        self.core = nil
        self._characteristic = characteristic
    }

    /// Retrieves the value of the characteristic descriptor, or an error.
    ///
    /// - Note:
    ///   When you call this method to read the value of a characteristic
    ///   descriptor, the descriptor calls the `didUpdate(any:for:)`
    ///   method of its delegate object with the retrieved value, or an error.
    ///
    /// - Returns: `.ok(())` iff successfull, `.err(error)` otherwise.
    public func read() {
        assert(self.peripheral.state == .connected, self.apiMisuseErrorMessage())
        self.peripheral.readData(for: self)
    }

    /// Writes the value of a characteristic descriptor.
    ///
    /// - Note:
    ///   When you call this method to write the value of a characteristic
    ///   descriptor, the peripheral calls the `didWrite(any:for:)`
    ///   method of its delegate object. The data passed into the data
    ///   parameter is copied, and you can dispose of it after the method returns.
    ///
    /// - Important:
    ///   You cannot use this method to write the value of a client
    ///   configuration descriptor (represented by the
    ///   `CBUUIDClientCharacteristicConfigurationString` constant),
    ///   which describes how notification or indications are configured
    ///   for a characteristic’s value with respect to a client.
    ///   If you want to manage notifications or indications for a
    ///   characteristic’s value, you must use the `set(notifyValue:)`
    ///   method of `Characteristic` instead.
    ///
    /// Parameters:
    /// - data: The value to be written.
    ///
    /// - Returns: `.ok(())` iff successfull, `.err(error)` otherwise.
    public func write(data: Data) {
        assert(self.peripheral.state == .connected, self.apiMisuseErrorMessage())
        self.peripheral.write(data: data, for: self)
    }

    fileprivate func apiMisuseErrorMessage() -> String {
        return "\(type(of: self)) can only accept commands while in the connected state."
    }

    internal func delegated<T, U>(to type: T.Type, closure: (T) -> (U)) -> U? {
        if let delegate = self as? T {
            return closure(delegate)
        } else if let delegatedSelf = self as? DelegatedDescriptorProtocol {
            if let delegate = delegatedSelf.delegate as? T {
                return closure(delegate)
            }
        }
        return nil
    }
}

// MARK: - Equatable
extension Descriptor: Equatable {
    public static func == (lhs: Descriptor, rhs: Descriptor) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - Hashable
extension Descriptor: Hashable {
    public var hashValue: Int {
        return self.identifier.hashValue
    }
}

// MARK: - CustomStringConvertible
extension Descriptor: CustomStringConvertible {
    open var description: String {
        let className = type(of: self)
        let attributes = [
            "identifier = \(self.identifier)",
            "name = \(self.name ?? "<nil>")",
        ].joined(separator: ", ")
        return "<\(className) \(attributes)>"
    }
}

// MARK: - TypedDescriptorProtocol
extension TypedDescriptorProtocol {
    /// A type-safe value representation of the descriptor.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Descriptor.data`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    public var value: Result<Transformer.Value?, TypedDescriptorError> {
        guard let any = self.any else {
            return .ok(nil)
        }
        return self.transformer.transform(any: any).map { .some($0) }
    }

    /// Writes the value of a descriptor.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Descriptor.write(data:type:)`.
    ///   See its documentation for more information. All this wrapper basically does
    ///   is transforming `any` into an `Data` object by calling `self.transform(any: any)`
    ///   and then passing the result to `Descriptor.write(data:type:)`.
    ///
    /// - SeeAlso: `Descriptor.write(data:type:)`
    ///
    /// - Parameters:
    ///   - value: The value to be written.
    ///   - type: The type of write to be executed.
    ///
    /// - Returns: `.ok(())` iff successful, `.err(error)` otherwise.
    public func write(value: Transformer.Value, type: WriteType) -> Result<(), TypedDescriptorError> {
        return self.transformer.transform(value: value).flatMap { data in
            return .ok(self.write(data: data))
        }
    }

    public func transform(any: Result<Any, Error>) -> Result<Transformer.Value, TypedDescriptorError> {
        return any.mapErr { .other($0) }.flatMap { self.transformer.transform(any: $0) }
    }
}

extension TypedDescriptorProtocol
    where Self: StringConvertibleDescriptorProtocol,
          Self.Transformer.Value: CustomStringConvertible {
    public var stringValue: Result<String?, TypedDescriptorError> {
        return self.value.map { $0?.description }
    }
}
