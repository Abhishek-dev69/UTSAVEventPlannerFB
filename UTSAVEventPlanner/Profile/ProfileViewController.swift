import UIKit
import PhotosUI

final class ProfileViewController: UIViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Profile
    private let profileStack = UIStackView()
    private let profileImageView = UIImageView()
    private let profileHintLabel = UILabel()

    // Cards
    private let personalCard = UIView()
    private let businessCard = UIView()

    // Fields
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let businessNameField = UITextField()
    private let businessAddressField = UITextField()

    // Button
    private let continueButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        configureNavigationBar()
        setupScrollViewAndContent()
        setupProfileArea()
        setupCards()
        setupContinueButton()
        registerKeyboardNotifications()
        addTapToDismissKeyboard()

        Task { await loadProfile() }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Nav Bar

    private func configureNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Your Profile"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .done,
            target: self,
            action: #selector(logoutTapped)
        )
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func logoutTapped() {
        EventSession.shared.currentEventId = nil
        CartManager.shared.clear()

        let welcomeVC = OnboardingWelcomeViewController()
        let nav = UINavigationController(rootViewController: welcomeVC)
        nav.modalPresentationStyle = .fullScreen

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = nav
            window.makeKeyAndVisible()
            UIView.transition(with: window,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: {},
                              completion: nil)
        }
    }

    // MARK: - Scroll + Content

    private func setupScrollViewAndContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 20
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

    // MARK: - Profile Photo

    private func setupProfileArea() {
        profileStack.axis = .vertical
        profileStack.alignment = .center
        profileStack.spacing = 8

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray5
        profileImageView.layer.cornerRadius = 48
        profileImageView.isUserInteractionEnabled = true
        profileImageView.image = UIImage(systemName: "person.crop.circle")?.withRenderingMode(.alwaysTemplate)
        profileImageView.tintColor = .secondaryLabel

        let tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(tap)

        profileHintLabel.text = "Tap to add profile photo"
        profileHintLabel.font = .systemFont(ofSize: 13)
        profileHintLabel.textColor = .secondaryLabel

        profileStack.addArrangedSubview(profileImageView)
        profileStack.addArrangedSubview(profileHintLabel)
        contentStack.addArrangedSubview(profileStack)

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 96),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor)
        ])
    }

    // MARK: - Cards

    private func setupCards() {
        setupPersonalCard()
        setupBusinessCard()
    }

    private func setupPersonalCard() {
        personalCard.backgroundColor = .systemBackground
        personalCard.layer.cornerRadius = 14
        contentStack.addArrangedSubview(personalCard)

        let title = headerLabel("Personal Information")
        personalCard.addSubview(title)

        let stack = UIStackView()
        stack.axis = .vertical
        personalCard.addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: personalCard.leadingAnchor, constant: 16),
            title.topAnchor.constraint(equalTo: personalCard.topAnchor, constant: 12),

            stack.leadingAnchor.constraint(equalTo: personalCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: personalCard.trailingAnchor),
            stack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: personalCard.bottomAnchor)
        ])

        stack.addArrangedSubview(makeRow(title: "Name", control: nameField, placeholder: "Your name"))
        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(makeRow(title: "Email", control: emailField, placeholder: "you@example.com", keyboard: .emailAddress))
        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(makeRow(title: "Phone", control: phoneField, placeholder: "Mobile number", keyboard: .phonePad))
    }

    private func setupBusinessCard() {
        businessCard.backgroundColor = .systemBackground
        businessCard.layer.cornerRadius = 14
        contentStack.addArrangedSubview(businessCard)

        let title = headerLabel("Business / Work Details")
        businessCard.addSubview(title)

        let stack = UIStackView()
        stack.axis = .vertical
        businessCard.addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: businessCard.leadingAnchor, constant: 16),
            title.topAnchor.constraint(equalTo: businessCard.topAnchor, constant: 12),

            stack.leadingAnchor.constraint(equalTo: businessCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: businessCard.trailingAnchor),
            stack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: businessCard.bottomAnchor)
        ])

        stack.addArrangedSubview(makeRow(title: "Business Name", control: businessNameField, placeholder: "Business / brand name"))
        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(makeRow(title: "Address", control: businessAddressField, placeholder: "Street, city, state"))
    }

    private func headerLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeRow(title: String, control: UIControl, placeholder: String, keyboard: UIKeyboardType = .default) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)

        let tf = control as! UITextField
        tf.placeholder = placeholder
        tf.textAlignment = .right
        tf.keyboardType = keyboard
        tf.textColor = .systemBlue

        label.translatesAutoresizingMaskIntoConstraints = false
        tf.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)
        row.addSubview(tf)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            tf.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            tf.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            tf.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 10)
        ])

        return row
    }

    private func separator() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray4
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    // MARK: - Save Profile Button

    private func setupContinueButton() {
        continueButton.setTitle("Save Profile", for: .normal)
        continueButton.backgroundColor = UIColor(red: 139/255, green: 59/255, blue: 240/255, alpha: 1)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 22
        continueButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        continueButton.addTarget(self, action: #selector(saveProfileTapped), for: .touchUpInside)

        let container = UIView()
        container.addSubview(continueButton)

        continueButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            continueButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            continueButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            continueButton.topAnchor.constraint(equalTo: container.topAnchor),
            continueButton.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        contentStack.addArrangedSubview(container)
    }

    // MARK: - SAVE PROFILE (With Image Upload)

    @objc private func saveProfileTapped() {
        Task {
            do {
                let userId = try await SupabaseManager.shared.ensureUserId()

                var uploadedImageURL: String? = nil
                if profileImageView.tintColor == nil,
                   let img = profileImageView.image {
                    uploadedImageURL =
                        try await ProfileSupabaseManager.shared.uploadProfileImage(
                            userId: userId,
                            image: img
                        )
                }

                let payload = UserProfileInsert(
                    id: userId,
                    full_name: nameField.text,
                    email: emailField.text,
                    phone: phoneField.text,
                    business_name: businessNameField.text,
                    business_address: businessAddressField.text,
                    profile_image_url: uploadedImageURL
                )

                _ = try await ProfileSupabaseManager.shared.saveProfile(payload)

                await MainActor.run {
                    let tabBar = MainTabBarController.make()

                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first {
                        window.rootViewController = tabBar
                    }
                }

            } catch {
                print("Profile save error:", error)
            }
        }
    }


    // MARK: - Load Profile

    private func loadProfile() async {
        do {
            let uid = try await SupabaseManager.shared.ensureUserId()
            if let p = try await ProfileSupabaseManager.shared.fetchProfile(for: uid) {

                await MainActor.run {
                    nameField.text = p.fullName
                    emailField.text = p.email
                    phoneField.text = p.phone
                    businessNameField.text = p.businessName
                    businessAddressField.text = p.businessAddress

                    if let urlStr = p.profileImageUrl,
                       let url = URL(string: urlStr),
                       let data = try? Data(contentsOf: url),
                       let img = UIImage(data: data) {

                        self.profileImageView.image = img
                        self.profileImageView.tintColor = nil
                    }
                }
            }

        } catch {
            print("Failed to load profile:", error)
        }
    }

    // MARK: - Image Picker

    @objc private func profileTapped() { presentImagePickerOptions() }

    private func presentImagePickerOptions() {
        let a = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            a.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
                self.presentSystemPicker(.camera)
            })
        }

        a.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            self.presentPHPicker()
        })

        a.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
            self.profileImageView.image = UIImage(systemName: "person.crop.circle")
            self.profileImageView.tintColor = .secondaryLabel
        })

        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))

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
        }
    }

    private func presentSystemPicker(_ type: UIImagePickerController.SourceType) {
        let p = UIImagePickerController()
        p.delegate = self
        p.allowsEditing = true
        p.sourceType = type
        present(p, animated: true)
    }

    // MARK: - Keyboard Handling

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func kbShow(_ n: Notification) {
        guard let f = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = f.height - view.safeAreaInsets.bottom + 20
    }

    @objc private func kbHide(_ n: Notification) {
        scrollView.contentInset.bottom = 0
    }

    private func addTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditing() { view.endEditing(true) }
}


// MARK: - PHPicker

@available(iOS 14, *)
extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else { return }
        guard provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let img = image as? UIImage else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = img
                self?.profileImageView.tintColor = nil
            }
        }
    }
}


// MARK: - UIImagePickerController

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        if let image = img {
            profileImageView.image = image
            profileImageView.tintColor = nil
        }
    }
}

