//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Cristian Turetta on 30/03/22.
//
import SwiftUI
import UserNotifications

@main
struct PomodoroApp: App {
    // Connect App Delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        Settings { }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // Status Bar Item
    var statusBarItem: NSStatusItem?
    
    // Pop Over
    var popOver = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuView = MenuView(workingMode: PomodoroWorkingMode())
        
        // Creating PopOver
        popOver.behavior = .transient
        popOver.animates = true
        popOver.contentViewController = NSViewController()
        popOver.contentViewController?.view = NSHostingView(rootView: menuView)
        
        // Make PopOver as main View
        popOver.contentViewController?.view.window?.makeKey()
        
        // Creating status bar button
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set menu button image and toggle PopOver
        if let menuButton = statusBarItem?.button {
//            menuButton.image = NSImage(systemSymbolName: "icloud.and.arrow.up.fill", accessibilityDescription: "Pomodoro App")
            menuButton.image = NSImage(named: NSImage.Name("pomodoro-logo"))
            menuButton.action = #selector(menuButtonToggle)
            menuButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Request authorization to notify user when it time to work and take a break
        requestNotificationAuthorization()
        
    }
    
    private func setupMenu() -> NSMenu {
        let menu = NSMenu()
        
//        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        menu.addItem(quit)
        return menu
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]){ success, error in
            if success {
                print("All set")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc func menuButtonToggle(sender: AnyObject) {
        let event = NSApp.currentEvent
        
        if let event = event {
            if event.type == .rightMouseUp {
                print("Right click on status bar icon")
                statusBarItem?.popUpMenu(setupMenu())
                
            } else if event.type == .leftMouseUp {
                print("Left click on status bar icon")
                
                if popOver.isShown{
                    popOver.performClose(sender)
                } else {
                    // Show PopOver
                    if let menuButton = statusBarItem?.button {
                        // Get button location for PopOver arrow
                        popOver.show(relativeTo: menuButton.bounds, of: menuButton, preferredEdge: .minY)
                    }
                }
            }
        }
        
        
    }
}
