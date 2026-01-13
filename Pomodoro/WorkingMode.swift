//
//  WorkingMode.swift
//  Pomodoro
//
//  Created by Cristian Turetta on 30/03/22.
//  The model

import Foundation
import UserNotifications

struct WorkingMode {
    static let pomodoroDefaults = (work: 25, rest: 5)

    private(set) var mode: Pomodoro
    
    init() {
        mode = Pomodoro(
            name: "Pomodoro",
            id: 1,
            workingTimeLimit: Double(WorkingMode.pomodoroDefaults.work) * 60,
            breakingTimeLimit: Double(WorkingMode.pomodoroDefaults.rest) * 60
        )
    }
    
    mutating func switching(to newModality: Pomodoro.Modality) {
        let content = UNMutableNotificationContent()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        print("Switching from \(mode.modality) to \(newModality)")

        if mode.modality == .working && newModality == .breaking {
            // Send notification, it is time to take a break
            content.title = "Time to take a break!"
            content.subtitle = "The \(mode.name) has been completed, enjoy your break time"
            content.sound = UNNotificationSound.default

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Notification sent")
                }
            }

        } else if mode.modality == .breaking && newModality == .working {
            // Send notification, the break time is ended
            content.title = "The break time has ended!"
            content.subtitle = "Your break time is over, get back to work"
            content.sound = UNNotificationSound.default

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Notification sent")
                }
            }
        }
        
        mode.switching(to: newModality)
    }
        
    mutating func change(selected: String, workMinutes: Int, breakMinutes: Int, preserveState: Bool) {
        let safeWorkMinutes = max(1, workMinutes)
        let safeBreakMinutes = max(1, breakMinutes)

        let (name, identifier): (String, Int) = {
            switch selected {
            case "Pomodoro":
                return ("Pomodoro", 1)
            case "Double Pomodoro":
                return ("Double Pomodoro", 2)
            default:
                return ("Pomodoro", 1)
            }
        }()

        if preserveState {
            mode.name = name
            mode.id = identifier
            mode.workingTimeLimit = Double(safeWorkMinutes) * 60
            mode.breakingTimeLimit = Double(safeBreakMinutes) * 60
            mode.timerWorking.timeLimit = mode.workingTimeLimit
            mode.timerBreaking.timeLimit = mode.breakingTimeLimit
            return
        }

        switch selected {
        case "Pomodoro":
            mode = Pomodoro(
                name: name,
                id: identifier,
                workingTimeLimit: Double(safeWorkMinutes) * 60,
                breakingTimeLimit: Double(safeBreakMinutes) * 60
            )
        case "Double Pomodoro":
            mode = Pomodoro(
                name: name,
                id: identifier,
                workingTimeLimit: Double(safeWorkMinutes) * 60,
                breakingTimeLimit: Double(safeBreakMinutes) * 60
            )
        default:
            mode = Pomodoro(
                name: "Pomodoro",
                id: 1,
                workingTimeLimit: Double(WorkingMode.pomodoroDefaults.work) * 60,
                breakingTimeLimit: Double(WorkingMode.pomodoroDefaults.rest) * 60
            )
        }
    }
    
}

struct Pomodoro: Identifiable {
    var name: String
    var id: Int
    var workingTimeLimit: Double
    var breakingTimeLimit: Double
    var timerWorking: PomodoroTimer
    var timerBreaking: PomodoroTimer
    
    init(name: String, id: Int, workingTimeLimit: Double, breakingTimeLimit: Double) {
        self.name = name
        self.id = id
        self.workingTimeLimit = workingTimeLimit
        self.breakingTimeLimit = breakingTimeLimit
        self.timerWorking = PomodoroTimer(timeLimit: workingTimeLimit)
        self.timerBreaking = PomodoroTimer(timeLimit: breakingTimeLimit)
    }
    
    var modality: Modality = .inactive
    
    var description: String {
        var minutes = 0
        
        switch modality {
        case .inactive:
            minutes = Int(timerWorking.timeLimit) / 60
        case .working:
            minutes = Int(timerWorking.timeLimit) / 60
        case .breaking:
            minutes = Int(timerBreaking.timeLimit) / 60
        }
        
        return String(format: "%02i Min", minutes)
    }

    var timeOnClock: String {
        var minutes = 0
        var seconds = 0
        
        switch modality {
        case .inactive:
            minutes = Int(timerWorking.timeLimit) / 60
            seconds = Int(timerWorking.timeLimit) % 60
        case .working:
            minutes = Int(timerWorking.timeRemaining) / 60
            seconds = Int(timerWorking.timeRemaining) % 60
        case .breaking:
            minutes = Int(timerBreaking.timeRemaining) / 60
            seconds = Int(timerBreaking.timeRemaining) % 60
        }
        
        return String(format: "%02i:%02i", minutes, seconds)
    }
    
    var isCounsumingTime: Bool {
        modality != .inactive 
    }
    
    mutating func switching(to newModality: Modality){
        switch newModality {
        case .inactive:
            timerWorking.stop()
            timerBreaking.stop()
            
        case .working:
            timerWorking.start()
            timerBreaking.stop()
            
        case .breaking:
            timerWorking.stop()
            timerBreaking.start()
        }
        modality = newModality
    }
}


struct PomodoroTimer {
    var timeLimit: TimeInterval
    var startDate: Date?
    
    var timePassed: TimeInterval {
        if let startDate = self.startDate {
            return Date().timeIntervalSince(startDate)
        } else {
            return 0
        }
    }
    
    var timeRemaining: TimeInterval {
        max(0, timeLimit - timePassed)
    }
    
    var timeRemainingPercentage: Double {
        (timeLimit > 0 && timeRemaining > 0) ? timeRemaining/timeLimit : 0
    }
    
    var isActive: Bool {
        startDate != nil && timeRemaining > 0
    }
    
    mutating func start() {
        if !isActive, startDate == nil {
            startDate = Date()
        }
    }
    
    mutating func stop() {
        startDate = nil
    }
}


extension Pomodoro {
    enum Modality {
        case inactive
        case working
        case breaking
    }
}
