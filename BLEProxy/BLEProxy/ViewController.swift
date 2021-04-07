//
//  ViewController.swift
//  BLEProxy
//
//  Created by Tom Hanekamp on 07/04/2021.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var startProxyButton: NSButton!
    @IBOutlet weak var stopProxyButton: NSButton!
    @IBOutlet weak var logView: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func startProxy(_ sender: Any) {
    }
    
    @IBAction func stopProxy(_ sender: Any) {
    }
    
    @IBAction func clearLog(_ sender: Any) {
    }
}

