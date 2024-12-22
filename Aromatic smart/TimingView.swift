import SwiftUI
import SwiftData

struct TimingView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    let peripheralUUID: String

    var body: some View {
        NavigationView {
            List {
                if let timings = diffuserManager.diffuserTimings[peripheralUUID] {
                    ForEach(timings) { timing in
                        NavigationLink(destination: OperationCycleView(diffuser: createDiffuser(for: timing))) {
                            TimingRow(timing: timing)
                        }
                    }
                } else {
                    Text("No timings found for this diffuser.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Timings")
        }
    }

    private func createDiffuser(for timing: Timing) -> Diffuser {
        let diffuser = Diffuser(
            name: "Timing \(timing.number)",
            isConnected: true,
            modelNumber: "AF300",
            serialNumber: "123ABC",
            timerSetting: timing.number
        )
        diffuser.powerOn = timing.powerOn
        diffuser.powerOff = timing.powerOff
        diffuser.daysOfOperation = timing.daysOfOperation
        diffuser.gradeMode = timing.gradeMode
        diffuser.grade = timing.grade
        diffuser.customWorkTime = timing.customWorkTime
        diffuser.customPauseTime = timing.customPauseTime
        return diffuser
    }
}

// A simple view to show each timing in the list
struct TimingRow: View {
    let timing: Timing

    var body: some View {
        HStack {
            Text("Timing \(timing.number)")
                .font(.headline)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("On: \(timing.powerOn)").font(.subheadline).foregroundColor(.gray)
                Text("Off: \(timing.powerOff)").font(.subheadline).foregroundColor(.gray)
            }
        }
    }
}


