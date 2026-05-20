import Foundation

class DarkModeBarItem: CustomButtonTouchBarItem, Widget {
    static var name: String = "darkmode"
    static var identifier: String = "com.toxblh.mtmr.darkmode"

    private var appearanceObserver: NSObjectProtocol?
    private var refreshTimer: Timer?

    init(identifier: NSTouchBarItem.Identifier) {
        super.init(identifier: identifier, title: "")
        isBordered = false
        setWidth(value: 24)

        actions.append(ItemAction(trigger: .singleTap) { [weak self] in self?.DarkModeToggle() })

        appearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }

        refreshTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        refreshTimer?.tolerance = 5

        refresh()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        refreshTimer?.invalidate()
        if let observer = appearanceObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    func DarkModeToggle() {
        DarkMode.isEnabled = !DarkMode.isEnabled
        refresh()
    }

    @objc func refresh() {
        image = DarkMode.isEnabled ? #imageLiteral(resourceName: "dark-mode-on") : #imageLiteral(resourceName: "dark-mode-off")
    }
}


struct DarkMode {
    private static let prefix = "tell application \"System Events\" to tell appearance preferences to"

    static var isEnabled: Bool {
        get {
            return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        }
        set {
            toggle(force: newValue)
        }
    }

    static func toggle(force: Bool? = nil) {
        let value = force.map(String.init) ?? "not dark mode"
        _ = runAppleScript("\(prefix) set dark mode to \(value)")
    }
}

func runAppleScript(_ source: String) -> String? {
    return NSAppleScript(source: source)?.executeAndReturnError(nil).stringValue
}
