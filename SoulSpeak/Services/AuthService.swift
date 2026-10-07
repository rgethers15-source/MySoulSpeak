import Foundation
import AuthenticationServices
import SwiftUI

/// AuthService — Handles Sign in with Apple authentication.
/// Stores user credential in Keychain for persistent login.
/// User can sign in once and stay logged in across sessions.
@MainActor
class AuthService: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userID: String = ""

    static let shared = AuthService()

    private let userIDKey = "mysoulspeak_apple_user_id"
    private let userNameKey = "mysoulspeak_user_name"
    private let userEmailKey = "mysoulspeak_user_email"

    init() {
        // Check if user is already signed in
        checkExistingCredential()
    }

    // MARK: - Check Existing Login

    private func checkExistingCredential() {
        guard let savedUserID = UserDefaults.standard.string(forKey: userIDKey),
              !savedUserID.isEmpty else {
            isSignedIn = false
            return
        }

        // Verify the credential is still valid with Apple
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: savedUserID) { [weak self] state, _ in
            Task { @MainActor [weak self] in
                switch state {
                case .authorized:
                    self?.userID = savedUserID
                    self?.userName = UserDefaults.standard.string(forKey: self?.userNameKey ?? "") ?? ""
                    self?.userEmail = UserDefaults.standard.string(forKey: self?.userEmailKey ?? "") ?? ""
                    self?.isSignedIn = true
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Handle Sign In Result

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

            userID = credential.user

            // Name and email are only provided on FIRST sign-in
            if let fullName = credential.fullName {
                let firstName = fullName.givenName ?? ""
                let lastName = fullName.familyName ?? ""
                userName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            }

            if let email = credential.email {
                userEmail = email
            }

            // Save to UserDefaults
            UserDefaults.standard.set(userID, forKey: userIDKey)
            if !userName.isEmpty {
                UserDefaults.standard.set(userName, forKey: userNameKey)
            }
            if !userEmail.isEmpty {
                UserDefaults.standard.set(userEmail, forKey: userEmailKey)
            }

            isSignedIn = true
            print("[MySoulSpeak Auth] Signed in: \(userName) (\(userID))")

        case .failure(let error):
            print("[MySoulSpeak Auth] Sign in failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign Out

    func signOut() {
        userID = ""
        userName = ""
        userEmail = ""
        isSignedIn = false

        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)

        print("[MySoulSpeak Auth] Signed out")
    }

    // MARK: - Display Name

    var displayName: String {
        if !userName.isEmpty {
            return userName
        } else if !userEmail.isEmpty {
            return userEmail
        } else {
            return "User"
        }
    }
}
