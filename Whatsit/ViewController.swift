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
    var typeValue = String()
    var rightCount = 0
    var wrongCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initTitleAndView()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        showStartAlert()
    }
    
    func initTitleAndView() {
        navigationItem.title = "Take a picture"
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
            imagePicker.dismiss(animated: true, completion: nil)
            
            self.navigationItem.title = "Guess"
            
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
        self.navigationItem.title = ""
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func showStartAlert() {
        let alert = UIAlertController(title: "", message: "Let's play a game.\nYou take a picture, and I guess what it is", preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
            self.pickImageSourceAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    func pickImageSourceAlert() {
        let alert = UIAlertController(title: "", message: "Camera or photo library?", preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (UIAlertAction) in
            self.imagePicker.sourceType = .camera
        }))
        
        alert.addAction(UIAlertAction(title: "Photo library", style: .default, handler: { (UIAlertAction) in
            self.imagePicker.sourceType = .photoLibrary
        }))
        self.navigationItem.title = "Take a picture"
        self.present(alert,animated: true, completion: nil )
    }
    
    func showGuessAlert(guess: String) {
        let alert = UIAlertController(title: "", message: "Is it \"" + guess + "\"?", preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
            self.rightCount += 1
            self.showResultAlert(win: true)
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (UIAlertAction) in
            self.wrongCount += 1
            self.showResultAlert(win: false)
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    func showResultAlert(win: Bool) {
        var message : String = ""
        if (win) {
            message = "We win!"
        } else {
            message = "I guessed wrong!"
        }
        let alert = UIAlertController(title: "Results", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
            self.playAgainAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    func playAgainAlert() {
        let alert = UIAlertController(title: "Results", message: "Do you want to play again?", preferredStyle: .alert)
        alert.isModalInPopover = true
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
            self.initTitleAndView()
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (UIAlertAction) in
            self.showFinalScoreAlert()
        }))
        self.present(alert,animated: true, completion: nil )
    }
    
    func showFinalScoreAlert() {
        var winMessage : String = ""
        if (rightCount > wrongCount) {
            winMessage = "\nWe won the game! Great job!\n"
        } else if (wrongCount > rightCount) {
            winMessage = "\nSorry! I'll try to do better next time.\n"
        } else {
            winMessage = "\nWe did ok!\n"
        }
        let message = "Right: " + String(self.rightCount) + "\nWrong: " + String(self.wrongCount) + winMessage + "\nThanks for playing!"
        let alert = UIAlertController(title: "Final score", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
        }))
        self.present(alert,animated: true, completion: nil )
    }
}
