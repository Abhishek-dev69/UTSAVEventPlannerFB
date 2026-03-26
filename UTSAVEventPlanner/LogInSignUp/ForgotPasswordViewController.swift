// ForgotPasswordViewController.swift
// UTSAV
// Simple Forgot Password screen: enter email -> send reset request (placeholder).

import UIKit

final class ForgotPasswordViewController: UIViewController {

    private let stack = UIStackView()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let emailTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .medium)

    private let edge: CGFloat = 20
    private let fieldH: CGFloat = 52

    private let gradientLayer = CAGradientLayer() // Added for brand gradient

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        view.backgroundColor = .systemBackground
        
        setupUTSAVNavbar(title: "Reset password") // Replaced setupNavigationItems()
        setupViews()
        layoutViews()
        styleViews()
        hookEvents()
        updateSendEnabled(isValid: false)
    }

    // MARK: - Navigation
    private func setupNavigationItems() {
        // navigationItem.title = "Reset password" // now handled by setupUTSAVNavbar

        // If this VC is not inside a UINavigationController (presented modally),
        // provide a close/dismiss button on the left so user can close the modal.
        if navigationController == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeTapped)
            )
        }
        // If it's pushed on a nav stack, the system-provided back button will appear automatically.
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    // Convenience factory: call `present(ForgotPasswordViewController.makeModal(), animated: true)`
    // from other VCs if you want it modal with a nav bar.
    static func makeModal() -> UINavigationController {
        let vc = ForgotPasswordViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        return nav
    }

    // MARK: - Views
    private func setupViews() {
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        view.addSubview(stack)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(titleLabel)

        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(infoLabel)

        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(emailTextField)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(sendButton)

        activity.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addSubview(activity)
        activity.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor).isActive = true
        activity.trailingAnchor.constraint(equalTo: sendButton.trailingAnchor, constant: -14).isActive = true
    }

    private func layoutViews() {
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edge),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -edge),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32)
        ])

        emailTextField.heightAnchor.constraint(equalToConstant: fieldH).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: fieldH).isActive = true
    }

    private func styleViews() {
        titleLabel.text = "Forgot your password?"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label

        infoLabel.text = "Enter the email associated with your account. We'll send a password reset link if the email exists."
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0

        emailTextField.placeholder = "Email address"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.backgroundColor = .secondarySystemBackground
        emailTextField.layer.cornerRadius = 12
        emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        emailTextField.leftViewMode = .always
        emailTextField.clearButtonMode = .whileEditing

        // SEND BUTTON (color: #8B3BF0)
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Send reset link"
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
        cfg.baseBackgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1)
        cfg.baseForegroundColor = .white
        sendButton.configuration = cfg
        sendButton.layer.cornerRadius = 12
        sendButton.layer.masksToBounds = true
    }

    private func hookEvents() {
        emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }

    @objc private func emailChanged() {
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        updateSendEnabled(isValid: validateEmail(email))
    }

    private func updateSendEnabled(isValid: Bool) {
        sendButton.isEnabled = isValid
        sendButton.alpha = isValid ? 1.0 : 0.6
    }

    @objc private func sendTapped() {
        view.endEditing(true)
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard validateEmail(email) else {
            showAlert(title: "Invalid email", message: "Please enter a valid email address.")
            return
        }

        setLoading(true)

        Task {
            do {
                // If you want the reset link to deep-link back into your app, set redirectTo accordingly.
                // Make sure the redirect URL is added in Supabase Auth Settings and Info.plist URL Types.
                let redirectTo = "utsav://callback/reset-password" // optional, or use nil
                try await SupabaseManager.shared.sendPasswordResetEmail(email: email, redirectTo: redirectTo)

                await MainActor.run {
                    self.setLoading(false)
                    let a = UIAlertController(
                        title: "Email sent",
                        message: "If an account exists for \(email) you'll receive a password reset email shortly.",
                        preferredStyle: .alert
                    )
                    a.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        if let nav = self.navigationController {
                            nav.popViewController(animated: true)
                        } else {
                            self.dismiss(animated: true)
                        }
                    })
                    self.present(a, animated: true)
                }
            } catch {
                // Show helpful error
                await MainActor.run {
                    self.setLoading(false)
                    let errMsg = (error as NSError).localizedDescription
                    self.showAlert(title: "Error sending reset email", message: errMsg)
                }
            }
        }
    }
    private func setLoading(_ loading: Bool) {
        sendButton.isEnabled = !loading
        if loading {
            activity.startAnimating()
        } else {
            activity.stopAnimating()
        }
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func validateEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(location: 0, length: email.utf16.count)
        return re?.firstMatch(in: email, options: [], range: range) != nil
    }
}
