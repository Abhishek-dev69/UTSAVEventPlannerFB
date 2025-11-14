import UIKit

final class RoundedTextField: UITextField {
    private let padding = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 44)

    init(placeholder: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        borderStyle = .none
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.masksToBounds = false
        font = .systemFont(ofSize: 15)
        textColor = .label
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        heightAnchor.constraint(equalToConstant: 48).isActive = true
        applyShadow()
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        leftViewMode = .always
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
    }

    func setRightIcon(systemName: String) {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: systemName), for: .normal)
        btn.tintColor = .tertiaryLabel
        btn.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        rightView = btn
        rightViewMode = .always
    }

    func onRightIconTap(target: Any?, action: Selector) {
        (rightView as? UIButton)?.addTarget(target, action: action, for: .touchUpInside)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
}
