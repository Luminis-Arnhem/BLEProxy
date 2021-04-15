import Foundation
import CoreBluetooth

protocol BleCentralDelegate {
    func connected()
    func disconnected(reason: String)
    func dataRead(data: Data)
    func dataWritten()
    func dataReceivedFromPeripheral(data: Data)
    func logMessage(message: String)
}

class BleCentral: NSObject, CBCentralManagerDelegate {
    
    var delegate: BleCentralDelegate?
    
    private var centralManager: CBCentralManager?
    private var peripheralName: String?
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connect() {
        self.peripheralName = BleConstants.DEVICE_NAME
        if self.centralManager?.state == .poweredOn && !(self.centralManager?.isScanning ?? false) {
            self.delegate?.logMessage(message: "Started scanning for BLE peripherals.")
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func disconnect() {
        
    }
    
    func readData(characteristicUUID: CBUUID) {
        
    }
    
    func writeData(characteristicUUID: CBUUID, data: Data) {
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && self.peripheralName != nil && !central.isScanning {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
}
