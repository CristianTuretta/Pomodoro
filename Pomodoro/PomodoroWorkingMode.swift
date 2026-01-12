//
//  PomodoroWorkingMode.swift
//  Pomodoro
//
//  Created by Cristian Turetta on 30/03/22.
//  The ViewModel

import SwiftUI

class PomodoroWorkingMode: ObservableObject {
    
    private static func createPomodoroWorkingMode() -> WorkingMode {
        return WorkingMode()
    }
    
    @Published private var model = PomodoroWorkingMode.createPomodoroWorkingMode()
    
    var mode: Pomodoro {
        model.mode
    }
    
    
    // MARK: - Intents
    
    func start() {
        if model.mode.modality == .working {
            model.switching(to: .breaking)
        } else {
            model.switching(to: .working)
        }
    }
    
    func stop() {
        model.switching(to: .inactive)
    }
    
    func switching(to newModality: Pomodoro.Modality) {
        model.switching(to: newModality)
    }
    
    func changeMode(to newMode: String, workMinutes: Int, breakMinutes: Int, preserveState: Bool = false) {
        model.change(selected: newMode, workMinutes: workMinutes, breakMinutes: breakMinutes, preserveState: preserveState)
    }
    
}
