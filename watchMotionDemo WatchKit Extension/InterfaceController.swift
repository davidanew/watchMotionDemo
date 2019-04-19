//  Copyright © 2019 David New. All rights reserved.

import WatchKit
import Foundation
import CoreMotion
import HealthKit
import WatchConnectivity
import os.log

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet weak var accLabel: WKInterfaceLabel!
    let motionManager = CMMotionManager()
    var workoutSession : HKWorkoutSession?
    let healthStore = HKHealthStore()
    var connectivitySession : WCSession?
    
    @IBAction func startButton() {
        if (workoutSession != nil){
            return
        }
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .mixedCardio
        workoutConfiguration.locationType = .indoor
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        }
        catch {
            print("Error generating workout session")
            return
        }
        workoutSession?.startActivity(with: Date())
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (data, error) in
                guard let acceleration : CMAcceleration = data?.userAcceleration else {
                    os_log("Invalid acceleration")
                    return
                }
                guard let rotationRate : CMRotationRate = data?.rotationRate else {
                    os_log("Invalid rotation rate")
                    return
                }
                let totalAcceleration = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
                self.accLabel.setText(String(format: "%.1fg", totalAcceleration))
                let messageDict : [String : Double] = [
                    "AccX" : acceleration.x,
                    "AccY" : acceleration.y,
                    "AccZ" : acceleration.z,
                    "RotX" : rotationRate.x,
                    "RotY" : rotationRate.y,
                    "RotZ" : rotationRate.z
                ]
                self.connectivitySession?.sendMessage(messageDict, replyHandler: nil , errorHandler: { (error) in
                    print("message error \(error)")
                })
            }
        }
        else {
            print ("Motion not available")
        }
    }
    @IBAction func stopButton() {
        if workoutSession == nil {
            return
        }
        motionManager.stopDeviceMotionUpdates()
        workoutSession?.end()
        workoutSession = nil
        self.accLabel.setText("Stopped")
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        motionManager.deviceMotionUpdateInterval = 0.1
        self.accLabel.setText("Stopped")

        if WCSession.isSupported() {
            connectivitySession = WCSession.default
            connectivitySession?.delegate = self
            connectivitySession?.activate()
            
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        os_log("WC session activated on watch")
    }

}
