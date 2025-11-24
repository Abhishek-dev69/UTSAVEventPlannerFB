import UIKit

final class VendorProposalViewController: UIViewController {

    private let vendor: Vendor
    private let requirement: CartItemRecord

    private let vendorField = UITextField()
    private let budgetField = UITextField()
    private let dateField = UITextField()
    private let notesText = UITextView()
    private let sendButton = UIButton(type: .system)

    init(vendor: Vendor, requirement: CartItemRecord) {
        self.vendor = vendor
        self.requirement = requirement
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Send Proposal"

        setupUI()
        fillData()
    }

    private func setting(_ tf: UITextField, placeholder: String) {
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        setting(vendorField, placeholder: "Vendor Name")
        setting(budgetField, placeholder: "Proposed Budget")
        setting(dateField, placeholder: "Required Completion Date")

        notesText.layer.borderWidth = 0.5
        notesText.layer.cornerRadius = 8
        notesText.heightAnchor.constraint(equalToConstant: 120).isActive = true

        sendButton.setTitle("Send Proposal", for: .normal)
        sendButton.backgroundColor = .systemPurple
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 22
        sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        stack.addArrangedSubview(vendorField)
        stack.addArrangedSubview(budgetField)
        stack.addArrangedSubview(dateField)
        stack.addArrangedSubview(notesText)
        stack.addArrangedSubview(sendButton)
    }

    private func fillData() {
        vendorField.text = vendor.name
        budgetField.text = "\(Int((requirement.rate ?? 0) * Double(requirement.quantity ?? 1)))"
    }

    // MARK: - SEND TO SUPABASE
    @objc private func sendTapped() {
        guard
            let completion = dateField.text,
            let budgetText = budgetField.text,
            let budget = Double(budgetText),
            let eventId = requirement.eventId
        else {
            print("❌ Invalid fields")
            return
        }

        Task {
            do {
                try await VendorProposalSupabaseManager.shared.sendProposal(
                    eventId: eventId,
                    vendorId: vendor.id,
                    serviceName: requirement.serviceName ?? "",
                    description: requirement.subserviceName ?? "",
                    budget: budget,
                    completionDate: completion,
                    notes: notesText.text ?? ""
                )

                let alert = UIAlertController(
                    title: "Success",
                    message: "Proposal Sent Successfully!",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                present(alert, animated: true)

            } catch {
                print("❌ Failed to send proposal:", error)
            }
        }
    }
}

