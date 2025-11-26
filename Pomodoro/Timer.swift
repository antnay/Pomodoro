import Combine
import Foundation
import SwiftUI
import UserNotifications

class PomodoroTimer: ObservableObject {
    @Published var timeString: String?
    @Published var isRunning: Bool = false
    @Published var currState: IntervalType = .start
    @Published var runningPoms: Int8 = 0

    @Published var pomCount: Int8 {
        didSet {
            UserDefaults.standard.set(pomCount, forKey: "pomCount")
        }
    }
    @Published var workTime: TimeInterval {
        didSet {
            UserDefaults.standard.set(workTime, forKey: "workTime")
        }
    }
    @Published var shortBreak: TimeInterval {
        didSet {
            UserDefaults.standard.set(shortBreak, forKey: "shortBreak")
        }
    }
    @Published var longBreak: TimeInterval {
        didSet {
            UserDefaults.standard.set(longBreak, forKey: "longBreak")
        }
    }

    private var lastTimeStringUpdate: String? = nil
    private var timerTask: Task<Void, Never>? = nil
    private var curTime: TimeInterval
    private var runningBreaks: Int8 = 0

    final let MINUTE: Double = 60

    init() {
        requestNoti()
        self.runningPoms = 0
        self.timeString = nil
        self.isRunning = false

        let wTime =
            UserDefaults.standard.double(forKey: "workTime") == 0
            ? 25 : UserDefaults.standard.double(forKey: "workTime")

        self.pomCount =
            Int8(UserDefaults.standard.integer(forKey: "pomCount")) == 0
            ? 4 : Int8(UserDefaults.standard.integer(forKey: "pomCount"))
        self.workTime = wTime
        self.shortBreak =
            UserDefaults.standard.double(forKey: "shortBreak") == 0
            ? 5 : UserDefaults.standard.double(forKey: "shortBreak")
        self.longBreak =
            UserDefaults.standard.double(forKey: "longBreak") == 0
            ? 15 : UserDefaults.standard.double(forKey: "longBreak")

        self.curTime = wTime * MINUTE
        self.timeString = curTime.description
    }

    //    func start() {
    //        updateTime()
    //        currState = .work
    //        self.isRunning = true
    //
    //        timerTask = Task(priority: .background) {  // background priority
    //            while isRunning {
    //                //                try? await Task.sleep(nanoseconds: 1_100_000_000)
    //                try? await Task.sleep(nanoseconds: 5_000_000)
    //                decrementTime()
    //            }
    //        }
    //    }

    func start() {
        updateTime()
        currState = .work
        self.isRunning = true

        scheduleNextTick()
    }

    private func scheduleNextTick() {
        guard isRunning else { return }

        timerTask = Task(priority: .background) {
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            if isRunning {
                decrementTime()
                scheduleNextTick()
            }
        }
    }

    func pause() {
        isRunning = false
        currState = .pause
        timerTask?.cancel()
        timerTask = nil
    }

    @inline(__always) private func decrementTime() {
        guard isRunning else { return }
        if curTime > 0 {
            switch currState {
            case .pause:
                Task { @MainActor in
                    self.isRunning = false
                }
                timerTask?.cancel()
                timerTask = nil
            default:
                curTime -= 1
                updateTime()
            }
        } else {
            switch currState {
            case .start:
                Task { @MainActor in
                    self.isRunning = false
                }
            case .pause:
                Task { @MainActor in
                    self.isRunning = false
                }
                timerTask?.cancel()
                timerTask = nil
            case .work:
                if runningBreaks == pomCount - 1 {
                    Task { @MainActor in
                        self.currState = .longBreak
                        self.curTime = self.longBreak * self.MINUTE
                    }
                    longBreakNoti()
                } else {
                    Task { @MainActor in
                        self.currState = .shortBreak
                        self.curTime = self.shortBreak * self.MINUTE
                    }
                    shortBreakNoti()
                }
            case .shortBreak:
                Task { @MainActor in
                    self.runningBreaks += 1
                    self.currState = .work
                    self.curTime = self.workTime * self.MINUTE
                }
                getToWorkNoti()
            case .longBreak:
                Task { @MainActor in
                    self.runningPoms += 1
                    self.runningBreaks = 0
                    self.currState = .work
                    self.curTime = self.workTime * self.MINUTE
                }
                getToWorkNoti()
            }
        }
    }
    @inline(__always) private func updateTime() {
        let minutes = Int(curTime / MINUTE)
        let seconds = Int(curTime.truncatingRemainder(dividingBy: MINUTE))
        let newTimeString = String(format: "%02i:%02i", minutes, seconds)
        if newTimeString != lastTimeStringUpdate {
            lastTimeStringUpdate = newTimeString
            Task { @MainActor in
                self.timeString = newTimeString
            }
        }
    }

    func reset() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        curTime = workTime * MINUTE
        timeString = curTime.description
        currState = .start
        runningPoms = 0
        runningBreaks = 0
    }
}

func requestNoti() {
    UNUserNotificationCenter.current().requestAuthorization(options: [
        .alert, .sound, .badge,
    ]) { granted, error in
        if granted {
            print("Notification permission granted.")
        } else {
            print(
                "Notification permission denied: \(error?.localizedDescription ?? "Unknown error")"
            )
        }
    }
}

private func sendNotification(title: String, body: String, identifier: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let req = UNNotificationRequest(
        identifier: identifier, content: content, trigger: nil)

    UNUserNotificationCenter.current().add(req) { error in
        if let error = error {
            print(
                "Error scheduling notification: \(error.localizedDescription)")
        }
    }
}

func shortBreakNoti() {
    sendNotification(
        title: "pomodoro", body: "long break started", identifier: "0")
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["0"])
    }
}

func longBreakNoti() {
    sendNotification(
        title: "pomodoro", body: "long break started", identifier: "1")

    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["1"])
    }
}

func getToWorkNoti() {
    sendNotification(title: "pomodoro", body: "get to work", identifier: "2")
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["2"])
    }
}
