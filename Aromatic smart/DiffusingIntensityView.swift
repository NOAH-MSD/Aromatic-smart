//
//  Untitled.swift
//  Aromatic smart
//
//  Created by عارف on 24/11/2024.
//
import SwiftUI

struct DiffusingIntensityView: View {
    @State private var selectedIntencity: Intencities = .LOW
    
    enum Intencities: String, CaseIterable, Identifiable {
        case Jet , HIGH , MID , LOW
        var id: Self { self }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diffusing Intensity")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading).padding()
            Text("Choose the Diffusing Intensity for your program")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading).padding()
           
            
            HStack{
                Spacer()
                Button(action: {
                    print("action")
                }) {
                    Text("Auto")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    Image(systemName: "fan.badge.automatic.fill")
                }
                Spacer()
            }
            
            
            Picker("Intencity", selection: $selectedIntencity) {
                ForEach(Intencities.allCases) { Intencity in
                    Text(Intencity.rawValue.capitalized)
                    
                }
                
            }.pickerStyle(.segmented).padding()
            
        Spacer()
        }//v
    }
    
    
    
}








struct DIView_Previews: PreviewProvider {
    static var previews: some View {
        DiffusingIntensityView()
    }
}
