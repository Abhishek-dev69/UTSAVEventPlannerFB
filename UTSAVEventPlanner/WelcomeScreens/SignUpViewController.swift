import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBrandGradient()
        titleLabel.text = "Create your Account"

        configurePlaceholdersAndInputTypes()
        styleTextFields()          // ✅ glass + clear spacing
        addPasswordToggleIcons()
        styleNextButton()
        setupKeyboardDismiss()
        setDelegates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }

    // MARK: - Placeholders & input types
    private func configurePlaceholdersAndInputTypes() {
        [emailTextField, fullNameTextField, passwordTextField, confirmPasswordTextField].forEach { $0?.text = nil }

        emailTextField.placeholder = "Email"
        fullNameTextField.placeholder = "Full Name"
        passwordTextField.placeholder = "Password"
        confirmPasswordTextField.placeholder = "Confirm Password"

        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.textContentType = .emailAddress

        fullNameTextField.autocapitalizationType = .words
        fullNameTextField.autocorrectionType = .no
        fullNameTextField.textContentType = .name

        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .oneTimeCode
        passwordTextField.autocorrectionType = .no
        passwordTextField.autocapitalizationType = .none

        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.textContentType = .oneTimeCode
        confirmPasswordTextField.autocorrectionType = .no
        confirmPasswordTextField.autocapitalizationType = .none
    }

    // MARK: - Styling (GLASS + SHADOW + BIGGER SPACING)
    private func styleTextFields() {
        let tfs = [emailTextField, fullNameTextField, passwordTextField, confirmPasswordTextField]

        for tf in tfs.compactMap({ $0 }) {

            tf.borderStyle = .none
            tf.backgroundColor = UIColor.white.withAlphaComponent(0.20)
            tf.layer.cornerRadius = 12
            tf.clipsToBounds = true

            // ✅ Clear visible spacing (18px)
            let spacer = UIView()
            spacer.backgroundColor = .clear
            tf.addSubview(spacer)
            spacer.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                spacer.topAnchor.constraint(equalTo: tf.bottomAnchor),
                spacer.heightAnchor.constraint(equalToConstant: 18)
            ])

            // ----- GLASS BLUR EFFECT -----
            let blur = UIBlurEffect(style: .systemUltraThinMaterialLight)
            let blurView = UIVisualEffectView(effect: blur)
            blurView.isUserInteractionEnabled = false
            blurView.frame = tf.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            tf.insertSubview(blurView, at: 0)

            // ----- DROP SHADOW -----
            tf.layer.masksToBounds = false
            tf.layer.shadowColor = UIColor.black.withAlphaComponent(0.25).cgColor
            tf.layer.shadowOpacity = 0.35
            tf.layer.shadowRadius = 10
            tf.layer.shadowOffset = CGSize(width: 0, height: 6)

            // Left padding
            let pad = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
            tf.leftView = pad
            tf.leftViewMode = .always
        }
    }

    private func styleNextButton() {
        nextButton.layer.cornerRadius = 24
        nextButton.backgroundColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nextButton.layer.shadowColor = UIColor.purple.withAlphaComponent(0.28).cgColor
        nextButton.layer.shadowOpacity = 0.9
        nextButton.layer.shadowRadius = 6
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    // MARK: - Password Toggles
    private func addPasswordToggleIcons() {
        addToggle(to: passwordTextField)
        addToggle(to: confirmPasswordTextField)
    }

    private func addToggle(to textField: UITextField) {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .gray
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
        textField.rightView = button
        textField.rightViewMode = .always
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        guard let tf = sender.superview as? UITextField ?? sender.findTextField() else { return }
        let wasSecure = tf.isSecureTextEntry
        tf.isSecureTextEntry.toggle()
        sender.setImage(UIImage(systemName: tf.isSecureTextEntry ? "eye.slash" : "eye"), for: .normal)

        if let text = tf.text, !text.isEmpty {
            tf.text = nil; tf.text = text
        }
        if wasSecure { tf.becomeFirstResponder() }
    }

    // MARK: - Keyboard Dismiss
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setDelegates() {
        [emailTextField, fullNameTextField, passwordTextField, confirmPasswordTextField].forEach { $0?.delegate = self }
        emailTextField.returnKeyType = .next
        fullNameTextField.returnKeyType = .next
        passwordTextField.returnKeyType = .next
        confirmPasswordTextField.returnKeyType = .done
    }

    @objc private func endEditing() { view.endEditing(true) }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField: fullNameTextField.becomeFirstResponder()
        case fullNameTextField: passwordTextField.becomeFirstResponder()
        case passwordTextField: confirmPasswordTextField.becomeFirstResponder()
        default: textField.resignFirstResponder()
        }
        return true
    }

    // MARK: - Actions
    @IBAction func nextTapped(_ sender: UIButton) {
        guard
            let email = emailTextField.text, !email.isEmpty,
            let name = fullNameTextField.text, !name.isEmpty,
            let password = passwordTextField.text, !password.isEmpty,
            let confirm = confirmPasswordTextField.text, !confirm.isEmpty
        else { showAlert(title: "Missing info", message: "Please fill all fields."); return }

        guard password == confirm else {
            showAlert(title: "Passwords mismatch", message: "Please make sure passwords match.")
            return
        }

        let vc = BusinessViewController(nibName: "BusinessViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(a, animated: true)
    }
}

extension UIView {
    func findTextField() -> UITextField? {
        if let tf = self as? UITextField { return tf }
        return superview?.findTextField()
    }
}
