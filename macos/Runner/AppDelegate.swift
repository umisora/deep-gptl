import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  private var eventMonitor: Any?
  private var lastCmdCEvent: Date?
  private let cmdCIntervalThreshold = 0.5 // 0.5秒以内に2回押されたかをチェック

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    checkAccessibilityPermissions()
    let menuItem = NSMenuItem(title: "Activate", action: #selector(activateMenuItemClicked), keyEquivalent: "i")
    menuItem.keyEquivalentModifierMask = [.command, .shift] // Set the shortcut to Cmd+Shift+C
    if let editMenu = NSApp.mainMenu?.item(withTitle: "Edit")?.submenu {
        editMenu.addItem(menuItem)
    }
    print("DEEPGPTL: Started Applications")
    startMonitoringCmdC()
  }

  override func applicationWillTerminate(_ aNotification: Notification) {
    stopMonitoringCmdC()
  }
  private func checkAccessibilityPermissions() {
    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [checkOptPrompt: true]
    let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)

    if !accessEnabled {
      let alert = NSAlert()
      alert.messageText = "Accessibility Permissions Needed"
      alert.informativeText = "This app requires accessibility permissions to function. Please grant these in System Preferences."
      alert.alertStyle = .warning
      alert.runModal()
    }
  }
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  @objc func activateMenuItemClicked(_ sender: NSMenuItem) {
    // Code to execute when the menu item is clicked or the shortcut is pressed
    print("DEEPGPTL: Clicked")
    NSApp.activate(ignoringOtherApps: true)
    sendActivateMessageToFlutter()
  }


  private func sendActivateMessageToFlutter() {
    print("DEEPGPTL: Sending activate message to Flutter")
    if let controller = self.mainFlutterWindow?.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.example.deep_gptl/activate", binaryMessenger: controller.engine.binaryMessenger)
      channel.invokeMethod("activate", arguments: nil)
    }
  }
  private func startMonitoringCmdC() {
    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
      if event.modifierFlags.contains(.command) && event.keyCode == 8 {
        if let lastCmdCEvent = lastCmdCEvent, Date().timeIntervalSince(lastCmdCEvent) < cmdCIntervalThreshold {
          sendActivateMessageToFlutter()
        }
        lastCmdCEvent = Date()
      }
    }
  }

  private func stopMonitoringCmdC() {
    if let eventMonitor = eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      self.eventMonitor = nil
    }
  }
}
