import UIKit

final class OtpViewController: UIViewController, UITextFieldDelegate {

    // MARK: Init
    private let countryCode: String
    private let phone: String
    init(countryCode: String, phone: String) {
        self.countryCode = countryCode
        self.phone = phone
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: UI
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let codeStack = UIStackView()
    private var fields: [UITextField] = []
    private let nextButton = UIButton(type: .system)
    private let resendButton = UIButton(type: .system)

    private let digits = 6

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(false, animated: false)
        title = "Verify OTP"

        buildUI()
        layoutUI()
        styleUI()
        updateNextEnabled(false)

        fields.first?.becomeFirstResponder()
    }

    private func buildUI() {
        [titleLabel, infoLabel, codeStack, nextButton, resendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        codeStack.axis = .horizontal
        codeStack.alignment = .fill
        codeStack.distribution = .fillEqually
        codeStack.spacing = 12

        for _ in 0..<digits {
            let tf = UITextField()
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.textAlignment = .center
            tf.font = .systemFont(ofSize: 22, weight: .bold)
            tf.keyboardType = .numberPad
            tf.layer.cornerRadius = 10
            tf.backgroundColor = .secondarySystemBackground
            tf.delegate = self
            tf.addTarget(self, action: #selector(fieldChanged(_:)), for: .editingChanged)
            tf.addTarget(self, action: #selector(fieldEditingBegan(_:)), for: .editingDidBegin)
            tf.addTarget(self, action: #selector(fieldEditingEnded(_:)), for: .editingDidEnd)
            tf.tag = fields.count
            tf.heightAnchor.constraint(equalToConstant: 56).isActive = true
            codeStack.addArrangedSubview(tf)
            fields.append(tf)
        }
    }

    private func layoutUI() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            infoLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            codeStack.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 22),
            codeStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            codeStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            nextButton.topAnchor.constraint(equalTo: codeStack.bottomAnchor, constant: 24),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 56),

            resendButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 8),
            resendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func styleUI() {
        titleLabel.text = "Enter verification code"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label

        let masked = mask(phone)
        infoLabel.text = "We sent an OTP to \(countryCode) \(masked)"
        infoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0

        // Next button color -> #8B3BF0
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Next"
        cfg.baseBackgroundColor = UIColor(
            red: 0x8B/255.0,
            green: 0x3B/255.0,
            blue: 0xF0/255.0,
            alpha: 1.0
        )
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24)
        nextButton.configuration = cfg
        nextButton.layer.cornerRadius = 14
        nextButton.layer.masksToBounds = true
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        var rcfg = UIButton.Configuration.plain()
        rcfg.title = "Resend OTP"
        rcfg.baseForegroundColor = .systemBlue
        resendButton.configuration = rcfg
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
    }

    private func mask(_ number: String) -> String {
        // 10 digits -> ******1234
        let n = number.suffix(4)
        return "******\(n)"
    }

    private func updateNextEnabled(_ enabled: Bool) {
        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1 : 0.6
    }

    // MARK: OTP input behaviors
    @objc private func fieldChanged(_ tf: UITextField) {
        let text = tf.text ?? ""
        // keep a single digit
        if text.count > 1 { tf.text = String(text.suffix(1)) }
        if text.isEmpty, tf.tag > 0 {
            fields[tf.tag - 1].becomeFirstResponder()
        } else if !text.isEmpty, tf.tag < digits - 1 {
            fields[tf.tag + 1].becomeFirstResponder()
        }
        updateNextEnabled(collectedCode().count == digits)
    }

    @objc private func fieldEditingBegan(_ tf: UITextField) {
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.systemGray3.cgColor
    }
    @objc private func fieldEditingEnded(_ tf: UITextField) {
        tf.layer.borderWidth = 0
    }

    private func collectedCode() -> String {
        fields.map { ($0.text ?? "").trimmingCharacters(in: .whitespaces) }.joined()
    }

    @objc private func nextTapped() {
        let code = collectedCode()
        guard code.count == digits else { return }
        // Normally verify OTP with backend here
        let vc = BusinessViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func resendTapped() {
        // Trigger resend on backend
        let a = UIAlertController(title: "OTP Sent", message: "We’ve resent the OTP to \(countryCode) \(mask(phone)).", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // only digits: one digit per field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true } // backspace
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
            && (textField.text ?? "").count == 0
    }
}
