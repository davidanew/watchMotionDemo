//  Copyright © 2019 David New. All rights reserved.

import WatchKit
import Foundation
import CoreMotion
import HealthKit

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var accLabel: WKInterfaceLabel!
    let motionManager = CMMotionManager()
    var workoutSession : HKWorkoutSession?
    let healthStore = HKHealthStore()
    
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
        }
        workoutSession?.startActivity(with: Date())
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (data, error) in
                if let acceleration : CMAcceleration = data?.userAcceleration {
                    let xSquared : Double = pow(acceleration.x, 2)
                    let ySquared : Double = pow(acceleration.y, 2)
                    let zSquared : Double = pow(acceleration.z, 2)
                    let totalSquared : Double = xSquared + ySquared + zSquared
                    let totalAcceleration : Double = sqrt(totalSquared)
                    //TODO: Check units
                    self.accLabel.setText(String(format: "%.1fm/s/s", totalAcceleration)   )
                    print (totalAcceleration)
                }
                else {
                    print ("data is nil")
                }
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
        self.accLabel.setText(String("Stopped")   )
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        motionManager.deviceMotionUpdateInterval = 1
        accLabel.setText("")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
