//
//  ViewController.swift
//  Whatsit
//
//  Created by Patty Case on 10/20/18.
//  Copyright © 2018 Azure Horse Creations. All rights reserved.
//

import AVFoundation
import UIKit
import VisualRecognitionV3
import SVProgressHUD
import Reachability

class ViewController: UIViewController, UIImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate {
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    let apiKey = "41T3884Bc5ufPS3fwMi-PjP4WQA_I8ZF_tfn4WIaJ_Ls"
    let version = "2018-07-17"
    var classificationResults : [String] = []
    var typeValue = String.EMPTY
    var rightCount = 0
    var wrongCount = 0
    var useCamera : Bool = false
    var timer:Timer?
    let network: NetworkManager = NetworkManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        NetworkManager.isUnreachable { _ in
            self.showNoNetworkAlert()
        }
        
        initTitleAndView(title: String.EMPTY)
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        showStartAlert()
    }
    
    /**
     Sets title and default view
     
     - Parameter title: title of view
     
     - Throws:
     
     - Returns:
     */
    func initTitleAndView(title : String) {
        navigationItem.title = title
        imageView.image = UIImage(named: "placeholder")
    }
    
    /**
     Returns number of components in vie
     
     - Parameter pickerview:
     
     - Throws:
     
     - Returns: int value of 1
     */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /**
     Returns number of rows in component
     
     - Parameter pickerView:
                numberOfRowsInComponent
     
     - Throws:
     
     - Returns: int value of 1
     */
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 1
    }
    
    /**
     Stops the progress spinner and the timer when the app times out
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    @objc func fire() {
        stopProgressAndTimer()
        showTimeoutAlert()
    }
    
    /**
      Attempts to classify the image
     
     - Parameter picker:
                info:
     
     - Throws:
     
     - Returns:
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        SVProgressHUD.show()
        
        timer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(fire), userInfo: nil, repeats: false)
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            imageView.roundCornersForAspectFit(radius: 15)
            imagePicker.dismiss(animated: true, completion: nil)
            
            self.navigationItem.title = String.THINKING
            
            let visualRecognition = VisualRecognition(version: version, apiKey: apiKey)
            let imageData = image.jpegData(compressionQuality: 0.01)
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("tempImage.jpg")
            try? imageData?.write(to: fileURL, options: [])
            let failure = { (error: Error) in print(error) }
            visualRecognition.classify(image: image, failure: failure) { classifiedImages in
                let classes = classifiedImages.images.first!.classifiers.first!.classes
                
                self.classificationResults = []
                
                for index in 0..<classes.count {
                    self.classificationResults.append(classes[index].className)
                }
                print(self.classificationResults)
                
                DispatchQueue.main.async {
                    self.stopProgressAndTimer()
                    self.navigationItem.title = String.GUESS
                    self.showGuessAlert(guess: self.classificationResults[0])
                }
            }
        } else {
            print("There was an error picking the image")
        }
    }

    /**
    Called when camera icon is tapped. Checks camera permission, and displays image.
     
     - Parameter sender:
     
     - Throws:
     
     - Returns:
     */
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        self.checkCameraPermission()
        
        self.navigationItem.title = String.EMPTY
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    /**
     Checks camera permission, and displays alert if access is denied or restricted
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
            
        // The user has previously granted access to the camera.
        case .authorized:
           return
            
        // The user has not yet been asked for camera access.
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                   return
                }
            }
            
        // denied - The user has previously denied access.
        // restricted - The user can't grant access due to restrictions.
        case .denied, .restricted:
            self.alertCameraAccessNeeded()
            return
            
        default:
            break
        }
    }
    
    /**
     Displays an alert saying that camera access is needed. Allows user to enable the camera.
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func alertCameraAccessNeeded() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        
        let alert = UIAlertController(
            title: "Need Camera Access",
            message: "Camera access is required to make full use of this app.",
            preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            self.noCameraAlert()
        }))
        alert.addAction(UIAlertAction(title: "Allow Camera", style: .cancel, handler: { (alert) -> Void in
            UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    /**
     Stops the progress spinner and timer.
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func stopProgressAndTimer() {
        SVProgressHUD.dismiss()
        timer?.invalidate()
        timer = nil
    }
    
    /**
     Displays an alert to start the guessing game
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func showStartAlert() {
        let alert = UIAlertController(title: String.EMPTY, message: String.LETS_PLAY, preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (UIAlertAction) in
            self.pickImageSourceAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Displays an alert to choose either the camera or the photo library as the image source
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func pickImageSourceAlert() {
        let alert = UIAlertController(title: String.EMPTY, message: String.CAMERA_OR_PHOTO, preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: String.CAMERA, style: .default, handler: { (UIAlertAction) in
            self.imagePicker.sourceType = .camera
            self.useCamera = true
            self.navigationItem.title = String.TAKE_A_PICTURE
        }))
        
        alert.addAction(UIAlertAction(title: String.PHOTO_LIBRARY, style: .default, handler: { (UIAlertAction) in
            self.imagePicker.sourceType = .photoLibrary
            self.useCamera = false
            self.navigationItem.title = String.SELECT_A_PICTURE
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Displays an alert to show the guess
     
     - Parameter guess: string representing the guess
     
     - Throws:
     
     - Returns:
     */
    func showGuessAlert(guess: String) {
        let alert = UIAlertController(title: String.EMPTY, message: String.IS_IT + String.SPACE + String.DOUBLE_QUOTE + guess + String.DOUBLE_QUOTE, preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: String.YES, style: .default, handler: { (UIAlertAction) in
            self.rightCount += 1
            self.showResultAlert(win: true)
        }))
        
        alert.addAction(UIAlertAction(title: String.NO, style: .default, handler: { (UIAlertAction) in
            self.wrongCount += 1
            self.showResultAlert(win: false)
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Displays an alert to announce the timeout
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func showTimeoutAlert() {
        let alert = UIAlertController(title: String.EMPTY, message: "I give up. I have NO idea what that is!", preferredStyle: .alert)
        alert.isModalInPopover = true
        self.wrongCount += 1
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (UIAlertAction) in
            self.playAgainAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Displays an alert to say there is no internet connection
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func showNoNetworkAlert() {
        let alert = UIAlertController(title: String.EMPTY, message: "Whatsit requires an internet connection", preferredStyle: .alert)
        alert.isModalInPopover = true
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (UIAlertAction) in
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Displays an alert to show the results
     
     - Parameter win: boolean value, true = win, false = lose
     
     - Throws:
     
     - Returns:
     */
    func showResultAlert(win: Bool) {
        self.navigationItem.title = String.RESULTS
        var message = String.EMPTY
        let number = Int.random(in: 0 ..< 9)
        if (win) {
            message = String.WE_WIN[number]
        } else {
            message = String.I_GUESSED_WRONG[number]
        }
        let alert = UIAlertController(title: String.EMPTY, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (UIAlertAction) in
            self.playAgainAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Displays an alert to ask if the user wants to play again
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func playAgainAlert() {
        self.navigationItem.title = String.EMPTY
        let alert = UIAlertController(title: String.EMPTY, message: String.PLAY_AGAIN, preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: String.YES, style: .default, handler: { (UIAlertAction) in
            self.initTitleAndView(title: self.useCamera ? String.TAKE_A_PICTURE : String.SELECT_A_PICTURE)
        }))
        
        alert.addAction(UIAlertAction(title: String.NO, style: .default, handler: { (UIAlertAction) in
            self.showFinalScoreAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Displays an alert to show the final score
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func showFinalScoreAlert() {
        var winMessage = String.EMPTY
        if (rightCount > wrongCount) {
            winMessage = String.WE_WON_THE_GAME
        } else if (wrongCount > rightCount) {
            winMessage = String.SORRY_ILL_DO_BETTER
        } else {
            winMessage = String.NEWLINE + String.WE_DID_OK + String.NEWLINE
        }
        let message = String.RIGHT + String.COLON + String(self.rightCount) + String.NEWLINE + String.WRONG + String.COLON + String(self.wrongCount) + String.NEWLINE + String.NEWLINE + winMessage + String.NEWLINE + String.NEWLINE + String.THANKS_FOR_PLAYING
        let alert = UIAlertController(title: String.FINAL_SCORE, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (UIAlertAction) in
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Displays an alert to say that the photo library will be used instead of the camera
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func noCameraAlert() {
        let alert = UIAlertController(title: String.EMPTY, message: "Using photo library instead", preferredStyle: .alert)
        alert.isModalInPopover = true
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (action) in
            self.usePhotoLibrary()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    /**
     Sets the image picker to use the photo libary as the source
     
     - Parameter none:
     
     - Throws:
     
     - Returns:
     */
    func usePhotoLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
}
