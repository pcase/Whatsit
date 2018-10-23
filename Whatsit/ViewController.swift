//
//  ViewController.swift
//  Whatsit
//
//  Created by Patty Case on 10/20/18.
//  Copyright © 2018 Azure Horse Creations. All rights reserved.
//

import UIKit
import VisualRecognitionV3
import SVProgressHUD

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initTitleAndView()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        showStartAlert()
    }
    
    func initTitleAndView() {
        if (useCamera) {
            navigationItem.title = String.TAKE_A_PICTURE
        } else {
            navigationItem.title = String.SELECT_A_PICTURE
        }
        imageView.image = UIImage(named: "placeholder")
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 1
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        SVProgressHUD.show()
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            imageView.roundCornersForAspectFit(radius: 15)
            imagePicker.dismiss(animated: true, completion: nil)
            
            self.navigationItem.title = String.GUESS
            
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
                    SVProgressHUD.dismiss()
                    self.showGuessAlert(guess: self.classificationResults[0])
                }
            }
        } else {
            print("There was an error picking the image")
        }
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        self.navigationItem.title = String.EMPTY
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func showStartAlert() {
        let alert = UIAlertController(title: String.EMPTY, message: String.LETS_PLAY, preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (UIAlertAction) in
            self.pickImageSourceAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
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
    
    func showResultAlert(win: Bool) {
        var message = String.EMPTY
        if (win) {
            message = String.WE_WIN
        } else {
            message = String.I_GUESSED_WRONG
        }
        let alert = UIAlertController(title: String.EMPTY, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (UIAlertAction) in
            self.playAgainAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    func playAgainAlert() {
        let alert = UIAlertController(title: String.EMPTY, message: String.PLAY_AGAIN, preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: String.YES, style: .default, handler: { (UIAlertAction) in
            self.initTitleAndView()
        }))
        
        alert.addAction(UIAlertAction(title: String.NO, style: .default, handler: { (UIAlertAction) in
            self.showFinalScoreAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    func showFinalScoreAlert() {
        var winMessage = String.EMPTY
        if (rightCount > wrongCount) {
            winMessage = String.WE_WON_THE_GAME
        } else if (wrongCount > rightCount) {
            winMessage = String.SORRY_ILL_DO_BETTER
        } else {
            winMessage = String.NEWLINE + String.WE_DID_OK + String.NEWLINE
        }
        let message = String.RIGHT + String.COLON + String(self.rightCount) + String.NEWLINE + String.WRONG + String.COLON + String(self.wrongCount) + String.NEWLINE + winMessage + String.NEWLINE + String.THANKS_FOR_PLAYING
        let alert = UIAlertController(title: String.FINAL_SCORE, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.OK, style: .default, handler: { (UIAlertAction) in
        }))
        self.present(alert,animated: true, completion: nil )
    }
}
