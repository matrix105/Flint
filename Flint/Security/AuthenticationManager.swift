import LocalAuthentication
import CryptoKit
import SwiftUI

@MainActor
@Observable
class AuthenticationManager {
    var isUnlocked = false
    var failedAttempts = 0
    var isLockedOut = false
    var lockoutEndTime: Date?
    var hasPIN: Bool { KeychainManager.hasPIN }

    private let maxAttempts = 5
    private let lockoutDuration: TimeInterval = 1800 // 30 minutes

    var lockoutTimeRemaining: String {
        guard let endTime = lockoutEndTime else { return "" }
        let remaining = max(0, endTime.timeIntervalSinceNow)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Flint to access your nutrition data"
            )
            if success {
                isUnlocked = true
            }
            return success
        } catch {
            return false
        }
    }

    // MARK: - PIN Authentication

    func authenticateWithPIN(_ enteredPIN: String) -> Bool {
        guard !isLockedOut else { return false }

        let enteredHash = hashPIN(enteredPIN)

        do {
            let storedData = try KeychainManager.load(key: "user_pin_hash")
            let storedHash = String(data: storedData, encoding: .utf8) ?? ""

            if enteredHash == storedHash {
                failedAttempts = 0
                isUnlocked = true
                return true
            }
        } catch {
            // No PIN stored
        }

        failedAttempts += 1
        if failedAttempts >= maxAttempts {
            triggerLockout()
        }
        return false
    }

    // MARK: - PIN Setup

    func setupPIN(_ pin: String) {
        let hash = hashPIN(pin)
        try? KeychainManager.save(key: "user_pin_hash", data: Data(hash.utf8))
    }

    // MARK: - Lock

    func lock() {
        isUnlocked = false
    }

    // MARK: - Helpers

    private func hashPIN(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func triggerLockout() {
        isLockedOut = true
        lockoutEndTime = Date().addingTimeInterval(lockoutDuration)
        Task {
            try? await Task.sleep(for: .seconds(lockoutDuration))
            isLockedOut = false
            failedAttempts = 0
        }
    }
}

extension KeychainManager {
    static var hasPIN: Bool {
        (try? load(key: "user_pin_hash")) != nil
    }
}
