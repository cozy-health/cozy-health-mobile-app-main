import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var captureChannel: FlutterMethodChannel?
  private var captureObserver: NSObjectProtocol?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "cozy_health/screen_capture", binaryMessenger: controller.binaryMessenger)
      captureChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "setProtected" {
          result(self?.window?.screen.isCaptured ?? UIScreen.main.isCaptured)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      captureObserver = NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main
      ) { [weak self] _ in
        let captured = self?.window?.screen.isCaptured ?? UIScreen.main.isCaptured
        self?.captureChannel?.invokeMethod("captureChanged", arguments: captured)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  deinit {
    if let observer = captureObserver { NotificationCenter.default.removeObserver(observer) }
  }
}
