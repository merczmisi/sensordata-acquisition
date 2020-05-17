//
//  InterfaceController.swift
//  SensorDataAcquisition2 WatchKit Extension
//
//  Created by Mercz Mihály on 2020. 03. 19..
//  Copyright © 2020. Student. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import CoreMotion
import os.log

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var label: WKInterfaceLabel!
    @IBOutlet weak var newSessionButton: WKInterfaceButton!
    
    //Motion
    let motionManager = CMMotionManager()
    var motionTimer: Timer?
    
    //Preparation
    var csvAcceleroText = ""
    var csvDeviceMotionText = ""
    var prepareTimer: Timer?
    var countDown = 1
    var frequency =  1.0 / 25
    
    //WatchConnectivity
    let session = WCSession.default
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WKExtension.shared().isAutorotating = true
        disableButton(button: newSessionButton)
        configureSession()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    fileprivate func disableButton(button: WKInterfaceButton) {
        button.setEnabled(false)
        button.setHidden(true)
    }
    
    fileprivate func configureSession() {
        session.delegate = self
        session.activate()
        do {
            sleep(1)
        }
        if session.activationState == WCSessionActivationState.activated{
            self.label.setText("Connection made between the watch and the phone.")
            self.label.setTextColor(UIColor.white)
        }
    }
    
    /* Creates a timer that immediately starts firing.
     frequency: the frequency of the timer in seconds
     selector: the function to call when the timer is fired
     */
    private func createTimer(frequency: TimeInterval, selector: Selector) -> Timer {
        return Timer.scheduledTimer(timeInterval: frequency, target: self, selector: selector, userInfo: nil, repeats: true)
    }
    
    /* This method is called when the motion timer is fired. (handles data recording)*/
    @objc func motionTimerFired() {
        queryAcceleroMeterData()
        queryDeviceMotionData()
    }
    
    fileprivate func queryDeviceMotionData() {
        if let deviceMotion = motionManager.deviceMotion {
            let oneLine = String(deviceMotion.attitude.quaternion.x) + "," + String(deviceMotion.attitude.quaternion.y) + "," + String(deviceMotion.attitude.quaternion.z) + "," +
                String(deviceMotion.attitude.quaternion.w) + "," +
                String(deviceMotion.userAcceleration.x) + "," +
                String(deviceMotion.userAcceleration.y) + "," +
                String(deviceMotion.userAcceleration.z) + "," +
                String(deviceMotion.rotationRate.x) + "," +
                String(deviceMotion.rotationRate.y) + "," +
                String(deviceMotion.rotationRate.z) + "," +
                String(Date().millisecondsSince1970) + "\n"
            csvDeviceMotionText.append(oneLine)
        }
    }
    
    fileprivate func queryAcceleroMeterData() {
        if let accelerometerData = motionManager.accelerometerData {
            let oneLine = String(accelerometerData.acceleration.x) + "," + String(accelerometerData.acceleration.y) + "," + String(accelerometerData.acceleration.z) + "," + String(Date().millisecondsSince1970) + ",,,,,,,\n"
            csvAcceleroText.append(oneLine)
        }
    }
    
    func startUpdates(){
        motionManager.startAccelerometerUpdates()
        motionManager.startDeviceMotionUpdates()
    }
    
    func setCSVTextsFirstRows(){
        csvAcceleroText = "wAccX,wAccY,wAccZ,wTimeStamp,,,,,,,\n"
        csvDeviceMotionText = "wQuatX,wQuatY,wQuatZ,wQuatW,wUserAccX,wUserAccY,wUserAccZ,wRotRateX,wRotRateY,wRotRateZ,wTimeStamp\n"
    }
    
    func stopUpdates(){
        motionManager.stopAccelerometerUpdates() 
        motionManager.stopDeviceMotionUpdates()
    }
    
    @IBAction func newSessionButtonTapped() {
        self.awake(withContext: nil)
        self.label.setText("Set the details of the next session on the phone.")
    }
    
    func enableButton(button: WKInterfaceButton){
        button.setEnabled(true)
        button.setHidden(false)
    }
    
    @objc private func prepareTimerFired() {
        countDown -= 1
        self.label.setTextColor(UIColor.white)
        self.label.setText("Please prepare for record in: \(countDown)s")
        if countDown == 0 {
            do {
                usleep(600000)
            }
            setCSVTextsFirstRows()
            startUpdates()
            DispatchQueue.main.async {
                self.motionTimer = self.createTimer(frequency: self.frequency, selector: #selector(self.motionTimerFired))
            }
            disableButton(button: newSessionButton)
            self.label.setText("Recording ...")
            self.label.setTextColor(UIColor.red)
            prepareTimer?.invalidate()
        }
    }
}

extension InterfaceController : WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        super.willActivate()
        print("received data: \(message)")
        
        if let value = message["iPhone"] as? String {
            switch value {
            case "stop":
                motionTimer?.invalidate()
                stopUpdates()
                self.label.setText("Recording stopped.")
                self.label.setTextColor(UIColor.green)
                sendMessageToPhone(key: "watchAcc", value: csvAcceleroText)
                sendMessageToPhone(key: "watchDev", value: csvDeviceMotionText)
                print(csvDeviceMotionText)
            case "start":
                setCSVTextsFirstRows()
                startUpdates()
                DispatchQueue.main.async {
                    self.motionTimer = self.createTimer(frequency: self.frequency, selector: #selector(self.motionTimerFired))
                }
                disableButton(button: newSessionButton)
                self.label.setText("Recording ...")
                self.label.setTextColor(UIColor.red)
            case "finish":
                self.label.setText("Session finished.")
                self.label.setTextColor(UIColor.yellow)
                enableButton(button: newSessionButton)
            default :
                let preparationArray = value.components(separatedBy: ",")
                frequency = 1.0 / Double(preparationArray[0])!
                print(frequency)
                countDown = Int(preparationArray[1])!
                disableButton(button: newSessionButton)
                self.label.setText("Press start button on the phone to begin recording.")
                self.label.setTextColor(UIColor.green)
            }
        }
        
        if let value = message["prepare"] as? String {
            countDown = Int(value)!
            DispatchQueue.main.async {
                self.prepareTimer = self.createTimer(frequency: 1, selector: #selector(self.prepareTimerFired))
            }
        }
    }
    
    func sendMessageToPhone(key: String, value: String){
        let data: [String: Any] = [key : value as Any]
        session.sendMessage(data, replyHandler: nil, errorHandler: {(error)-> Void in print("Watch send failed with error \(error)")})
    }
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
