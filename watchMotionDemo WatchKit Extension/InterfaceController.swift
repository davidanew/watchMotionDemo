//  Copyright © 2019 David New. All rights reserved.

import WatchKit
import Foundation
import CoreMotion
import HealthKit
import WatchConnectivity
import os.log

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet weak var accLabel: WKInterfaceLabel!
    //Handles motion from the watch's sensors
    let motionManager = CMMotionManager()
    //A workout session is needed so we can get readings in the background
    var workoutSession : HKWorkoutSession?
    //Heath store only needed for workout initialisation
    let healthStore = HKHealthStore()
    //For sending messages to the phone
    var connectivitySession : WCSession?
    //Period ogf motion samples
    let deviceMotionUpdateInterval : TimeInterval = 0.02
    //We take a max of samples over deviceMotionUpdateInterval and send it after
    //this many samples
    let samplesPerMessage : Int = 25
    //Used to cound to the above amount of samples
    var sampleCount : Int = 0
    //Store working copies of the max amopunt of samples
    var accXMax : Double = 0
    var accYMax : Double = 0
    var accZMax : Double = 0
    var rotXMax : Double = 0
    var rotYMax : Double = 0
    var rotZMax : Double = 0
  
    //Start button has been pressed
    //TODO: Update colours on buttons on start and stop
    @IBAction func startButton() {
        //If this is nil then there is no workout session running
        //Could be a guard statement
        if (workoutSession != nil){
            return
        }
        //Create the workout configuration and start the session
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .mixedCardio
        workoutConfiguration.locationType = .indoor
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        }
        catch {
            os_log("Error generating workout session")
            return
        }
        //Start the workout session
        workoutSession?.startActivity(with: Date())
        if motionManager.isDeviceMotionAvailable {
            //TODO: Update this for max counting
            //request updates from motion manager
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { [weak self] (data, error) in
                //Need valid data for acceleration and rortation
                guard let acceleration : CMAcceleration = data?.userAcceleration else {
                    os_log("Invalid acceleration")
                    return
                }
                guard let rotationRate : CMRotationRate = data?.rotationRate else {
                    os_log("Invalid rotation rate")
                    return
                }
                //Update the max values
                self?.accXMax = max(acceleration.x, self?.accXMax ?? 0.0)
                self?.accYMax = max(acceleration.y, self?.accYMax ?? 0.0)
                self?.accZMax = max(acceleration.z, self?.accZMax ?? 0.0)
                self?.rotXMax = max(rotationRate.x, self?.rotXMax ?? 0.0)
                self?.rotYMax = max(rotationRate.y, self?.rotYMax ?? 0.0)
                self?.rotZMax = max(rotationRate.z, self?.rotZMax ?? 0.0)
                
                if let samplesPerMessage = self?.samplesPerMessage,  self?.sampleCount == samplesPerMessage - 1 {
                    //Display total acceleration on watch
                    let totalAcceleration = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
                    self?.accLabel.setText(String(format: "%.1fg", totalAcceleration))
                    //Create a dictionary of the acceleration and rotation data
                    let messageDict : [String : Double] = [
                        "AccX" : self?.accXMax ?? 0.0,
                        "AccY" : self?.accYMax ?? 0.0,
                        "AccZ" : self?.accZMax ?? 0.0,
                        "RotX" : self?.rotXMax ?? 0.0,
                        "RotY" : self?.rotYMax ?? 0.0,
                        "RotZ" : self?.rotZMax ?? 0.0
                    ]
                    //Send this dictionary to the watch
                    self?.connectivitySession?.sendMessage(messageDict, replyHandler: nil , errorHandler: { (error) in
                        print("message error \(error)")
                    })
                    self?.sampleCount = 0
                    self?.accXMax = 0.0
                    self?.accYMax = 0.0
                    self?.accZMax = 0.0
                    self?.rotXMax = 0.0
                    self?.rotYMax = 0.0
                    self?.rotZMax = 0.0
                }
                else {
                    self?.sampleCount += 1
                }
            }
        }
        else {
            print ("Motion not available")
        }
    }
    @IBAction func stopButton() {
        //If workout session is already nil we don't need to do anaything
        //TODO: Think a bout guard instead
        if workoutSession == nil {
            return
        }
        //Stop the motion update processing
        motionManager.stopDeviceMotionUpdates()
        //Remove the workout session
        workoutSession?.end()
        workoutSession = nil
        //Upadate the data label
        self.accLabel.setText("Stopped")
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        //Sensor data update frequency
        motionManager.deviceMotionUpdateInterval = deviceMotionUpdateInterval
        //Show user the workout is not yet running
        self.accLabel.setText("Stopped")
        //Start phone connection session
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
    
    //Required WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        os_log("WC session activated on watch")
    }
}
