import SwiftUI

struct UserProfileView: View {
    var body: some View {
        VStack(spacing: 50) {
            // Profile Picture
            Image("profile") // Replace with actual image name or make dynamic
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                .shadow(radius: 10)
                .padding(.top, 20)

            // معلومات المستخدم
            // معلومات المستخدم
            VStack(alignment: .leading, spacing: 12) {
                UserInfoRow(label: "الاسم", value: "أبو ورد")
                UserInfoRow(label: "البريد الإلكتروني", value: "abo.ward@aromaticfamilies.com")
                UserInfoRow(label: "رقم الهاتف", value: "+123 456 7890")
                UserInfoRow(label: "العنوان", value: "123 Main St, المدينة، الدولة")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
            .padding(.horizontal, 20)

            Spacer()
            
            // Logout Button
            Button(action: {
                // Logout action here
                print("User logged out")
            }) {
                Text("تسجيل الخروج")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// A helper view for displaying a row of user info
struct UserInfoRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack {
            Spacer() // This pushes the text to the right
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
            Text(label + ":")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
