//
//  ViewController.swift
//  SensorDataAcquisition2
//
//  Created by Student on 2020. 03. 19..
//  Copyright © 2020. Student. All rights reserved.
//

import UIKit
import WatchConnectivity

//Preparation
var userID = ""
var taskID = "SID"
var prepareTime = 1
var numberOfUpdates = 25
var numberOfRepeats = 2
var defaults = UserDefaults.standard
var dominantHand = Hand.right
var handToUse = Hand.right
let numberOfSessionsKey = "numberOfSessionsSofar"
var watchAccText = ""
var watchDevText = ""

//WatchConnectivity
var sessionWC: WCSession?

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var userIDField: UITextField!
    @IBOutlet weak var taskIDPickerView: UIPickerView!
    @IBOutlet weak var waitTimePickerView: UIPickerView!
    @IBOutlet weak var updatesPickerView: UIPickerView!
    @IBOutlet weak var repeatsPickerView: UIPickerView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var dominantHandField: UILabel!
    @IBOutlet weak var handToUseField: UILabel!
    
    let taskIDs = ["SID", "SIP", "STD", "STP", "WAP"]
    let prepareTimes = [1 ,2 ,3 ,4 , 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    let updatesPerSeconds = [25, 50 , 100]
    let repeats = ["2 (Test)", "3", "5", "10", "20"]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.layer.cornerRadius = 7
        userIDField.delegate = self
        configureWatchKitSession()
    }
    
    func configureWatchKitSession(){
        if WCSession.isSupported(){
            sessionWC = WCSession.default
            sessionWC?.delegate = self
            sessionWC?.activate()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var countrows : Int = taskIDs.count
        if pickerView == waitTimePickerView {
            countrows = prepareTimes.count
        } else if pickerView == updatesPickerView {
            countrows = updatesPerSeconds.count
        } else if pickerView == repeatsPickerView {
            countrows = repeats.count
        }
        return countrows
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == taskIDPickerView {
            let titleRow = taskIDs[row]
            return titleRow
        } else if pickerView == waitTimePickerView{
            let titleRow = prepareTimes[row]
            return String(titleRow)
        } else if pickerView == updatesPickerView {
            let titleRow = updatesPerSeconds[row]
            return String(titleRow)
        } else if pickerView == repeatsPickerView {
            let titleRow = repeats[row]
            return titleRow
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == taskIDPickerView {
            taskID = taskIDs[row]
        } else if pickerView == waitTimePickerView {
            prepareTime = prepareTimes[row]
        } else if pickerView == updatesPickerView {
            numberOfUpdates = updatesPerSeconds[row]
        } else if pickerView == repeatsPickerView {
            if repeats[row] == "2 (Test)" {
                numberOfRepeats = 2
            } else {
                numberOfRepeats = Int(repeats[row])!
            }
        }
    }

    @IBAction func dominantHandSwitch(_ sender: UISwitch) {
        if (sender.isOn == true){
            dominantHandField.text = Hand.right
            dominantHand = Hand.right
        } else {
            dominantHandField.text = Hand.left
            dominantHand = Hand.left
        }
    }
    @IBAction func handToUseSwitch(_ sender: UISwitch) {
        if (sender.isOn == true){
            handToUseField.text = Hand.right
            handToUse = Hand.right
        } else {
            handToUseField.text = Hand.left
            handToUse = Hand.left
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        userID = userIDField.text!
        sendMessageToWatch(key: "iPhone", value: String(numberOfUpdates)+","+String(prepareTime))
    }
    
    private func sendMessageToWatch(key: String, value: String){
        if let validSession = sessionWC{
            let data: [String: Any] = [key : value as Any]
            validSession.sendMessage(data, replyHandler: nil, errorHandler: {(error)-> Void in print("Watch send failed with error \(error)")})
        }
    }
    
}

struct Hand {
    static let left = "Left"
    static let right = "Right"
}


extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController : WCSessionDelegate {
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("received message: \(message)")
        DispatchQueue.main.async {
            if let value = message["watchAcc"] as? String{
                watchAccText = value
            }
            if let value = message["watchDev"] as? String{
                watchDevText = value
            }
        }
    }
}

