import Foundation
import CoreBluetooth

protocol BleCentralDelegate {
    func connected(services: [BleService])
    func disconnected(reason: String)
    func dataWritten(onCharacteristicWithUUID uuid: CBUUID, withResult result: CBATTError.Code)
    func dataReceived(data: Data, onCharacteristicWithUUID uuid: CBUUID)
    func logMessage(message: String)
}

class BleCentral: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var delegate: BleCentralDelegate?
    
    private var centralManager: CBCentralManager?
    private var peripheralName: String?
    private var peripheral: CBPeripheral?
    private var services: [BleService]?
    private var connected: Bool = false
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connect() {
        self.connected = false
        self.peripheralName = BleConstants.DEVICE_NAME
        if self.centralManager?.state == .poweredOn && !(self.centralManager?.isScanning ?? false) {
            self.delegate?.logMessage(message: "Started scanning for BLE peripherals.")
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        } else {
            self.delegate?.logMessage(message: "BLE is not powered on (yet).")
        }
    }
    
    func disconnect() {
        self.peripheralName = nil
        self.stopScanning()
        if let peripheral = self.peripheral {
            if peripheral.state == .connected || peripheral.state == .connecting {
                self.centralManager?.cancelPeripheralConnection(peripheral)
            }
        }
    }

    private func stopScanning() {
        if (self.centralManager?.isScanning ?? false) {
            self.delegate?.logMessage(message: "Stopped scanning for BLE peripherals.")
            self.centralManager?.stopScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name?.lowercased(), let gapName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)?.lowercased(), let peripheralName = self.peripheralName?.lowercased() else { return }
        self.delegate?.logMessage(message: "BLE peripheral found with names: [\(name),\(gapName)].")
        if peripheral.state != .connected && (name == peripheralName || gapName == peripheralName) {
            self.stopScanning()
            self.delegate?.logMessage(message: "Connecting to peripheral \(peripheral).")
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            print("Connecting to peripheral")
            self.centralManager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if (!self.connected) {
            self.connected = true
            self.delegate?.logMessage(message: "Connected to peripheral \(peripheral), discovering services.")
            self.setupServicesAndCharacteristics()
            self.peripheral?.discoverServices(nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.delegate?.disconnected(reason: "Connection to peripheral \(peripheral) failed with error: \(error.debugDescription)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.delegate?.disconnected(reason: "Connection to peripheral \(peripheral) closed with error: \(error).")
        } else {
            self.delegate?.disconnected(reason: "Connection to peripheral \(peripheral) closed.")
        }
    }
    
    private func setupServicesAndCharacteristics() {
        self.services = BleConstants.SERVICES_AND_CHARACTERISTICS.map({ (key: CBUUID, value: [CBUUID]) -> BleService in
            let service = BleService(uuid: key)
            service.characteristics = value.map({ (uuid) -> BleCharacteristic in
                return BleCharacteristic(uuid: uuid)
            })
            return service
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            self.delegate?.disconnected(reason: "Peripheral \(peripheral) service discovery failed with error: \(error).")
            self.disconnect()
        } else if let services = peripheral.services {
            for service in services {
                if let expectedService = self.services?.first(where: { (expectedService) -> Bool in
                    service.uuid == expectedService.uuid
                }) {
                    expectedService.service = service
                    self.delegate?.logMessage(message: "Service \(service.uuid.uuidString) found, discovering characteristics.")
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        } else {
            self.delegate?.disconnected(reason: "Peripheral \(peripheral) has no services.")
            self.disconnect()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            self.delegate?.disconnected(reason: "Peripheral \(peripheral) and service \(service.uuid.uuidString) characteristic discovery failed with error: \(error).")
            self.disconnect()
        } else if let characteristics = service.characteristics {
            if let expectedService = self.services?.first(where: { (expectedService) -> Bool in
                service.uuid == expectedService.uuid
            }) {
                for characteristic in characteristics {
                    if let expectedCharacteristic = expectedService.characteristics?.first(where: { (expectedCharacteristic) -> Bool in
                        characteristic.uuid == expectedCharacteristic.uuid
                    }) {
                        expectedCharacteristic.characteristic = characteristic
                    }
                }
            }
            if let services = self.services, self.servicesAndCharacteristicsComplete(services) {
                self.delegate?.connected(services: services)
            }
        } else {
            self.delegate?.disconnected(reason: "Peripheral \(peripheral) and service \(service.uuid.uuidString) have no characteristics.")
            self.disconnect()
        }
    }
    
    private func servicesAndCharacteristicsComplete(_ services: [BleService]) -> Bool {
        return services.allSatisfy({ (bleService) -> Bool in
            return bleService.service != nil && bleService.characteristics?.allSatisfy({ (bleCharacteristic) -> Bool in
                return bleCharacteristic.characteristic != nil
            }) ?? false
        })
    }
    
    func readData(characteristicUUID: CBUUID) {
        if let peripheral = self.peripheral, let characteristic = findCharacteristic(characteristicUUID) {
            self.delegate?.logMessage(message: "Reading from peripheral on characteristic: \(characteristicUUID.uuidString)")
            peripheral.readValue(for: characteristic)
        }
    }
    
    private func findCharacteristic(_ characteristicUUID: CBUUID) -> CBCharacteristic? {
        if let services = self.services {
            for service in services {
                if let bleCharacteristic = service.characteristics?.first(where: { (bleCharacteristic) -> Bool in
                    return bleCharacteristic.uuid == characteristicUUID
                }) {
                    return bleCharacteristic.characteristic
                }
            }
        }
        return nil
    }
    
    func writeData(characteristicUUID: CBUUID, data: Data, writeType: CBCharacteristicWriteType) {
        if let peripheral = self.peripheral, let characteristic = findCharacteristic(characteristicUUID) {
            self.delegate?.logMessage(message: "Writing to peripheral on characteristic: \(characteristicUUID.uuidString) -> \(data.hexEncodedString())")
            peripheral.writeValue(data, for: characteristic, type: writeType)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            self.delegate?.disconnected(reason: "Writing data to peripheral on characteristic \(characteristic.uuid.uuidString) failed with error: \(error).")
            self.delegate?.dataWritten(onCharacteristicWithUUID: characteristic.uuid, withResult: CBATTError.unlikelyError)
        } else {
            self.delegate?.dataWritten(onCharacteristicWithUUID: characteristic.uuid, withResult: CBATTError.success)
        }
    }

    func registerForNotifications(characteristicUUID: CBUUID) {
        if let peripheral = self.peripheral, let characteristic = findCharacteristic(characteristicUUID) {
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: characteristic)
            } else {
                delegate?.logMessage(message: "registerForNotifications requested for characteristic \(characteristicUUID) that does not allow such actions.")
            }
        }
    }

    func unregisterFromNotifications(characteristicUUID: CBUUID) {
        if let peripheral = self.peripheral, let characteristic = findCharacteristic(characteristicUUID) {
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                peripheral.setNotifyValue(false, for: characteristic)
            } else {
                delegate?.logMessage(message: "registerForNotifications requested for characteristic \(characteristicUUID.uuidString) that does not allow such actions.")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            self.delegate?.disconnected(reason: "Notification state update failed for characteristic \(characteristic.uuid.uuidString) with error: \(error).")
            self.disconnect()
        } else if (characteristic.isNotifying) {
            delegate?.logMessage(message: "Now receiving notifications for characteristic \(characteristic.uuid.uuidString)")
        } else {
            delegate?.logMessage(message: "No longer receiving notifications for characteristic \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            self.delegate?.disconnected(reason: "Receiving data failed with error: \(error).")
            self.disconnect()
        } else if let data = characteristic.value {
            self.delegate?.dataReceived(data: data, onCharacteristicWithUUID: characteristic.uuid)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && self.peripheralName != nil && !central.isScanning {
            self.delegate?.logMessage(message: "BLE is powered on now, started scanning for BLE peripherals.")
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
}
