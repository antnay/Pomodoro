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

struct MenuButtonStyle: ButtonStyle {
    @State private var isHighlighted = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top], 5)
            .padding([.bottom], 6)
            .padding([.leading, .trailing], 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHighlighted ? Color.gray.opacity(0.30) : Color.clear
            )
            .cornerRadius(5)
            .frame(width: 240, height: 20)
            .padding([.top, .bottom], 0)
            .onHover { isHovering in
                isHighlighted = isHovering
            }
    }
}


@main
struct PomodoroApp: App {
    @StateObject private var timer = PomodoroTimer()
    private var statusItem: NSStatusItem?
    
    var body: some Scene {
        MenuBarExtra {
            TimerView(timer: timer)
                .frame(width: 250)
                .cornerRadius(5.0)
        } label: {
            if timer.isRunning {
                Text(timer.timeString)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .background(Color.blue)
            } else {
                let image: NSImage = {
                    let ratio = $0.size.height / $0.size.width
                    $0.size.height = 25
                    $0.size.width = 25 / ratio
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
    @State var setting: Bool = false
    @State var workTime: TimeInterval = 25
    @State var shortTime: TimeInterval = 5
    @State var longTime: TimeInterval = 15
    @State var numBreaks: Int8 = 4
    @State var pomCounter: Int8 = 0
    let paddingValue: CGFloat = 15
    
    enum DefaultValues: Int {
        case work = 25
        case short = 5
        case long = 15
    }
    var body: some View {
        HStack {
            Text(timer.curType)
                .font(.system(size: 12, weight: .semibold))
            Spacer()
//            Text(timer.timeString)
            Text("\(timer.pomCount)  🍅")
        }
        .padding([.leading, .trailing], paddingValue)
        .padding(.top, 10)
        Divider()
        VStack {
            Button(timer.isRunning ? "Pause" : "Start") {
                if timer.isRunning {
                    timer.pause()
                } else {
                    timer.start()
                }
            }
            .buttonStyle(MenuButtonStyle())
            Button("Reset") {
                timer.reset()
            }
            .buttonStyle(MenuButtonStyle())
        }
        
        Divider()
        
        HStack {
            Text("Custom pomodoro")
                .frame(alignment: .leading)
            Spacer()
            Toggle("", isOn: $setting)
                .onChange(of: setting) { value in
                    if !setting {
                        timer.reset()
                        timer.defaultSetting()
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding([.leading, .trailing], paddingValue)
        
        
        Form {
            HStack {
                Text("Work")
                    .frame(alignment: .leading)
                Spacer()
                TextField("", value: $workTime, formatter: NumberFormatter())
                    .frame(width: 50, alignment: .leading)
            }
            .padding([.leading, .trailing], paddingValue)
            HStack {
                Text("Short break")
                    .frame(alignment: .leading)
                Spacer()
                TextField("", value: $shortTime, formatter: NumberFormatter())
                    .frame(width: 50, alignment: .leading)
            }
            .padding([.leading, .trailing], paddingValue)
            HStack {
                Text("Long break")
                    .frame(alignment: .leading)
                Spacer()
                TextField("", value: $longTime, formatter: NumberFormatter())
                    .frame(width: 50, alignment: .trailing)
            }
            .padding([.leading, .trailing], paddingValue)
            HStack {
                Text("Pomodoro count")
                    .frame(alignment: .leading)
                Spacer()
                TextField("", value: $numBreaks, formatter: NumberFormatter())
                    .frame(width: 50, alignment: .leading)
            }
            .padding([.leading, .trailing], paddingValue)
        }
        .disabled(!setting)
        .onSubmit {
            if setting {
                if timer.isRunning {
                    timer.reset()
                }
                timer.customSettings(workTime: workTime, shortTime: shortTime, longTime: shortTime, numBreaks: numBreaks)
            }
        }
        Divider()
        VStack {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .buttonStyle(MenuButtonStyle())
        }
        .padding(.bottom, 10)
    }
}



class PomodoroTimer: ObservableObject {
    @Published var pomCount: Int8
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
    
    func customSettings(workTime: TimeInterval, shortTime: TimeInterval, longTime: TimeInterval, numBreaks: Int8) {
        timer?.invalidate()
        reset()
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
        self.workTime = 25 * 60
        self.shortTime = 5 * 60
        self.longTime = 15 * 60
        self.numBreaks = 4
        self.curTime = 25 * 60
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
                    pomCount = 0 // maybe dont reset, find a way to keep all poms
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
