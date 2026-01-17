import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Start ObjC event capture observing (bridged via NS_SWIFT_NAME)
        EventCaptureManager.shared().startObserving()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name("SentinelAppDidEnterForeground"), object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name("SentinelAppDidEnterBackground"), object: nil)
    }

    // UIScene lifecycle is handled in SceneDelegate
}
