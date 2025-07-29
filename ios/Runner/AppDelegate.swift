import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register custom channel for UserDefaults
    if let controller = window?.rootViewController as? FlutterViewController {
      registerUserDefaultsChannel(with: controller)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func registerUserDefaultsChannel(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "contentvault/userdefaults",
      binaryMessenger: controller.binaryMessenger
    )
    
    channel.setMethodCallHandler { (call, result) in
      if call.method == "getSharedData" {
        let appGroupName = "group.com.sangdae.contentvault.dw002"
        
        if let userDefaults = UserDefaults(suiteName: appGroupName),
           let sharedData = userDefaults.object(forKey: "ShareMedia") as? [[String: Any]] {
          print("AppDelegate: Found \(sharedData.count) shared items")
          result(sharedData)
        } else {
          print("AppDelegate: No shared data found")
          result([])
        }
      } else if call.method == "clearSharedData" {
        let appGroupName = "group.com.sangdae.contentvault.dw002"
        
        if let userDefaults = UserDefaults(suiteName: appGroupName) {
          userDefaults.removeObject(forKey: "ShareMedia")
          userDefaults.synchronize()
          print("AppDelegate: Cleared shared data")
          result(true)
        } else {
          result(false)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
