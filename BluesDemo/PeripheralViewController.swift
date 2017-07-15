//
//  PeripheralViewController.swift
//  BluesDemo
//
//  Created by Vincent Esche on 28/10/2016.
//  Copyright © 2016 NWTN Berlin. All rights reserved.
//

import UIKit
import Blues

import Result

protocol PeripheralViewControllerDelegate: class {
    func connect(peripheral: Peripheral)
    func disconnect(peripheral: Peripheral)
}

class PeripheralViewController: UITableViewController {

    var characteristicViewController: CharacteristicViewController?

    var peripheral: DefaultPeripheral? {
        willSet {
            self.peripheral?.delegate = nil
        }
        didSet {
            if let peripheral = self.peripheral {
                peripheral.delegate = self
                if let services = peripheral.services {
                    for service in services {
                        self.characteristicsByService[service] = service.characteristics ?? []
                    }
                }
                self.navigationItem.rightBarButtonItem = self.barButtonItem
            } else {
                self.navigationItem.rightBarButtonItem = nil
            }
            self.tableView.reloadData()
        }
    }

    weak var delegate: PeripheralViewControllerDelegate?

    @IBOutlet var barButtonItem: UIBarButtonItem!

    fileprivate let queue: DispatchQueue = .init(label: "serial")

    var services: [Service] {
         return Array(self.characteristicsByService.keys)
    }

    var characteristicsByService: [Service: [Characteristic]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true

        guard let peripheral = self.peripheral else {
            return
        }

        self.title = self.title(for: peripheral)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()

        guard let peripheral = self.peripheral else {
            self.navigationItem.rightBarButtonItem = nil
            return
        }

        peripheral.delegate = self

        self.navigationItem.rightBarButtonItem = self.barButtonItem
        if peripheral.state == .connected {
            self.barButtonItem?.title = "Disconnect"
        } else {
            self.barButtonItem?.title = "Connect"
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard let peripheral = self.peripheral else {
            return
        }
        peripheral.delegate = nil
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)

        // Caution: Due to http://www.openradar.me/18002763 this methods is actually never called.
        // Look into Main.storyboard for more info.

        // The back button was pressed or interactive gesture used:
        if parent == nil {
            // do something
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCharacteristic" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            let service = self.services[indexPath.section]
            let characteristics = self.characteristicsByService[service]!
            let characteristic = characteristics[indexPath.row]

            let controller = segue.destination as! CharacteristicViewController
            controller.characteristic = characteristic
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            self.characteristicViewController = controller
        }
    }

    @IBAction fileprivate func toggleConnection(_ sender: UIBarButtonItem) {
        guard let delegate = self.delegate else {
            fatalError("Expected 'self.delegate', found nil.")
        }

        guard let peripheral = self.peripheral else {
            return
        }
        if peripheral.state == .connected {
            delegate.disconnect(peripheral: peripheral)
        } else {
            delegate.connect(peripheral: peripheral)
        }
    }

    fileprivate func title(for peripheral: Peripheral) -> String {
        return peripheral.name ?? "UUID: \(peripheral.identifier.string)"
    }

    fileprivate func title(for characteristic: Characteristic) -> String {
        return characteristic.name ?? "UUID: \(characteristic.identifier.string)"
    }

    fileprivate func humanReadableValue<C>(for characteristic: C) -> String
        where C: Characteristic
    {
        guard let data = characteristic.data else {
            return "No data"
        }
        if let hexString = data.hexString {
            return "Hex: \(hexString)"
        } else {
            return "No Value"
        }
    }

    fileprivate func humanReadableValue<C>(for characteristic: C) -> String
        where C: Characteristic,
              C: TypedCharacteristic,
              C.Transformer.Value: CustomStringConvertible
    {
        return characteristic.value.map { value in
            value!.description
        }.asOk.unwrapOr("No value")
    }
}

extension PeripheralViewController {
    func willConnect() {
        DispatchQueue.main.async {
            if let buttonItem = self.navigationItem.rightBarButtonItem {
                buttonItem.isEnabled = false
                buttonItem.title = "Connecting…"
            }
        }
    }

    func didConnect() {
        guard let peripheral = self.peripheral else {
            return
        }

        if peripheral.services == nil {
            peripheral.discover(services: nil)
        }

        DispatchQueue.main.async {
            if let buttonItem = self.navigationItem.rightBarButtonItem {
                buttonItem.isEnabled = true
                buttonItem.title = "Disconnect"
            }
        }
    }

    func willDisconnect() {
        DispatchQueue.main.async {
            if let buttonItem = self.navigationItem.rightBarButtonItem {
                buttonItem.isEnabled = false
                buttonItem.title = "Disconnecting…"
            }
        }
    }

