import Foundation
import CoreBluetooth

protocol BlePeripheralDelegate {
    func advertisingStarted(services: [BleService])
    func advertisingStopped(reason: String)
    func read(fromCharacteristicUUID: CBUUID)
    func write(data: Data, toCharacteristicUUID: CBUUID)
    func registerForNotifications(onCharacteristicWithUUID: CBUUID)
    func unregisterFromNotifications(onCharacteristicWithUUID: CBUUID)
    func logMessage(message: String)
}

class BlePeripheral: NSObject, CBPeripheralManagerDelegate {
    
    var delegate: BlePeripheralDelegate?
    
    private var peripheralManager: CBPeripheralManager?
    
    override init() {
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAvertising() {
        
    }
    
    func stopAdvertising() {
        
    }
    
    func confirmWriteRequest(onCharacteristicUUID: CBUUID, withResult: CBATTError.Code) {
        
    }
    
    func dataReceived(data: Data, onCharacteristicUUID: CBUUID) {
        
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
}
