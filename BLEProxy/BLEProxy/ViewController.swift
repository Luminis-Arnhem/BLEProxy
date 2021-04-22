import Cocoa
import CoreBluetooth

class ViewController: NSViewController, BleCentralDelegate {
    
    @IBOutlet weak var startProxyButton: NSButton!
    @IBOutlet weak var stopProxyButton: NSButton!
    @IBOutlet weak var logView: NSTextField!
    
    var bleCentral: BleCentral?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.bleCentral = BleCentral()
        self.bleCentral?.delegate = self
    }

    @IBAction func startProxy(_ sender: Any) {
        startProxyButton.isEnabled = false
        stopProxyButton.isEnabled = true
        self.bleCentral?.connect()
    }
    
    @IBAction func stopProxy(_ sender: Any) {
        startProxyButton.isEnabled = true
        stopProxyButton.isEnabled = false
        self.bleCentral?.disconnect()
    }
    
    @IBAction func clearLog(_ sender: Any) {
        self.logView.stringValue = ""
    }
    
    func connected(services: [BleService]) {
        log("Connected to peripheral")
    }
    
    func disconnected(reason: String) {
        log("Stopped because: \(reason)")
    }
    
    func dataWritten(onCharacteristicWithUUID: CBUUID, withResult: CBATTError.Code) {
        log("Data written from central to peripheral on characteristic \(onCharacteristicWithUUID.uuidString) with result: \(withResult)")
    }
    
    func dataReceived(data: Data, onCharacteristicWithUUID: CBUUID) {
        log("Received \(data) from peripheral to pass to central on characteristic \(onCharacteristicWithUUID.uuidString)")
    }
    
    func logMessage(message: String) {
        log(message)
    }
    
    private func log(_ message: String) {
        logView.stringValue.append("\(message)\n")
    }
}
