import UIKit
import PhotosUI

final class BusinessViewController: UIViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Profile
    private let profileStack = UIStackView()
    private let profileImageView = UIImageView()
    private let profileHintLabel = UILabel()

    // Personal section
    private let personalTitleLabel = UILabel()
    private let nameTextField = UITextField()
    private let emailTextField = UITextField()
    private let phoneTextField = UITextField()

    // Business section
    private let businessTitleLabel = UILabel()
    private let businessNameTextField = UITextField()
    private let businessAddressTextField = UITextField()

    // Continue button
    private let continueButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        configureNavigationBar()
        setupScrollViewAndContent()
        setupProfileArea()
        setupPersonalSection()
        setupBusinessSection()
        setupContinueButton()
        styleTextFields()
        registerKeyboardNotifications()
        addTapToDismissKeyboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Nav Bar

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = .label

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ]
            appearance.shadowColor = .clear
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.compactAppearance  = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.shadowImage = UIImage()
        }

        navigationItem.title = "Create your profile"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Skip", style: .plain, target: self, action: #selector(skipTapped))
    }

    // MARK: - Layout Setup

    private func setupScrollViewAndContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Profile

    private func setupProfileArea() {
        profileStack.axis = .vertical
        profileStack.alignment = .center
        profileStack.spacing = 8
        profileStack.translatesAutoresizingMaskIntoConstraints = false

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray5
        profileImageView.layer.cornerRadius = 48
        profileImageView.isUserInteractionEnabled = true
        profileImageView.image = UIImage(systemName: "person.crop.circle")?.withRenderingMode(.alwaysTemplate)
        profileImageView.tintColor = .secondaryLabel

        let tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(tap)

        profileHintLabel.font = .systemFont(ofSize: 13)
        profileHintLabel.textColor = .secondaryLabel
        profileHintLabel.text = "Tap to add profile photo"

        profileStack.addArrangedSubview(profileImageView)
        profileStack.addArrangedSubview(profileHintLabel)
        contentStack.addArrangedSubview(profileStack)

        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 96),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor)
        ])
    }

    // MARK: - Personal Section

    private func setupPersonalSection() {
        personalTitleLabel.text = "Personal Information"
        personalTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        contentStack.addArrangedSubview(personalTitleLabel)

        // Name
        contentStack.addArrangedSubview(labelledFieldLabel("Name"))
        nameTextField.placeholder = "Full name"
        contentStack.addArrangedSubview(nameTextField)

        // Email
        contentStack.addArrangedSubview(labelledFieldLabel("Email"))
        emailTextField.placeholder = "you@example.com"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        contentStack.addArrangedSubview(emailTextField)

        // Phone
        contentStack.addArrangedSubview(labelledFieldLabel("Phone"))
        phoneTextField.placeholder = "Mobile number"
        phoneTextField.keyboardType = .phonePad
        contentStack.addArrangedSubview(phoneTextField)
    }

    // MARK: - Business Section

    private func setupBusinessSection() {
        businessTitleLabel.text = "Business Information"
        businessTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        contentStack.addArrangedSubview(businessTitleLabel)

        contentStack.addArrangedSubview(labelledFieldLabel("Business Name"))
        businessNameTextField.placeholder = "Business name"
        contentStack.addArrangedSubview(businessNameTextField)

        contentStack.addArrangedSubview(labelledFieldLabel("Business Address"))
        businessAddressTextField.placeholder = "Street, city, state"
        contentStack.addArrangedSubview(businessAddressTextField)
    }

    private func labelledFieldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .label
        return l
    }

    // MARK: - Continue Button

    private func setupContinueButton() {
        continueButton.layer.cornerRadius = 22
        continueButton.backgroundColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(continueButton)
    }

    // MARK: - Styling

    private func styleTextFields() {
        let fields = [nameTextField, emailTextField, phoneTextField, businessNameTextField, businessAddressTextField]
        fields.forEach { tf in
            tf.borderStyle = .none
            tf.backgroundColor = .secondarySystemBackground
            tf.layer.cornerRadius = 10
            tf.layer.masksToBounds = true
            tf.layer.borderWidth = 1
            tf.layer.borderColor = UIColor.systemGray4.cgColor
            tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            tf.leftViewMode = .always
            tf.tintColor = .systemBlue
            tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }

    // MARK: - Actions

    @objc private func skipTapped() {
        // present main app without validating
        presentMainTabBarAsRoot()
    }

    @objc private func profileTapped() {
        presentImagePickerOptions()
    }

    @objc private func continueTapped() {
        view.endEditing(true)

        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bname = businessNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let baddr = businessAddressTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty, !email.isEmpty, !phone.isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill Name, Email and Phone.")
            return
        }

        guard isValidEmail(email) else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }

        guard isValidPhone(phone) else {
            showAlert(title: "Invalid Phone", message: "Please enter a valid phone number.")
            return
        }

        guard !bname.isEmpty, !baddr.isEmpty else {
            showAlert(title: "Missing Business Info", message: "Please fill Business Name and Address.")
            return
        }

        // all good -> present main tab bar
        presentMainTabBarAsRoot()
    }

    // MARK: - Validators

    private func isValidEmail(_ s: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    private func isValidPhone(_ s: String) -> Bool {
        let digits = s.filter { $0.isWholeNumber }
        return digits.count >= 7 && digits.count <= 15
    }

    // MARK: - Image Picker

    private func presentImagePickerOptions() {
        let a = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            a.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
                self.presentSystemImagePicker(source: .camera)
            }))
        }
        a.addAction(UIAlertAction(title: "Choose from Library", style: .default, handler: { _ in
            self.presentPHPicker()
        }))

        a.addAction(UIAlertAction(title: "Remove Photo", style: .destructive, handler: { _ in
            self.profileImageView.image = UIImage(systemName: "person.crop.circle")
            self.profileImageView.tintColor = .secondaryLabel
        }))

        a.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if let pop = a.popoverPresentationController {
            pop.sourceView = profileImageView
            pop.sourceRect = profileImageView.bounds
        }
        present(a, animated: true)
    }

    private func presentPHPicker() {
        if #available(iOS 14, *) {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            presentSystemImagePicker(source: .photoLibrary)
        }
    }

    private func presentSystemImagePicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - Tab Bar creation (same approach you used)

    private func makeMainTabBar() -> UITabBarController {
        let tabBar = UITabBarController()
        let symbols: [(String, String)] = [
            ("house", "house.fill"),
            ("creditcard", "creditcard.fill"),
            ("storefront", "storefront.fill"),
            ("cart", "cart.fill")
        ]
        
        let dashVC = OnboardingWelcomeViewController()   // ALWAYS start here
        let dashNav = UINavigationController(rootViewController: dashVC)
        dashNav.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        // Payments
        let paymentsVC = PaymentsRootController()
        let paymentsNav = UINavigationController(rootViewController: paymentsVC)
        paymentsNav.tabBarItem = UITabBarItem(
            title: "Payments",
            image: UIImage(systemName: "creditcard"),
            selectedImage: UIImage(systemName: "creditcard.fill")
        )
        
        // Services
        let servicesVC = ServicesViewController()
        let servicesNav = UINavigationController(rootViewController: servicesVC)
        servicesNav.tabBarItem = UITabBarItem(
            title: "Services",
            image: UIImage(systemName: "storefront"),
            selectedImage: UIImage(systemName: "storefront.fill")
        )
        
        // Inventory
        let inventoryVC = InventoryRootController()
        let inventoryNav = UINavigationController(rootViewController: inventoryVC)
        inventoryNav.tabBarItem = UITabBarItem(
            title: "Inventory",
            image: UIImage(systemName: "cart"),
            selectedImage: UIImage(systemName: "cart.fill")
        )
        
        tabBar.viewControllers = [dashNav, paymentsNav, servicesNav, inventoryNav]
        tabBar.tabBar.tintColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)
        tabBar.tabBar.isTranslucent = false
        tabBar.selectedIndex = 0
        
        return tabBar
    }

    private func presentMainTabBarAsRoot() {
        let tabBar = makeMainTabBar()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
            UIView.transition(with: window, duration: 0.20, options: .transitionCrossDissolve, animations: nil)
        } else {
            tabBar.modalPresentationStyle = .fullScreen
            present(tabBar, animated: true)
        }
    }

    // MARK: - Keyboard handling

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func kbWillShow(_ n: Notification) {
        guard let info = n.userInfo,
              let frameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let kbFrame = frameValue.cgRectValue
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: kbFrame.height - view.safeAreaInsets.bottom + 16, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc private func kbWillHide(_ n: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    private func addTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - PHPicker Delegate (iOS 14+)
@available(iOS 14, *)
extension BusinessViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else { return }
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
                guard let img = obj as? UIImage else { return }
                DispatchQueue.main.async {
                    self?.profileImageView.image = img
                    self?.profileImageView.tintColor = nil
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension BusinessViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        if let img = image {
            profileImageView.image = img
            profileImageView.tintColor = nil
        }
    }
}
