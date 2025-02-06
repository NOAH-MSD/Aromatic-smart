import SwiftUI
import SwiftData

struct TimingView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    let peripheralUUID: String

    var body: some View {
        NavigationView {
            VStack {
                // Refresh button
                Button(action: refreshTimings) {
                    Text("Refresh Timings")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()

                // Find the diffuser by peripheralUUID
                if let diffuser = diffuserManager.findDiffuser(by: peripheralUUID) {
                    let timings = diffuser.timings

                    List(timings) { timing in
                        NavigationLink(destination: OperationCycleView(timing: timing)) {
                            TimingRow(timing: timing)
                        }
                    }
                    .navigationTitle("Timings")
                } else {
                    Text("No diffuser found for this peripheral.")
                        .foregroundColor(.gray)
                        .navigationTitle("Timings")
                }
            }        .onAppear {
                    refreshTimings()
                  }
        }
    }

    // Function to refresh timings using diffuserManager
    private func refreshTimings() {
        diffuserManager.updateTimings(for: peripheralUUID)
    }
}

// A simple row to display each timing’s basic info
struct TimingRow: View {
    let timing: Timing

    var body: some View {
        HStack {
            Text("Timing \(timing.number)")
                .font(.headline)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("On: \(timing.powerOn)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Off: \(timing.powerOff)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}
