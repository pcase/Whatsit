//
//  ClassifyViewModel.swift.swift
//  Whatsit
//
//  Created by Patty Case on 12/11/21.
//

import SwiftUI
import CoreML

class ClassifyViewModel: ObservableObject {
    
    //TODO init() is deprecated. Use init(configuration:) instead
    let model = MobileNetV2()
    
    func classifyImage(image: UIImage?) -> String {
        var result: String = ""
        guard let image = image,
              let resizedImage = image.resizeImageTo(size: CGSize(width: 224, height: 224)),
              let buffer = resizedImage.convertToBuffer() else {
                  return result
              }
        let output = try? model.prediction(image: buffer)
        
        if let output = output {
            let results = output.classLabelProbs.sorted { $0.1 > $1.1 }
            
            // Get the top 3 results
            result = results[0..<3].map { (key, value) in
                return "\(key) = \(String(format: "%.2f", value * 100))%"
            }.joined(separator: "\n")
        }
        return result
    }
    
    func classifyImage(imageName: String) -> String {
        var result: String = ""
        guard let image = UIImage(named: imageName),
              let resizedImage = image.resizeImageTo(size: CGSize(width: 224, height: 224)),
              let buffer = resizedImage.convertToBuffer() else {
                  return result
              }
        let output = try? model.prediction(image: buffer)
        
        if let output = output {
            let results = output.classLabelProbs.sorted { $0.1 > $1.1 }
            
            result = results.map { (key, value) in
                return "\(key) = \(String(format: "%.2f", value * 100))%"
            }.joined(separator: "\n")
        }
        return result
    }
}
