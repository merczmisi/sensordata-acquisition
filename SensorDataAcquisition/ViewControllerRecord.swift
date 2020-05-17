//
//  ViewControllerRecord.swift
//  SensorDataAcquisition2
//
//  Created by Student on 2020. 03. 27..
//  Copyright © 2020. Student. All rights reserved.
//

import UIKit
import CoreMotion
import CoreAudioKit

class ViewControllerRecord: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var newSessionButton: UIButton!
    
    // Motion
    let motionManager = CMMotionManager()
    var motionTimer: Timer?
    var frequency: TimeInterval = 1.0 / Double(numberOfUpdates)
    
    // Preparation
    var prepareTimer: Timer?
    var countDown: Int = prepareTime
    var phoneAccText = ""
    var phoneGyrText = ""
    var phoneMagText = ""
    var phoneDevText = ""
    var recordCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.layer.cornerRadius = 7
        stopButton.layer.cornerRadius = 7
        newSessionButton.layer.cornerRadius = 7
        discardButton.layer.cornerRadius = 7
        saveButton.layer.cornerRadius = 7
        titleLabel.text = "Press start to begin the session!\n"+getStringFromRepeats()
        disableButton(button: newSessionButton)
        disableButton(button: discardButton)
        disableButton(button: saveButton)
        disableButton(button: stopButton)
    }
    
    func getStringFromRepeats() -> String {
        if numberOfRepeats == 2 {
            return "(This is just a test record.)"
        } else {
            return "(\(numberOfRepeats) records)"
        }
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        navigationItem.hidesBackButton = true
        disableButton(button: startButton)
        getReadyForRecording()
        sendMessageToWatch(key: "prepare", value: String(prepareTime))
    }
    
    fileprivate func disableButton(button: UIButton){
        button.isHidden = true
        button.isEnabled = false
    }
    
    /* This method is called when the start button is tapped.
     It stops any ongoing process (reset) and starts the prepare count back.*/
    fileprivate func getReadyForRecording() {
        disableAllButtons()
        titleLabel.text = "Please prepare for (\(recordCounter+1).) record in: \n \(countDown)s"
        prepareTimer = createTimer(frequency: 1, selector: #selector(prepareTimerFired))
    }

    fileprivate func disableAllButtons() {
        startButton.isEnabled = false
        newSessionButton.isEnabled = false
        stopButton.isEnabled = false
        discardButton.isEnabled = false
        saveButton.isEnabled = false
    }
    
    /* Creates a timer that immediately starts firing.
     frequency: the frequency of the timer in seconds
     selector: the function to call when the timer is fired
     */
    private func createTimer(frequency: TimeInterval, selector: Selector) -> Timer {
        return Timer.scheduledTimer(timeInterval: frequency, target: self, selector: selector, userInfo: nil, repeats: true)
    }
    
    /* This method is called when the prepare timer fires. (handles the count back and starts recording)*/
    @objc private func prepareTimerFired() {
        countDown -= 1
        titleLabel.text = "Please prepare for the (\(recordCounter+1).) record in: \n \(countDown)s"
        if countDown == 0 {
            finishPreparation()
            startButton.isEnabled = false
            AudioServicesPlaySystemSoundWithCompletion(1052){
                DispatchQueue.main.async {
                    if(numberOfRepeats != 2){
                        self.startRecording()
                    }
                    self.titleLabel.text = "Recording... \n Press stop to end capturing data!"
                }
            }
        enableButton(button: stopButton)
        }
    }
    
    /* Stops the count back timer and resets the counter to prepareTime.*/
    private func finishPreparation() {
        countDown = prepareTime
        prepareTimer?.invalidate()
    }
    
    private func sendMessageToWatch(key: String, value: String){
        if let validSession = sessionWC{
            let data: [String: Any] = [key : value as Any]
            validSession.sendMessage(data, replyHandler: nil, errorHandler: {(error)-> Void in print("Watch send failed with error \(error)")})
        }
    }
    
    /* Tells the motion manager to start recording data and starts the motion timer. */
    private func startRecording() {
        setTextsFirstRows()
        startUpdates()
        motionTimer = createTimer(frequency: frequency, selector: #selector(motionTimerFired))
    }
    
    fileprivate func setTextsFirstRows() {
        phoneAccText = "AccX,AccY,AccZ,TimeStamp,,,,,,,\n"
        phoneGyrText = "GyrX,GyrY,GyrZ,TimeStamp,,,,,,,\n"
        phoneMagText = "MagX,MagY,MagZ,TimeStamp,,,,,,,\n"
        phoneDevText = "QuatX,QuatY,QuatZ,QuatW,UserAccX,UserAccY,UserAccZ,RotRateX,RotRateY,RotRateZ,TimeStamp\n"
    }
    
    fileprivate func enableButton(button: UIButton){
        button.isHidden = false
        button.isEnabled = true
    }
    
    fileprivate func startUpdates() {
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        motionManager.startDeviceMotionUpdates()
    }
    
    /* This method is called when the motion timer is fired. (handles data recording)*/
    @objc func motionTimerFired() {
        queryAccelerometerData()
        queryGyroscopeData()
        queryMagnetometerData()
        queryDeviceMotionData()
    }
    
    fileprivate func queryAccelerometerData() {
        if let accelerometerData = motionManager.accelerometerData {
            let oneLine = String(accelerometerData.acceleration.x) + "," + String(accelerometerData.acceleration.y) + "," + String(accelerometerData.acceleration.z) + "," + String(Date().millisecondsSince1970) + ",,,,,,,\n"
            phoneAccText.append(oneLine)
        }
    }
    
    fileprivate func queryGyroscopeData() {
        if let gyroscopeData = motionManager.gyroData {
            let oneLine = String(gyroscopeData.rotationRate.x) + "," + String(gyroscopeData.rotationRate.y) + "," + String(gyroscopeData.rotationRate.z) + "," + String(Date().millisecondsSince1970) + ",,,,,,,\n"
            phoneGyrText.append(oneLine)
        }
    }
    
    fileprivate func queryMagnetometerData() {
        if let magnetometerData = motionManager.magnetometerData {
            let oneLine = String(magnetometerData.magneticField.x) + "," + String(magnetometerData.magneticField.y) + "," + String(magnetometerData.magneticField.z) + "," + String(Date().millisecondsSince1970) + ",,,,,,,\n"
            phoneMagText.append(oneLine)
        }
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
            phoneDevText.append(oneLine)
        }
    }
    
    @IBAction func stopButtonTapped(_ sender: Any) {
        sendMessageToWatch(key: "iPhone", value: "stop")
        disableButton(button: stopButton)
        enableButton(button: discardButton)
        enableButton(button: saveButton)
        titleLabel.text = "The \(recordCounter+1). record is finished.\n\(numberOfRepeats-recordCounter-1) records left.\n Press save to keep the data or discard if the record was not appropriate!"
        stopRecording()
    }
    
    /* Stops  motion timer and tells the motion manager
     to finish capturing data.*/
    private func stopRecording() {
        motionTimer?.invalidate()
        stopMotionManagerUpdates()
    }
    
    fileprivate func stopMotionManagerUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
    }
    
    @IBAction func discardButtonTapped(_ sender: Any) {
        disableButton(button: discardButton)
        disableButton(button: saveButton)
        setTextsFirstRows()
        getReadyForRecording()
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        recordCounter += 1
        disableButton(button: discardButton)
        disableButton(button: saveButton)
        if(numberOfRepeats == 2) {
            if recordCounter == numberOfRepeats {
                sessionFinished()
            } else {
                sendMessageToWatch(key: "prepare", value: String(prepareTime))
                getReadyForRecording()
            }
        } else if recordCounter < numberOfRepeats {
            sendMessageToWatch(key: "prepare", value: String(prepareTime))
            keepRecordAndGetReadyForNext()
        } else {
            sessionFinished()
            printRecordedDataToCSV()
            increaseTotalNumberOfSessions()
        }
    }
    
    fileprivate func sessionFinished() {
        sendMessageToWatch(key: "iPhone", value: "finish")
        enableButton(button: newSessionButton)
        titleLabel.text = "Session finished."
    }
    
    fileprivate func keepRecordAndGetReadyForNext() {
        printRecordedDataToCSV()
        setTextsFirstRows()
        getReadyForRecording()
    }
    
    fileprivate func printRecordedDataToCSV() {
        do {
            let dir: URL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last! as URL
            let url = dir.appendingPathComponent(generateFileName())

            try phoneAccText.appendToURL(fileURL: url as URL)
            try phoneGyrText.appendToURL(fileURL: url as URL)
            try phoneMagText.appendToURL(fileURL: url as URL)
            try phoneDevText.appendToURL(fileURL: url as URL)
            
            try watchAccText.appendToURL(fileURL: url as URL)
            try watchDevText.appendToURL(fileURL: url as URL)
        }
        catch {
            print("Could not write to file")
        }
    }
    
    fileprivate func increaseTotalNumberOfSessions() {
        defaults.set(getTotalNumberOfSessions() + 1, forKey: numberOfSessionsKey)
    }
        
    func getTotalNumberOfSessions() -> Int {
        return defaults.integer(forKey: numberOfSessionsKey)
    }
    
    private func generateFileName() -> String {
        return userID+"_"+taskID+"_"+dominantHand[0]+"_"+handToUse[0]+"_"+String(numberOfUpdates)+"_"+String(getTotalNumberOfSessions())+".csv"
    }
    
    @IBAction func newSessionButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        setTextsFirstRows()
    }

    
}

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

extension String {
   func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }

    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
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
