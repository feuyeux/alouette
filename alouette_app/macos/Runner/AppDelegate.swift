import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication)
    -> Bool
  {
    return true
  }

  @objc func showAbout(_ sender: Any?) {
    NSLog("=== About menu clicked ===")
    
    guard let window = mainFlutterWindow else {
      NSLog("ERROR: mainFlutterWindow is nil")
      return
    }
    
    guard let controller = window.contentViewController as? FlutterViewController else {
      NSLog("ERROR: Could not get FlutterViewController")
      return
    }
    
    NSLog("Creating method channel")
    let channel = FlutterMethodChannel(
      name: "com.example.alouette/menu",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    NSLog("Sending showAbout message to Flutter")
    channel.invokeMethod("showAbout", arguments: nil) { result in
      if let error = result as? FlutterError {
        NSLog("Error from Flutter: \(error.message ?? "unknown")")
      } else {
        NSLog("Flutter received message successfully")
      }
    }
  }
}
