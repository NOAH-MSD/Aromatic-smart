import SwiftUI

struct TimingCardView: View {
    var title: String
    var startTime: String
    var endTime: String
    
    var body: some View {
        HStack {
            // Left Icon
            Image(systemName: "chevron.left")
                .foregroundColor(.gray)
                .font(.system(size: 18))
                .padding(.leading, 10)
            
            // Time Information and Title
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(startTime)
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Text("تشغيل") // "Start"
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(endTime)
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Text("إيقاف") // "Stop"
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                // Title
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.top, 4)
            }
            .padding(.vertical, 10)
            
            Spacer() // Push content to the left
        }
        .background(
            RoundedRectangle(cornerRadius: 20)  // Adjusted for smoother rounding
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)  // Softer shadow
        )
        .padding(.horizontal, 16)
    }
}

struct ContentViewz: View {
    var body: some View {
        ZStack {
            // Updated Gradient Background
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {  // Reduced spacing between cards
                TimingCardView(title: "Timing 1", startTime: "08:00", endTime: "20:00")
                TimingCardView(title: "Timing 2", startTime: "00:00", endTime: "00:00")
                TimingCardView(title: "Timing 3", startTime: "00:00", endTime: "00:00")
                
            }
            .padding(.top, 40)  // Center cards on screen
        }
    }
}

struct ContentView_Previewsz: PreviewProvider {
    static var previews: some View {
        ContentViewz()
    }
}

