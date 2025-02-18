import SwiftUI

struct TimingsView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    let peripheralUUID: String

    var body: some View {
        if let diffuser = diffuserManager.findDiffuser(by: peripheralUUID) {
            let timings = diffuser.timings

            NavigationView {
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.122, green: 0.251, blue: 0.565),   // Darker blue (Top)
                            Color(red: 0.542, green: 0.678, blue: 1)        // Lighter blue (Bottom)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 10) {
                        headerView

                        // Rounded transparent background  
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.25))
                            .padding(.horizontal, 16)
                            .frame(maxHeight: 360)  // i want this to expand just a little more than the total of timing rows
                            .overlay(
                                ScrollView {
                                    VStack(spacing: 10) {
                                        ForEach(timings) { timing in
                                            NavigationLink(destination: OperationCycleView(timing: timing)) {
                                                TimingRow(timing: timing)
                                            }
                                            .buttonStyle(PlainButtonStyle())  // No chevron
                                            .padding(.horizontal, 10)
                                        }
                                    }
                                    .padding(.vertical, 20)
                                }
                            )

                        Spacer()

                        // Refresh timings button
                        Button(action: updateTimings) {
                            Text("Refresh Timings")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 20)
                    }


                }
                .onAppear {
                    updateTimings()
                }
            }
        } else {
            Text("Device not found.")
                .foregroundColor(.red)
                .font(Font.system(size: 20))
        }
    }

    private var headerView: some View {
        HStack {
            Text("Timings")  // Moved to the right
                .font(Font.custom("DIN Next LT Arabic", size: 24))
                .foregroundColor(.white)
            Spacer()
        }
        .padding([.leading, .trailing], 20)
        .padding(.top, 50)
    }

    private func updateTimings() {
        diffuserManager.updateTimings(for: peripheralUUID)
    }
}
// MARK: - Timing Row
struct TimingRow: View {
    let timing: Timing
    var body: some View {
        HStack {
            // Timing title on the right
            Text("Timing \(timing.number)")
                .font(.system(size: 16))
                .foregroundColor(.black)
                .padding(.leading, 10)
            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                // Start time
                HStack {

                    Text("Start: ")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(timing.powerOn)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }

                // Stop time
                HStack {
                    Text("Stop:")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(timing.powerOff)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
            }
            .padding(.trailing, 5)
            .padding(.leading, 5)
            
            Image(systemName: "chevron.left")
                .foregroundColor(.gray)
                .font(.system(size: 18))
                .padding(.leading, 8)

        }
        .padding(10)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
        .frame(width: UIScreen.main.bounds.width - 60)

    }
}
