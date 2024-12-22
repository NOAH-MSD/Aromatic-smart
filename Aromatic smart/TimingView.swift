import SwiftUI
import SwiftData

struct TimingView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    let peripheralUUID: String

    var body: some View {
        NavigationView {
            // Find the diffuser by peripheralUUID
            if let diffuser = diffuserManager.findDiffuser(by: peripheralUUID) {
                // Fetch the diffuser’s timings
                let timings = diffuser.timings

                List(timings) { timing in
                    NavigationLink(
                        destination: {
                            // Pass a single Timing to OperationCycleView
                            OperationCycleView(timing: timing)
                        }
                    ) {
                        TimingRow(timing: timing)
                    }
                }
                .navigationTitle("Timings")
            } else {
                // If no Diffuser is found for this peripheralUUID
                Text("No diffuser found for this peripheral.")
                    .foregroundColor(.gray)
                    .navigationTitle("Timings")
            }
        }
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
