import Foundation
import CoreBluetooth

protocol BlePeripheralDelegate {
    func advertisingStarted()
    func advertisingStopped(reason: String)
    func read(fromCharacteristicUUID uuid: CBUUID)
    func write(data: Data, toCharacteristicUUID uuid: CBUUID)
    func registerForNotifications(onCharacteristicWithUUID uuid: CBUUID)
    func unregisterFromNotifications(onCharacteristicWithUUID uuid: CBUUID)
}

class BlePeripheral: NSObject, CBPeripheralManagerDelegate {
    
    var delegate: BlePeripheralDelegate?
    
    private var peripheralManager: CBPeripheralManager?
    private var services: [CBMutableService] = []
    private var characteristics: [CBMutableCharacteristic] = []
    private var openReadRequests: [CBATTRequest] = []
    private var openWriteRequests: [CBATTRequest] = []
    private var registrations: [CBCharacteristic: [CBCentral]] = [:]
    
    override init() {
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising(services: [BleService]) {
        self.openReadRequests = []
        self.openWriteRequests = []
        self.registrations = [:]
        self.initialiseServicesAndCharacteristics(services: services)
        self.peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey : self.services.map({ (service) -> CBUUID in
                return service.uuid
            }),
            CBAdvertisementDataLocalNameKey: BleConstants.DEVICE_NAME,
        ])
    }
    
    private func initialiseServicesAndCharacteristics(services: [BleService]) {
        self.services = []
        for bleService in services {
            var characteristics:[CBMutableCharacteristic] = []
            if let bleCharacteristics = bleService.characteristics {
                for bleCharacteristic in bleCharacteristics {
                    if let characteristic = bleCharacteristic.characteristic {
                        let mutableCharacteristic = CBMutableCharacteristic(type: characteristic.uuid, properties: characteristic.properties, value: nil, permissions: self.getPermissions(fromProperties: characteristic.properties))
                        characteristics.append(mutableCharacteristic)
                        self.characteristics.append(mutableCharacteristic)
                    }
                }
            }
            let service = CBMutableService(type: bleService.uuid, primary: bleService.service?.isPrimary ?? false)
            service.characteristics = characteristics
            self.services.append(service)
        }
    }
    
    private func getPermissions(fromProperties: CBCharacteristicProperties) -> CBAttributePermissions {
        if fromProperties.contains(.write) || fromProperties.contains(.writeWithoutResponse) {
            return .writeable
        } else {
            return .readable
        }
    }
    
    func stopAdvertising() {
        self.peripheralManager?.stopAdvertising()
        self.peripheralManager?.removeAllServices()
        self.delegate?.advertisingStopped(reason: "Stop requested")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            self.delegate?.advertisingStopped(reason: "There was an error: \(error)")
        } else {
            self.delegate?.advertisingStarted()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        self.openReadRequests.append(request)
        self.delegate?.read(fromCharacteristicUUID: request.characteristic.uuid)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let data = request.value {
                self.openWriteRequests.append(request)
                self.delegate?.write(data: data, toCharacteristicUUID: request.characteristic.uuid)
            }
        }
    }
    
    func confirmWriteRequest(onCharacteristicUUID uuid: CBUUID, withResult result: CBATTError.Code) {
        let requestsToRespondTo = self.openWriteRequests.filter { (request) -> Bool in
            request.characteristic.uuid == uuid
        }
        for request in requestsToRespondTo {
            self.peripheralManager?.respond(to: request, withResult: result)
        }
        self.openWriteRequests.removeAll { (request) -> Bool in
            requestsToRespondTo.contains(request)
        }
    }
    
    func dataReceived(data: Data, onCharacteristicUUID uuid: CBUUID) {
        if let characteristic = self.characteristics.first(where: { (characteristic) -> Bool in
            characteristic.uuid == uuid
        }) {
            characteristic.value = data
            
            let requestsToRespondTo = self.openReadRequests.filter { (request) -> Bool in
                request.characteristic.uuid == uuid
            }
            for request in requestsToRespondTo {
                self.peripheralManager?.respond(to: request, withResult: .success)
            }
            self.openWriteRequests.removeAll { (request) -> Bool in
                requestsToRespondTo.contains(request)
            }
            
            self.peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        if var registrationsForCharacteristic = self.registrations[characteristic] {
            if (!registrationsForCharacteristic.contains(central)) {
                registrationsForCharacteristic.append(central)
            }
        } else {
            self.registrations[characteristic] = [central]
            self.delegate?.registerForNotifications(onCharacteristicWithUUID: characteristic.uuid)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if var registrationsForCharacteristic = self.registrations[characteristic] {
            registrationsForCharacteristic.removeAll { (centralRegistration) -> Bool in
                centralRegistration.identifier == central.identifier
            }
            if registrationsForCharacteristic.isEmpty {
                self.delegate?.unregisterFromNotifications(onCharacteristicWithUUID: characteristic.uuid)
            }
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state != .poweredOn {
            self.delegate?.advertisingStopped(reason: "Bluetooth is turned off.")
            return
        }
        
        for service in self.services {
            self.peripheralManager?.add(service)
        }
    }
}