    func didDisconnect(error: Swift.Error?) {
        DispatchQueue.main.async {
            if let buttonItem = self.navigationItem.rightBarButtonItem {
                buttonItem.isEnabled = true
                buttonItem.title = "Connect"
            }
        }
    }

    func didFailToConnect(to peripheral: Peripheral, error: Swift.Error?) {
        
    }
}

// MARK: - UITableViewDataSource
extension PeripheralViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
//        print("\n")
//        print("self.sortedServices.count:", self.sortedServices.count)
        return self.characteristicsByService.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let service = self.services[section]
//        print("service:", service)
        return ServiceNames.nameOf(service: service.identifier) ?? service.name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let service = self.services[section]
        let characteristics = self.characteristicsByService[service]!
//        print("characteristics:", characteristics)
        return characteristics.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CharacteristicCell", for: indexPath)

        let service = self.services[indexPath.section]
        let characteristics = self.characteristicsByService[service]!
        let characteristic = characteristics[indexPath.row]
//        print("characteristic:", characteristic)

        cell.textLabel!.text = self.humanReadableValue(for: characteristic)
        cell.detailTextLabel!.text = self.title(for: characteristic)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension PeripheralViewController{
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let peripheral = self.peripheral else {
            return false
        }
        return peripheral.state == .connected
    }
}

// MARK: - PeripheralDelegate
extension PeripheralViewController: PeripheralStateDelegate {
    func didUpdate(name: String?, of peripheral: Peripheral) {
        self.title = self.title(for: peripheral)
    }

    func didModify(services: [Service], of peripheral: Peripheral) {

    }

    func didRead(rssi: Result<Int, Error>, of peripheral: Peripheral) {

    }
}

extension PeripheralViewController: PeripheralDiscoveryDelegate {
    func didDiscover(services: Result<[Service], Error>, for peripheral: Peripheral) {
        guard case let .ok(services) = services else {
            return
        }
        self.queue.async {
            for service in services {
                self.characteristicsByService[service] = service.characteristics ?? []
                if let service = service as? DefaultService {
                    service.delegate = self
                }
                service.discover(characteristics: nil)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - ServiceDelegate
extension PeripheralViewController: ServiceDiscoveryDelegate {
    func didDiscover(includedServices: Result<[Service], Error>, for service: Service) {

    }

    func didDiscover(characteristics: Result<[Characteristic], Error>, for service: Service) {
        guard case let .ok(characteristics) = characteristics else {
            return
        }
        self.queue.async {
            self.characteristicsByService[service] = service.characteristics ?? []
            for characteristic in characteristics {
                if let characteristic = characteristic as? DefaultCharacteristic {
                    characteristic.delegate = self
                }
                characteristic.discoverDescriptors()
                characteristic.read()
                characteristic.set(notifyValue: true)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - CharacteristicReadingDelegate
extension PeripheralViewController: CharacteristicReadingDelegate {
    func didUpdate(data: Result<Data, Error>, for characteristic: Characteristic) {
        let service = characteristic.service
        self.queue.async {
            let services = self.services
            let characteristics = self.characteristicsByService[service]!

            let section = services.index(of: characteristic.service)!
            let row = characteristics.index(of: characteristic)!
            let indexPath = IndexPath(row: row, section: section)
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}

// MARK: - CharacteristicWritingDelegate
extension PeripheralViewController: CharacteristicWritingDelegate {
    func didWrite(data: Result<Data, Error>, for characteristic: Characteristic) {
        let service = characteristic.service
        self.queue.async {
            let services = self.services
            let characteristics = self.characteristicsByService[service]!

            let section = services.index(of: characteristic.service)!
            let row = characteristics.index(of: characteristic)!
            let indexPath = IndexPath(row: row, section: section)
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}

// MARK: - CharacteristicNotificationStateDelegate
extension PeripheralViewController: CharacteristicNotificationStateDelegate {
    func didUpdate(notificationState isNotifying: Result<Bool, Error>, for characteristic: Characteristic) {

    }
}

// MARK: - CharacteristicDiscoveryDelegate
extension PeripheralViewController: CharacteristicDiscoveryDelegate {
    func didDiscover(descriptors: Result<[Descriptor], Error>, for characteristic: Characteristic) {
        guard case let .ok(descriptors) = descriptors else {
            return
        }
        self.queue.async {
            for descriptor in descriptors {
                if let descriptor = descriptor as? DefaultDescriptor {
                    descriptor.delegate = self
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - DescriptorReadingDelegate
extension PeripheralViewController: DescriptorReadingDelegate {
    public func didUpdate(any: Result<Any, Error>, for descriptor: Descriptor) {

    }
}

// MARK: - DescriptorWritingDelegate
extension PeripheralViewController: DescriptorWritingDelegate {
    public func didWrite(any: Result<Any, Error>, for descriptor: Descriptor) {

    }
}
