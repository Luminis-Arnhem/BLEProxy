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
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connect() {
        
    }
    
    func disconnect() {
        
    }
    
    func readData(characteristicUUID: CBUUID) {
        
    }
    
    func writeData(characteristicUUID: CBUUID, data: Data) {
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
}
