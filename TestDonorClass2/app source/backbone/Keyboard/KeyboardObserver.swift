//
//  File.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 7/20/25.
//
import SwiftUI
import UIKit

// MARK: - Keyboard Observer Class
@MainActor
@Observable
final class KeyboardObserver {
    var isKeyboardVisible = false

    init() {
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        // A hardware keyboard will report a small or zero height for the keyboard frame.
        // We check if the height is substantial enough to be the on-screen keyboard.
        // A threshold of 100 points should be safe enough to ignore accessory views.
        guard keyboardFrame.height > 100 else { return }
        setKeyboardVisible(true)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        setKeyboardVisible(false)
    }

    // Keyboard notifications can arrive synchronously while SwiftUI is mid-render
    // (e.g. a text field becoming first responder), so defer the mutation one
    // runloop tick to stay out of the current view update transaction.
    private func setKeyboardVisible(_ visible: Bool) {
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = visible
            }
        }
    }
}
