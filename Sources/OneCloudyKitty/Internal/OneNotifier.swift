//
//  OneEventer.swift
//  Test
//
//  Created by Robin Enhorn on 2024-11-10.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

internal class OneNotifier: NSObject {

    private var observers: [NSObjectProtocol] = []
    private var listeners: Set<Listener> = []

    override init() {
        super.init()
        DispatchQueue.main.async { [weak self] in
            self?.setup()
        }
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

}

// MARK: - Listener handling -

extension OneNotifier {

    @discardableResult
    func register(event: Event, callback: @escaping (Event) -> Void) -> Listener {
        let listener = Listener(id: UUID(), event: event, callback: callback)
        listeners.insert(listener)
        return listener
    }

    func deregister(listener: Listener) {
        listeners.remove(listener)
    }

    internal func got(event: Event) {
        for listener in listeners {
            if listener.event == event || listener.event == .all {
                listener.callback(event)
            }
        }
    }

}

// MARK: - Setup -

private extension OneNotifier {

    func setup() {
        for (event, name) in eventsForSetup() {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                self?.got(event: event)
            })
        }
    }

    func eventsForSetup() -> [Event: Notification.Name] {
        #if canImport(UIKit)
        [
            .didEnterBackground: UIApplication.didEnterBackgroundNotification,
            .willEnterForeground: UIApplication.willEnterForegroundNotification,
            .didFinishLaunching: UIApplication.didFinishLaunchingNotification,
            .didBecomeActive: UIApplication.didBecomeActiveNotification,
            .willResignActive: UIApplication.willResignActiveNotification,
            .didReceiveMemoryWarning: UIApplication.didReceiveMemoryWarningNotification,
            .significantTimeChange: UIApplication.significantTimeChangeNotification,
        ]
        #elseif canImport(AppKit)
        [
            .didEnterBackground: NSApplication.didFinishLaunchingNotification,
            .willEnterForeground: NSApplication.willFinishLaunchingNotification,
            .didFinishLaunching: NSApplication.didFinishLaunchingNotification,
            .didBecomeActive: NSApplication.didBecomeActiveNotification,
            .willResignActive: NSApplication.willResignActiveNotification,
            .willTerminate: NSApplication.willTerminateNotification
        ]
        #endif
    }

}

// MARK: - Subtypes -

extension OneNotifier {

    enum Event: String {

        case all
        case didEnterBackground
        case willEnterForeground
        case didFinishLaunching
        case didBecomeActive
        case willResignActive
        case willTerminate

        #if canImport(UIKit)
        case didReceiveMemoryWarning
        case significantTimeChange
        #endif

    }

    struct Listener: Identifiable, Hashable {

        let id: UUID
        let event: Event
        let callback: (Event) -> Void

        init(id: UUID, event: Event = .all, callback: @escaping (Event) -> Void) {
            self.id = id
            self.event = event
            self.callback = callback
        }

        static func == (lhs: OneNotifier.Listener, rhs: OneNotifier.Listener) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

    }

}

extension OneNotifier: @unchecked Sendable { }
