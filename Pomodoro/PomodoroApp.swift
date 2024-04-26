//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Anthony Naydyuk on 4/5/24.
//

// TODO increment counts and switch to break!

import SwiftUI
import Foundation
import UserNotifications

@main
struct PomodoroApp: App {
    @StateObject private var timer = PomodoroTimer()
    private var statusItem: NSStatusItem?
    
    var body: some Scene {
        MenuBarExtra {
            TimerView(timer: timer)
        } label: {
            if timer.isRunning {
                Text(timer.timeString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .background(Color.blue)
            } else {
                let image: NSImage = {
                    let ratio = $0.size.height / $0.size.width
                    $0.size.height = 20
                    $0.size.width = 20 / ratio
                    return $0
                }(NSImage(named: "tomato")!)
                Image(nsImage: image)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

struct TimerView: View {
    @ObservedObject var timer: PomodoroTimer
    @State var setting: Bool = true
    @State var workTime: TimeInterval = 25
    @State var shortTime: TimeInterval = 5
    @State var longTime: TimeInterval = 15
    @State var numBreaks: Int8 = 4
    
    enum DefaultValues: Int {
        case work = 25
        case short = 5
        case long = 15
    }
    var body: some View {
        Text(timer.curType)
        if timer.isRunning == false {
            Text(timer.timeString)
        }
        Divider()
        Button(timer.isRunning ? "Pause" : "Start") {
            if timer.isRunning {
                timer.pause()
            } else {
                timer.start()
            }
        }
        Button("Reset") {
            timer.reset()
        }
        Divider()
        Toggle("Default settings", isOn: $setting)
            .onChange(of: setting) { value in
                if setting {
                    timer.defaultSetting()
                }
            }
            .toggleStyle(.switch)
        Form {
            Group {
                TextField("Work time", value: $workTime, formatter: NumberFormatter())
                TextField("Short break time", value: $shortTime, formatter: NumberFormatter())
                TextField("Long break time", value: $longTime, formatter: NumberFormatter())
                TextField("Pomodoro count", value: $numBreaks, formatter: NumberFormatter())
            }
        }
        .onSubmit {
            if !setting {
                timer.settings(workTime: workTime, shortTime: shortTime, longTime: shortTime, numBreaks: numBreaks)
            }
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}


class PomodoroTimer: ObservableObject {
    @Published var pomCount: Int
    @Published var workTime: TimeInterval
    @Published var shortTime: TimeInterval
    @Published var longTime: TimeInterval
    @Published var curTime: TimeInterval
    @Published var isRunning: Bool
    @Published var curType: String = "Pomodoro"
    @Published var staticImage = NSImage(named: "tomato")!
    @Published var timeString: String = ""
    
    private var timer: Timer? = nil
    private var intervalType: IntervalType = .work
    private var remainingTime: TimeInterval = 0
    private var numBreaks: Int8
    
    enum IntervalType {
        case work, shortBreak, longBreak
    }
    
    init() {
        self.pomCount = 0
        let defaultWorkTime: TimeInterval = 25 * 60
        self.workTime = defaultWorkTime
        self.shortTime = 5 * 60
        self.longTime = 15 * 60
        self.numBreaks = 4
        self.curTime = defaultWorkTime
        self.isRunning = false
        self.updateTime()
    }
    
    func settings(workTime: TimeInterval, shortTime: TimeInterval, longTime: TimeInterval, numBreaks: Int8) {
        timer?.invalidate()
        self.pomCount = 0
        self.workTime = workTime * 60
        self.shortTime = shortTime * 60
        self.longTime = longTime * 60
        self.numBreaks = numBreaks
        self.curTime = workTime * 60
        self.isRunning = false
        self.updateTime()
    }
    
    func defaultSetting() {
        timer?.invalidate()
        self.pomCount = 0
        let defaultWorkTime: TimeInterval = 25 * 60
        self.workTime = defaultWorkTime
        self.shortTime = 5 * 60
        self.longTime = 15 * 60
        self.numBreaks = 4
        self.curTime = defaultWorkTime
        self.isRunning = false
        self.updateTime()
    }
    func start() {
        self.updateTime()
        curType = "Work"
        if !isRunning {
            isRunning = true
            if timer == nil {
                if intervalType == .work {
                    curTime = workTime
                } else {
                    curTime = remainingTime
                }
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(decrementTime), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: .common)
        }
    }
    
    func pause() {
        //        print("pausing")
        curType = "Paused"
        isRunning = false
        timer?.invalidate()
        remainingTime = curTime
    }
    
    @objc func decrementTime() {
        if curTime > 0 {
            curTime -= 1
            DispatchQueue.main.async {
                [weak self] in
                self?.updateTime()
            }
            // debug printing
            //            print(curTime)
            //            print(intervalType)
            // end debug printing
        } else {
            if (intervalType == .work) {
                pomCount += 1
            }
            timer?.invalidate()
            switchInterval()
        }
    }
    
    func switchInterval() {
        if curTime <= 0 {
            if (intervalType == .work) {
                if pomCount < 4 {
                    intervalType = .shortBreak
                    curTime = shortTime
                } else {
                    intervalType = .longBreak
                    curTime = longTime
                    pomCount = 0
                }
                curType = "Break"
            }
            else {
                intervalType = .work
                curTime = workTime
                curType = "Work"
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(decrementTime), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: .common)
        }
    }
    
    func reset() {
        timer?.invalidate()
        curType = "Pomodoro"
        isRunning = false
        pomCount = 0
        remainingTime = 0
        intervalType = .work
        curTime = workTime
        updateTime()
    }
    
    private func updateTime() {
        let minutes = Int(curTime) / 60
        let seconds = Int(curTime) % 60
        self.timeString = String(format: "%02i:%02i", minutes, seconds)
    }
    
}

//@main
//struct Notification:App {
//    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
//        if success {
//            print("Started")
//        } else if let error {
//            print(error.localizedDescription)
//        }
//    }
//    content.title = "Started Timer"
//    content.sound = UNNotificationSound.default
//
//    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
//
//    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//    UNUserNotificationCenter.current().add(request)
//}
