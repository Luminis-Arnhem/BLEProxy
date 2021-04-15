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
    
    override init() {
        super.init()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
}
