import SwiftUI
import AuthenticationServices

/// SignInView — Sign in with Apple screen.
/// Clean, simple, one-button authentication.
/// Shows after disclaimer, before the app content.
struct SignInView: View {
    @StateObject private var auth = AuthService.shared
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.04, blue: 0.12),
                    Color(red: 0.1, green: 0.06, blue: 0.16),
                    Color(red: 0.04, green: 0.03, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // App icon/logo area
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(red: 0.7, green: 0.4, blue: 0.8).opacity(0.2), Color.clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "waveform.and.mic")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.7, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.3, blue: 0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("MySoulSpeak")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.white)

                    Text("Your spiritual wellness companion")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Benefits
                VStack(alignment: .leading, spacing: 14) {
                    benefitRow(icon: "icloud.fill", text: "Sync across all your devices")
                    benefitRow(icon: "lock.shield.fill", text: "Your data stays private and secure")
                    benefitRow(icon: "person.crop.circle.fill", text: "Personalized AI that remembers you")
                }
                .padding(.horizontal, 40)

                Spacer()

                // Sign in with Apple button
                SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleResult)
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .cornerRadius(27)
                    .padding(.horizontal, 40)

                // Skip option (for testing/review)
                Button(action: skipSignIn) {
                    Text("Continue without signing in")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.top, 8)

                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
    }

    // MARK: - Benefit Row
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.7, green: 0.4, blue: 0.8))
                .frame(width: 28)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Apple Sign In
    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        auth.handleSignInResult(result)

        if case .failure(let error) = result {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func skipSignIn() {
        // Allow use without sign-in (data won't sync across devices)
        auth.isSignedIn = true // Treat as "signed in" locally
        UserDefaults.standard.set("local_user", forKey: "mysoulspeak_apple_user_id")
    }
}
