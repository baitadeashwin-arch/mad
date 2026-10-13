import SwiftUI

struct LoginView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var showErrorAlert = false
    @State private var email = ""
    @State private var password = ""
    @State private var resetSent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 40)
                VStack(spacing: 8) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .accessibilityLabel("AntiSocial logo")
                    Text("app-name")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                    Text("app-subtitle")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(14)
                        .accessibilityLabel("Email")
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(14)
                        .accessibilityLabel("Password")

                    Button {
                        Task { await authenticate { await loginViewModel.signIn(email: email, password: password) } }
                    } label: {
                        Text("Log In")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: AppColor.appColors, startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .disabled(loginViewModel.isLoading || email.isBlank || password.isBlank)
                    .accessibilityLabel("Log In")

                    Button("Forgot password?") {
                        Task {
                            await loginViewModel.resetPassword(email: email)
                            resetSent = loginViewModel.loginError == nil
                            if loginViewModel.loginError != nil { showErrorAlert = true }
                        }
                    }
                    .font(.footnote)
                }
                .padding(.horizontal, 24)

                Button {
                    Task { await authenticate { await loginViewModel.signIn(controller: getRootViewController()) } }
                } label: {
                    HStack {
                        Image("icons8-google-48")
                            .resizable()
                            .frame(width: 22, height: 22)
                        Text("sign-in-google")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)

                NavigationLink(destination: CreateProfileView()) {
                    Text("create-account")
                        .font(.headline)
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .overlay {
            if loginViewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.15))
            }
        }
        .alert("error", isPresented: $showErrorAlert, actions: {
            Button("cancel", role: .cancel) { }
        }, message: {
            Text(loginViewModel.loginError ?? "")
        })
        .alert("Check your email", isPresented: $resetSent, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text("If an account exists, a reset link is on its way.")
        })
    }

    private func authenticate(_ work: () async -> Void) async {
        await work()
        if loginViewModel.loginError != nil {
            showErrorAlert = true
        } else {
            contentViewModel.updateAuthState()
        }
    }
}

extension View {
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }
        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        return root
    }
}
