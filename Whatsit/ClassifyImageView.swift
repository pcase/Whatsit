//
//  SignatureImageView.swift
//  Whatsit
//
//  Created by Patty Case on 12/11/21.
//

import SwiftUI

struct ClassifyImageView: View {
    @ObservedObject private var viewModel = ClassifyViewModel()
    @State private var showPhotoLibrary = false
    @State private var showCamera = false
    @State private var classificationLabel: String = ""
    @State private var image: UIImage?
    @State private var imageSource = "library"
    @State private var selectedSource = 0
    @State private var opacityIndex = 0
    
    var body: some View {
        VStack {
            Image(uiImage: self.image ?? UIImage(named: "placeholder")!)
                .resizable()
                .scaledToFit()
                .frame(minWidth: 0, maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            Button(action: {
                classificationLabel = ""
                if selectedSource == 0 {
                    self.showPhotoLibrary = true
                    self.showCamera = false
                } else {
                    self.showPhotoLibrary = false
                    self.showCamera = true
                }
            }) {
                Text("Select Image")
            }
            
            Spacer()
                .frame(height: 30)
            
            Button(action: {
                classificationLabel = viewModel.classifyImage(image: image)
            }) {
              Text("Classify")
            }
            .disabled(image == nil)

            if classificationLabel.count > 0 {
                Text(classificationLabel)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue, lineWidth: 4)
                    )
            }
            
            Spacer()
            
            Picker("", selection: $selectedSource) {
                Text("Photo Library")
                .tag(0)
                .padding(.vertical, 10)
                .padding(.horizontal, 35)
                .background((Color.white).opacity(self.opacityIndex == 0 ? 1 : 0))
                .clipShape(Capsule())
                .onTapGesture {
                   self.opacityIndex = 0
                }
                Text("Camera")
                .tag(1)
                .padding(.vertical, 10)
                .padding(.horizontal, 35)
                .background((Color.white).opacity(self.opacityIndex == 0 ? 1 : 0))
                .clipShape(Capsule())
                .onTapGesture {
                    self.opacityIndex = 0
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: self.$image)
        }
    }
}
