import UIKit
import MapKit

// MARK: - Data Model passed to the next screen
struct EventDetails {
    let eventName: String
    let clientName: String
    let location: String
    let guestCount: Int
    let budgetInPaise: Int        // store raw value; format on display
    let startDate: Date
    let endDate: Date
}

final class EventDetailsViewController: UIViewController {

    // --- Convenience factory: returns a UINavigationController with this VC as the root.
    // Use this when you want to present the screen modally but still show a nav bar.
    // Example:
    //    let nav = EventDetailsViewController.wrappedInNavigation()
    //    present(nav, animated: true)
    static func wrappedInNavigation() -> UINavigationController {
        let vc = EventDetailsViewController()
        let nav = UINavigationController(rootViewController: vc)
        // ensure standard appearance (match ConfirmationViewController behavior)
        nav.navigationBar.prefersLargeTitles = false
        nav.setNavigationBarHidden(false, animated: false)
        nav.modalPresentationStyle = .fullScreen
        return nav
    }

    // MARK: UI
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    private let contentView = UIView()
    private let formStack = UIStackView()

    private let continueButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Continue"
        cfg.baseBackgroundColor = UIColor(red: 0x8B/255, green: 0x3B/255, blue: 0xF0/255, alpha: 1)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24)

        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.layer.cornerRadius = 28
        b.layer.masksToBounds = true
        return b
    }()

    // Fields (uses your RoundedTextField)
    private let eventName = RoundedTextField(placeholder: "Enter The Event Name")
    private let clientName = RoundedTextField(placeholder: "Enter the Client Name")

    private let locationField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Search for Location")
        tf.setRightIcon(systemName: "paperplane")
        return tf
    }()

    private let guestCountField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Enter the Number of Guests")
        tf.keyboardType = .numberPad
        return tf
    }()

    private let budgetField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "₹1,00,000")
        tf.keyboardType = .numberPad
        return tf
    }()

    private let startDateField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Select Date")
        tf.setRightIcon(systemName: "calendar")
        return tf
    }()

    private let endDateField: RoundedTextField = {
        let tf = RoundedTextField(placeholder: "Select Date")
        tf.setRightIcon(systemName: "calendar")
        return tf
    }()

    // Date pickers
    private let startPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.preferredDatePickerStyle = .wheels
        p.minimumDate = Date()
        return p
    }()
    private let endPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.preferredDatePickerStyle = .wheels
        p.minimumDate = Date()
        return p
    }()

    // Formatters
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
    let indianFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        f.locale = Locale(identifier: "en_IN")
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Title shown in nav-bar
        navigationItem.title = "Event Details"
        navigationItem.largeTitleDisplayMode = .never

        // Left/back button which dismisses or pops depending on presentation
        let backItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(didTapBack))
        navigationItem.leftBarButtonItem = backItem

        setupLayout()
        setupDatePickers()
        setupBudgetFormatting()
        setupKeyboardHandling()
        hookRightIconTaps()
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // If hosted inside a navigation controller, ensure nav bar is visible
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: Layout
    private func setupLayout() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        formStack.translatesAutoresizingMaskIntoConstraints = false
        formStack.axis = .vertical
        formStack.spacing = 16

        view.addSubview(scrollView)
        view.addSubview(continueButton)
        scrollView.addSubview(contentView)
        contentView.addSubview(formStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            formStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        formStack.addArrangedSubview(labeled("Event Name", eventName))
        formStack.addArrangedSubview(labeled("Client Name", clientName))
        formStack.addArrangedSubview(labeled("Location", locationField))
        formStack.addArrangedSubview(labeled("Guest Count", guestCountField))
        formStack.addArrangedSubview(labeled("Budget", budgetField))

        let dateRow = hStack()
        dateRow.addArrangedSubview(labeled("Start Date", startDateField))
        dateRow.addArrangedSubview(labeled("End Date", endDateField))
        formStack.addArrangedSubview(dateRow)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = UIColor(white: 0.15, alpha: 1)
        return l
    }
    private func labeled(_ title: String, _ field: UIView) -> UIStackView {
        let s = UIStackView(arrangedSubviews: [sectionLabel(title), field])
        s.axis = .vertical
        s.spacing = 8
        return s
    }
    private func hStack() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 16
        s.distribution = .fillEqually
        return s
    }

    // MARK: Date pickers
    private func setupDatePickers() {
        startDateField.inputView = startPicker
        endDateField.inputView   = endPicker

        startPicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        endPicker.addTarget(self,   action: #selector(endDateChanged),   for: .valueChanged)

        startDateField.inputAccessoryView = toolbar(done: #selector(doneStart), cancel: #selector(cancelPicker))
        endDateField.inputAccessoryView   = toolbar(done: #selector(doneEnd),   cancel: #selector(cancelPicker))
    }
    private func toolbar(done: Selector, cancel: Selector) -> UIToolbar {
        let tb = UIToolbar()
        tb.items = [
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: cancel),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done,   target: self, action: done)
        ]
        tb.sizeToFit()
        return tb
    }
    @objc private func startDateChanged() {
        let d = startPicker.date
        endPicker.minimumDate = d
        startDateField.text = dateFormatter.string(from: d)
        if endPicker.date < d {
            endPicker.date = d
            endDateChanged()
        }
    }
    @objc private func endDateChanged() {
        let d = max(endPicker.date, startPicker.date)
        endPicker.date = d
        endDateField.text = dateFormatter.string(from: d)
    }
    @objc private func doneStart() { startDateChanged(); startDateField.resignFirstResponder() }
    @objc private func doneEnd()   { endDateChanged();   endDateField.resignFirstResponder() }
    @objc private func cancelPicker() { view.endEditing(true) }

    // MARK: Budget formatting
    private func setupBudgetFormatting() {
        budgetField.addTarget(self, action: #selector(formatBudget), for: .editingChanged)
    }
    @objc private func formatBudget() {
        let digits = budgetField.text?.filter(\.isNumber) ?? ""
        guard let n = Int(digits) else { budgetField.text = nil; return }
        budgetField.text = indianFormatter.string(from: NSNumber(value: n))
    }

    // MARK: Keyboard
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbChanged(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbHidden(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func kbChanged(_ n: Notification) {
        guard
            let ui = n.userInfo,
            let frame = ui[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let dur = ui[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }
        let bottom = max(0, view.convert(frame, from: nil).intersection(view.bounds).height)
        UIView.animate(withDuration: dur) {
            self.scrollView.contentInset.bottom = bottom + 12 + 56
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }
    @objc private func kbHidden(_ n: Notification) {
        let dur = (n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        UIView.animate(withDuration: dur) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
    @objc private func endEditingNow() { view.endEditing(true) }

    // MARK: Icon taps
    private func hookRightIconTaps() {
        startDateField.onRightIconTap(target: self, action: #selector(focusStartDate))
        endDateField.onRightIconTap(target: self, action: #selector(focusEndDate))
        locationField.onRightIconTap(target: self, action: #selector(openLocationSearch))

        startDateField.addTarget(self, action: #selector(focusStartDate), for: .editingDidBegin)
        endDateField.addTarget(self,   action: #selector(focusEndDate),   for: .editingDidBegin)
    }
    @objc private func focusStartDate() { startDateField.becomeFirstResponder() }
    @objc private func focusEndDate()   { endDateField.becomeFirstResponder() }

    @objc private func openLocationSearch() {
        let vc = LocationSearchViewController()
        vc.onSelect = { [weak self] sel in
            self?.locationField.text = sel.displayName
        }
        // If you want search to have nav controls, wrap it in a UINavigationController:
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissPresented)
        )
        present(nav, animated: true)
    }

    // MARK: Build + push
    private func parseINR(_ text: String?) -> Int? {
        guard let t = text, !t.isEmpty else { return nil }
        let digits = t.filter(\.isNumber)
        guard let rupees = Int(digits) else { return nil }
        return rupees * 100 // store as paise
    }

    private func readForm() throws -> EventDetails {
        enum VError: LocalizedError {
            case missing(String)
            case logical(String)
            var errorDescription: String? {
                switch self {
                case .missing(let f): return "\(f) is required."
                case .logical(let m): return m
                }
            }
        }

        guard let e = eventName.text?.trimmingCharacters(in: .whitespaces), !e.isEmpty
        else { throw VError.missing("Event Name") }

        guard let c = clientName.text?.trimmingCharacters(in: .whitespaces), !c.isEmpty
        else { throw VError.missing("Client Name") }

        guard let loc = locationField.text?.trimmingCharacters(in: .whitespaces), !loc.isEmpty
        else { throw VError.missing("Location") }

        guard let gcText = guestCountField.text?.filter(\.isNumber),
              let gc = Int(gcText), gc > 0
        else { throw VError.missing("Guest Count") }

        guard let budget = parseINR(budgetField.text), budget > 0
        else { throw VError.missing("Budget") }

        let s = startPicker.date
        let eDate = endPicker.date
        guard eDate >= s else { throw VError.logical("End Date cannot be before Start Date.") }

        return EventDetails(eventName: e,
                            clientName: c,
                            location: loc,
                            guestCount: gc,
                            budgetInPaise: budget,
                            startDate: s,
                            endDate: eDate)
    }

    // MARK: Actions
    @objc private func didTapBack() {
        // If presented modally (and this is the first controller in a nav stack), dismiss.
        if presentingViewController != nil && (navigationController == nil || navigationController?.viewControllers.first === self) {
            dismiss(animated: true)
            return
        }

        // Otherwise, if inside a navigation stack, pop.
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }

        // fallback: if nothing else, attempt to dismiss the root
        view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }

    @objc private func didTapContinue() {
        do {
            let details = try readForm()

            // show a small loading HUD (simple)
            let hud = UIActivityIndicatorView(style: .large)
            hud.translatesAutoresizingMaskIntoConstraints = false
            hud.startAnimating()
            view.addSubview(hud)
            NSLayoutConstraint.activate([
                hud.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                hud.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])

            Task {
                do {
                    // Insert event on server
                    let record = try await EventSupabaseManager.shared.insertEvent(details: details)

                    print("Event inserted id:", record.id)

                    DispatchQueue.main.async {
                        hud.removeFromSuperview()
                        // navigate to confirmation view with local details (we can also pass record.id if needed)
                        let vc = ConfirmationViewController(details: details,
                                                            currencyFormatter: self.indianFormatter,
                                                            dateFormatter: self.dateFormatter)
                        if let nav = self.navigationController {
                            nav.pushViewController(vc, animated: true)
                        } else {
                            let nav = UINavigationController(rootViewController: vc)
                            nav.modalPresentationStyle = .fullScreen
                            self.present(nav, animated: true, completion: nil)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        hud.removeFromSuperview()
                        let alert = UIAlertController(title: "Failed to save", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }

        } catch {
            let a = UIAlertController(title: "Hold on", message: error.localizedDescription, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
        }
    }


    @objc private func dismissPresented() {
        presentedViewController?.dismiss(animated: true)
    }
}
