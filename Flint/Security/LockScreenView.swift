import SwiftUI

struct LockScreenView: View {
    @Environment(AuthenticationManager.self) var auth
    @State private var showPINEntry = false

    var body: some View {
        ZStack {
            Color.flintBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.flintSpark)

                Text("Flint")
                    .font(.flintDisplay(28))
                    .foregroundStyle(Color.flintText)

                Text("Authenticate to access your data")
                    .font(.flintBody(14))
                    .foregroundStyle(Color.flintGrey)

                if auth.isLockedOut {
                    Text("Too many attempts. Try again in \(auth.lockoutTimeRemaining)")
                        .foregroundStyle(Color.flintDanger)
                        .font(.flintBody(13))
                } else if showPINEntry {
                    PINEntryView { pin in
                        auth.authenticateWithPIN(pin)
                    }
                }

                Spacer()

                if !showPINEntry && !auth.isLockedOut {
                    Button("Use PIN Instead") {
                        showPINEntry = true
                    }
                    .foregroundStyle(Color.flintGrey)
                    .font(.flintBody(14))
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            _ = await auth.authenticateWithBiometrics()
        }
    }
}

// MARK: - PIN Entry View

struct PINEntryView: View {
    let onComplete: (String) -> Bool
    @State private var pin: String = ""
    @State private var shake = false
    private let pinLength = 6

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter PIN")
                .font(.flintBody(17, weight: .semibold))
                .foregroundColor(.flintText)

            // Dot indicators
            HStack(spacing: 12) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.flintSpark : Color.flintBorder)
                        .frame(width: 14, height: 14)
                        .scaleEffect(index < pin.count ? 1.1 : 1.0)
                        .animation(.spring(duration: 0.2), value: pin.count)
                }
            }
            .offset(x: shake ? 10 : 0)

            // Number pad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(1...9, id: \.self) { number in
                    PINButton(label: "\(number)") {
                        appendDigit("\(number)")
                    }
                }

                // Bottom row
                PINButton(label: "face.smiling", isSymbol: true) {
                    Task { _ = await AuthenticationManager().authenticateWithBiometrics() }
                }
                PINButton(label: "0") {
                    appendDigit("0")
                }
                PINButton(label: "delete.left", isSymbol: true) {
                    if !pin.isEmpty { pin.removeLast() }
                }
            }
            .padding(.horizontal, 40)
        }
    }

    private func appendDigit(_ digit: String) {
        guard pin.count < pinLength else { return }
        pin += digit

        if pin.count == pinLength {
            let success = onComplete(pin)
            if !success {
                withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                    shake = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    shake = false
                    pin = ""
                }
            }
        }
    }
}

struct PINButton: View {
    let label: String
    var isSymbol: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.flintSurface)
                    .frame(width: 70, height: 70)

                if isSymbol {
                    Image(systemName: label)
                        .font(.title2)
                        .foregroundColor(.flintText)
                } else {
                    Text(label)
                        .font(.flintDisplay(24))
                        .foregroundColor(.flintText)
                }
            }
        }
    }
}
