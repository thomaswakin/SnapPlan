//
//  CelebrationView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/29/23.
//

import SwiftUI

struct CelebrationView: View {
    var phrase: String
    var symbol: String
    
    var body: some View {
        VStack {
            Text(phrase)
                .font(.largeTitle)
                .bold()
            Image(systemName: symbol)
                .resizable()
                .frame(width: 50, height: 50)
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(15)
    }
}
