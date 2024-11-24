//
//  Untitled.swift
//  Aromatic smart
//
//  Created by عارف on 24/11/2024.
//
import SwiftUI

struct DiffusingIntensityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diffusing Intensity")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Choose the Diffusing Intensity for your program")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
    }
    
}








struct DIView_Previews: PreviewProvider {
    static var previews: some View {
        DiffusingIntensityView()
    }
}
