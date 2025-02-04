import SwiftUI
import SwiftData

struct MainView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Query var diffusers: [Diffuser]

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.122, green: 0.251, blue: 0.565),   // Darker blue (Top)
                    Color(red: 0.542, green: 0.678, blue: 1)        // Lighter blue (Bottom)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            dotsBackground

            // Fixed logo at the top using alignment
            VStack {
                logoView
                    .padding(.top, 3)  // Adjust this to control the top spacing
                Spacer()  // Pushes content below the logo
            }

            // Main content (noDevicesView or scroll view)
            VStack(spacing: 20) {
                if diffusers.isEmpty {
                    noDevicesView
                } else {
                    devicesScrollView
                }
            }
            .padding(.top, 150)  // Ensures main content starts below the fixed logo

            // Floating button
            floatingAddButton
            
        }
    }
}









// MARK: - Subviews
extension MainView {
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            Button(action: {
                // Navigation logic (replace with actual NavigationLink if needed)
            }) {
                NavigationLink(destination: PairDeviceView()) {
                    HStack {
                        Text("أضف جهازك الآن")
                            .font(Font.custom("DIN Next LT Arabic", size: 18))
                            .foregroundColor(.white)

                        Image(systemName: "arrow.forward.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 20)
                    .frame(width: 309, height: 53)  // Button dimensions
                    .background(Color(red: 0.102, green: 0.259, blue: 0.541))
                    .cornerRadius(25)
                    .shadow(radius: 5)
                }
            }
            .padding(.top, -70)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var logoView: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(width: 140, height: 140)
    }

    private var noDevicesView: some View {
        VStack(spacing: 5) {
            Text("مرحباً بك في تطبيق أروماتك ..")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .font(Font.custom("DIN Next LT Arabic", size: 20))
                .padding(.bottom, 4)
            

            Text("أنت على بُعد خطوات من الاستمتاع بروائح أروماتك الساحرة")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .font(Font.custom("DIN Next LT Arabic", size: 20))
                

            Image("devices")
                .resizable()
                .scaledToFit()
                .padding(.top, 10)
        }
        .padding(.top, -40)
    }

    private var devicesScrollView: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(diffusers) { diffuser in
                    DiffuserCard(diffuser: diffuser)
                        .frame(width: UIScreen.main.bounds.width - 40, height: 410)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                }
            }
        }
    }
}


// MARK: - Subviews

private var dotsBackground: some View {
    ZStack {
        // green dot
        Circle()
            .fill(Color.green)
            .frame(width: 4, height: 4)
            .offset(x: -100, y: -50)

        // yello dot (small)
        Circle()
            .fill(Color.yellow)
            .frame(width: 8, height: 8)
            .offset(x: -60, y: -10)

        // bluw dot
        Circle()
            .fill(Color(red: 0.67, green: 1.0, blue: 1.0))  // #7FFCAA - Light Blue
            .frame(width: 4, height: 4)
            .offset(x: 1, y: 5)

        // pink dot (small)
        Circle()
            .fill(Color(red: 1.0, green: 0.67, blue: 0.67))  // #FF7CAA - Pink
            .frame(width: 10, height: 10)
            .offset(x: 60, y: -25)
    }
}
