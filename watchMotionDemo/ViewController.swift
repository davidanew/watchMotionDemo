//
//  ViewController.swift
//  watchMotionDemo
//
//  Created by David New on 18/04/2019.
//  Copyright © 2019 David New. All rights reserved.
//

import UIKit
import WatchConnectivity
import os.log



class ViewController: UIViewController, WCSessionDelegate  {
    
    let accGain : Double = 1.0
    let rotGain : Double = 0.1
    
    @IBOutlet weak var progressAX: UIProgressView!
    @IBOutlet weak var progressAY: UIProgressView!
    @IBOutlet weak var progressAZ: UIProgressView!
    @IBOutlet weak var progressRX: UIProgressView!
    @IBOutlet weak var progressRY: UIProgressView!
    @IBOutlet weak var progressRZ: UIProgressView!
    
    struct Log {
        static var general = OSLog(subsystem: "com.watchMotionDemo", category: "general")
    }
    
    var connectivitySession : WCSession?

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        os_log("activationDidComplete on phone")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        os_log("sessionDidBecomeInactive on phone")

    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        os_log("sessionDidDeactivate on phone")

    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
 /*
        if let response = message["AccX"] as? Double {
            os_log("phone message recieved")
            DispatchQueue.main.async {
                self.testLabel.text = "phone message recieved : \(response)"
            }
             
        }
 */
        let accX : Double = message["AccX"] as? Double ?? 0.0
        let accY : Double = message["AccY"] as? Double ?? 0.0
        let accZ : Double = message["AccZ"] as? Double ?? 0.0
        let rotX : Double = message["RotX"] as? Double ?? 0.0
        let rotY : Double = message["RotY"] as? Double ?? 0.0
        let rotZ : Double = message["RotZ"] as? Double ?? 0.0
        DispatchQueue.main.async {
            self.testLabel.text = (String(accX))
            self.progressAX.progress = Float(accX * self.accGain)
            self.progressAY.progress = Float(accY * self.accGain)
            self.progressAZ.progress = Float(accZ * self.accGain)
            self.progressRX.progress = Float(rotX * self.rotGain)
            self.progressRY.progress = Float(rotY * self.rotGain)
            self.progressRZ.progress = Float(rotZ * self.rotGain)
        }

    }

    @IBOutlet weak var testLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        //testLabel.text = "phone view did load"
        //print("phone view did load")
        //os_log("watchMotionDemo phone view did load", log: Log.general, type: .info)
        os_log("viewDidLoad")
        
        // Do any additional setup after loading the view.
        if WCSession.isSupported() {
            connectivitySession = WCSession.default
            connectivitySession?.delegate = self
            connectivitySession?.activate()
            os_log ("wc session activated")
        }
        else {
            os_log ("wc session not supported on phone")
        }
    }
}

