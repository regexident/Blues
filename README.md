# Blues

**Blues** is a type-safe object-oriented high-level wrapper around Core Bluetooth for iOS.

## Example Usage

Core Bluetooth does not provide any type-safety on its own, sending bare untyped `Data` packets over the "wire".

Blues in contrast allows one to effortlessly specify concrete types for peripherals, services, characteristics, descriptors as well as the actual values being sent over the BLE protocol.

So let's take a look at how one would implement a simple type-safe characteristic, such as the **Battery Level** characteristic of the **Battery** service as [specified in the Bluetooth Low Energy GATT specification](https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.service.battery_service.xml):

### Battery Level Value

The battery level characteristic is specified as returning integer values in the range of 0 to 100, inclusive, corresponding to chargedness in percent:

> The Battery Level characteristic is read using the GATT Read Characteristic Value sub-procedure and returns the current battery level as a percentage from `0%` to `100%`; `0%` represents a battery that is fully discharged, `100%` represents a battery that is fully charged.

A minimal `struct` implementation representing such a value could look something like this:

```swift
public struct BatteryLevel {
    public let percentage: UInt8

    public init(percentage: UInt8) {
        assert(percentage <= 100)
        self.percentage = percentage
    }
}

extension BatteryLevel: Equatable {
    public static func == (lhs: Battery.Level.Value, rhs: Battery.Level.Value) -> Bool {
        return lhs.percentage == rhs.percentage
    }
}

extension BatteryLevel: Comparable {
    public static func < (lhs: Battery.Level.Value, rhs: Battery.Level.Value) -> Bool {
        return lhs.percentage < rhs.percentage
    }
}

extension BatteryLevel: CustomStringConvertible {
    public var description: String {
        return "\(self.percentage)%"
    }
}
```

### Battery Level Value Transformer

Blues wraps Core Bluetooth, which by itself just sends and receives instances of `Data`.

We define a `CharacteristicValueTransformer` to allow Blues to come to its full potential when reading from a **Battery Level** characteristic:

```swift
import Blues

public struct BatteryLevelTransformer: CharacteristicValueTransformer {
    public typealias Value = Battery.Level.Value

    private static let codingError = "Expected value within 0 and 100 (inclusive)."

    public func transform(data: Data) -> Result<Value, TypedCharacteristicError> {
        let expectedLength = 1
        guard data.count == expectedLength else {
            return .err(.decodingFailed(message: "Expected data of \(expectedLength) bytes, found \(data.count)."))
        }
        return data.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) in
            let percentage = buffer[0]
            if percentage <= 100 {
                return .ok(Value(percentage: percentage))
            } else {
                return .err(.decodingFailed(message: Transformer.codingError))
            }
        }
    }

    public func transform(value: Value) -> Result<Data, TypedCharacteristicError> {
        return .err(.transformNotImplemented)
    }
}
```

Given that the GATT specification defines the **Battery Level** characteristic as being reado-only we don't fully implement `transform(value:)` and just return an error instead.

### Battery Level Characteristic:

Now that we have a type-safe `BatteryLevel` type and a matching value transformer it's about time to write the type-safe characteristic to make use of it:

```swift
import Blues

public class BatteryLevelCharacteristic: Blues.Characteristic,
    DelegatedCharacteristicProtocol,
    StringConvertibleCharacteristicProtocol,
    TypedCharacteristicProtocol,
    TypeIdentifiable
{
    public static let typeIdentifier = Identifier(string: "2A19")
    
    public typealias Transformer = BatteryLevelTransformer

    public let transformer: Transformer = .init()

    open override var name: String? {
        return "Battery-Level"
    }

    public weak var delegate: CharacteristicDelegate? = nil
}
```

By providing `weak public var delegate: CharacteristicDelegate?` and conforming to `DelegatedCharacteristicProtocol` the `BatteryLevelCharacteristic` will automagically forward all relevant method calls to its `delegate`.

### Battery Service

The `Battery Level` characteristic (i.e. `BatteryLevelCharacteristic`) is specified by GATT to be part of a `Battery` service (i.e. `BatteryService`):

```
import Blues

public class BatteryService: Blues.Service,
    DelegatedServiceProtocol,
    TypeIdentifiable
{
    public static let typeIdentifier = Identifier(string: "180F")

    weak public var delegate: ServiceDelegate?
    
    open var automaticallyDiscoveredCharacteristics: [Identifier]? {
        return [
            BatteryLevelCharacteristic.typeIdentifier
        ]
    }
}

extension BatteryService: ServiceDataSource {
    public func characteristic(with identifier: Identifier, for service: Service) -> Characteristic {
        switch identifier {
        case BatteryLevelCharacteristic.typeIdentifier:
            return BatteryLevelCharacteristic(identifier: identifier, service: service)
        default:
            return DefaultCharacteristic(identifier: identifier, service: service)
        }
    }
}
```

Just like we did for `BatteryLevelCharacteristic` we enable automagical call delegation for `BatteryService` by conforming to the corresponding `DelegatedServiceProtocol`.

We override `var automaticallyDiscoveredCharacteristics: [Identifier]?` to enable automatic discovery of the `BatteryLevelCharacteristic ` characteristic.

Implementing `characteristic(with:for:)` allows us to model a type-aware hierarchy of services and characteristics.

### Battery-aware Peripheral

Next we need to make our peripheral class be aware of the `BatteryService`, which we do by implementing `ServiceDataSource`:

```swift
open class BatteryAwarePeripheral: Blues.Peripheral,
    DelegatedPeripheralProtocol,
    DataSourcedPeripheralProtocol
{
    public weak var delegate: PeripheralDelegate?

    open var automaticallyDiscoveredServices: [Identifier]? {
        return [
            BatteryService.typeIdentifier
        ]
    }
}

extension BatteryAwarePeripheral: ServiceDataSource {
    public func service(with identifier: Identifier, for peripheral: Peripheral) -> Service {
        switch identifier {
        case BatteryService.typeIdentifier:
            return BatteryService(identifier: identifier, peripheral: peripheral)
        default:
            return DefaultService(identifier: identifier, peripheral: peripheral)
        }
    }
}
```

Similiar to what we did with `BatteryService` we're overriding `var automaticallyDiscoveredServices: [Identifier]?` to enable automatic discovery of the `BatteryService` service.

### Central Manager

Last but not least we need to provide a data source for our `CentralManager`

```
public class InsoleCentralManagerDataSource: CentralManagerDataSource {
    public func peripheral(
        with identifier: Identifier,
        advertisement: Advertisement?,
        for manager: CentralManager
    ) -> Peripheral {
        return BatteryAwarePeripheral(identifier: identifier, centralManager: manager)
    }
}
```

## Installation

The recommended way to add **Blues** to your project is via [Carthage](https://github.com/Carthage/Carthage):

    github 'regexident/Blues'

Or to add **Blues** to your project is via [CocoaPods](https://cocoapods.org):

    pod 'Blues'

## License

**Blues** is available under a **MPL-2 license**. See the `LICENSE` file for more info.
