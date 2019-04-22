//  Copyright © 2019 David New. All rights reserved.

import UIKit
import WatchConnectivity
import os.log

class ViewController: UIViewController, WCSessionDelegate  {
    
    //Sensor values are multiplied by this to produce graphs with the right range
    let accGain : Double = 1.0
    let rotGain : Double = 0.1
    
    //Graphs for senso values use progress views
    @IBOutlet weak var progressAX: UIProgressView!
    @IBOutlet weak var progressAY: UIProgressView!
    @IBOutlet weak var progressAZ: UIProgressView!
    @IBOutlet weak var progressRX: UIProgressView!
    @IBOutlet weak var progressRY: UIProgressView!
    @IBOutlet weak var progressRZ: UIProgressView!
    
    //Label for debugging/logging
    @IBOutlet weak var testLabel: UILabel!

    //TODO: Either remove this or figure out how it is meant to work
    struct Log {
        static var general = OSLog(subsystem: "com.watchMotionDemo", category: "general")
    }
    
    //Session for recieving data from watch
    var connectivitySession : WCSession?
    
    //Reuquired WCSessionDelegate methods

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        os_log("activationDidComplete on phone")
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
        os_log("sessionDidBecomeInactive on phone")

    }
    func sessionDidDeactivate(_ session: WCSession) {
        os_log("sessionDidDeactivate on phone")
    }
    
    //handle message from watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        //Extract values from message dictionary
        let accX : Double = message["AccX"] as? Double ?? 0.0
        let accY : Double = message["AccY"] as? Double ?? 0.0
        let accZ : Double = message["AccZ"] as? Double ?? 0.0
        let rotX : Double = message["RotX"] as? Double ?? 0.0
        let rotY : Double = message["RotY"] as? Double ?? 0.0
        let rotZ : Double = message["RotZ"] as? Double ?? 0.0
        DispatchQueue.main.async {
            //test label for any test
            self.testLabel.text = (String(rotX))
            //Update graphs
            self.progressAX.progress = Float(abs(accX * self.accGain))
            self.progressAY.progress = Float(abs(accY * self.accGain))
            self.progressAZ.progress = Float(abs(accZ * self.accGain))
            self.progressRX.progress = Float(abs(rotX * self.rotGain))
            self.progressRY.progress = Float(abs(rotY * self.rotGain))
            self.progressRZ.progress = Float(abs(rotZ * self.rotGain))
        }

    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("viewDidLoad")
        //Start watch connection to listen for messages
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

