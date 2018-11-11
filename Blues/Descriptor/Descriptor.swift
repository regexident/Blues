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
    open var name: String?

    /// The characteristic that this descriptor belongs to.
    public var characteristic: CharacteristicProtocol {
        guard let characteristic = self._characteristic else {
            fatalError("Expected `Characteristic`, found `nil` in `self.characteristic`.")
        }
        return characteristic
    }

    private weak var _characteristic: CharacteristicProtocol?

    /// The service that this characteristic belongs to.
    public var service: ServiceProtocol {
        return self.characteristic.service
    }

    /// The peripheral that this descriptor belongs to.
    public var peripheral: PeripheralProtocol {
        return self.service.peripheral
    }
    
    internal var core: CBDescriptor!

    public init(identifier: Identifier, characteristic: Characteristic) {
        self.identifier = identifier
        self.core = nil
        self._characteristic = characteristic
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
    public var description: String {
        let className = type(of: self)
        let attributes = [
            "identifier = \(self.identifier)",
            "name = \(self.name ?? "<nil>")",
        ].joined(separator: ", ")
        return "<\(className) \(attributes)>"
    }
}

extension ReadableDescriptorProtocol
where
    Self: Descriptor
{
    /// The value of the descriptor, or an error.
    public var any: Any? {
        return self.core.value
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
        guard let peripheral = self.peripheral as? Peripheral else {
            let typeName = String(describing: type(of: self.peripheral))
            fatalError("Expected `Peripheral`, found `\(typeName)`")
        }
        peripheral.readData(for: self)
    }
}

extension WritableDescriptorProtocol
where
    Self: Descriptor
{
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
        guard let peripheral = self.peripheral as? Peripheral else {
            let typeName = String(describing: type(of: self.peripheral))
            fatalError("Expected `Peripheral`, found `\(typeName)`")
        }
        peripheral.write(data: data, for: self)
    }
}

//public protocol DecodableDescriptorProtocol: DescriptorProtocol {
//    associatedtype Decoder: ValueDecoder where Decoder.Input == Any
//
//    var decoder: Decoder { get }
//}
//
//public protocol EncodableDescriptorProtocol: DescriptorProtocol {
//    associatedtype Encoder: ValueEncoder where Encoder.Output == Data
//
//    var encoder: Encoder { get }
//}

extension TypedReadableDescriptorProtocol
where
    Self: Descriptor & ReadableDescriptorProtocol
{
    /// A type-safe value representation of the descriptor.
    ///
    /// - Note:
    ///   This is a thin type-safe wrapper around `Descriptor.data`.
    ///   See its documentation for more information. All this wrapper basically
    ///   does is transforming `self.data` into an `Value` object by calling
    ///   `self.transform(data: self.data)` and then returning the result.
    public var value: Result<Decoder.Value?, DecodingError> {
        guard let any = self.any else {
            return .ok(nil)
        }
        return self.decoder.decode(any).map { .some($0) }
    }
}

extension TypedWritableDescriptorProtocol
where
    Self: Descriptor & WritableDescriptorProtocol
{
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
    public func write(value: Encoder.Value) -> Result<(), EncodingError> {
        return self.encoder.encode(value).flatMap { data in
            return .ok(self.write(data: data))
        }
    }
}

extension StringConvertibleDescriptorProtocol
where
    Self: Descriptor & ReadableDescriptorProtocol
{
    public var stringValue: Result<String?, DecodingError> {
        guard let any = self.any else {
            return .ok("")
        }
        return .ok("\(any)")
    }
}

extension StringConvertibleDescriptorProtocol
    where
    Self: Descriptor & TypedReadableDescriptorProtocol
{
    public var stringValue: Result<String?, DecodingError> {
        return self.value.map { value in
            guard let value = value else {
                return ""
            }
            return "\(value)"
        }
    }
}
