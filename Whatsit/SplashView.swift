//
//  SplashView.swift
//  Whatsit
//
//  Created by Patty Case on 1/23/22.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        Image(uiImage: UIImage(named: "azurehorsecreations")!)
            .resizable()
            .scaledToFit()
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
