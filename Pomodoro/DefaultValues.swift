//
//  DefaultValues.swift
//  Pomodoro
//
//  Created by Anthony on 7/9/25.
//

import Foundation

enum DefaultValues {
    static let workTime: TimeInterval = 25.0
    static let shortBreak: TimeInterval = 5.0
    static let longBreak: TimeInterval = 15.0
    static let numBreaks: Int8 = 4
}

enum IntervalType: String {
    case start = "pomodoro"
    case pause = "pause"
    case work = "work"
    case shortBreak = "short break"
    case longBreak = "long break"
    
    var stringValue: String {
            switch self {
            case .start: return "pomodoro"
            case .pause: return "pause"
            case .work: return "work"
            case .shortBreak: return "short break"
            case .longBreak: return "long break"
            }
        }
    
}
