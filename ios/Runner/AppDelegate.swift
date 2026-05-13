import Flutter
import UIKit
import FirebaseCore
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 🔥 CRITICAL ORDER: Firebase MUST be configured before ANYTHING else
    // This ensures GoogleSignIn can read CLIENT_ID from GoogleService-Info.plist
    FirebaseApp.configure()

    // Register Flutter plugins AFTER Firebase is ready
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 🔑 REQUIRED: Handle Google Sign-In OAuth callback URL
  // Without this, the app cannot receive the auth token after Google login
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Let GoogleSignIn handle its OAuth callback first
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    // Fall through to Flutter's URL handler for other deep links
    return super.application(app, open: url, options: options)
  }

  // 🔑 REQUIRED for iOS 13+: Handle Universal Links & OAuth callback via Scene
  // This is needed when using UISceneDelegate (modern iOS architecture)
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }
}
