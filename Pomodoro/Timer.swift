import Foundation
import SwiftUI
import Combine

class PomodoroTimer: ObservableObject {
    @Published var timeString: String
    @Published var pomCount: Int8
    @Published var workTime: TimeInterval
    @Published var shortTime: TimeInterval
    @Published var longTime: TimeInterval
    @Published var isRunning: Bool
    @Published var curType: String = "Pomodoro"
    @Published var staticImage = NSImage(named: "tomato")!
    

    private var timer: Timer? = nil
    private var intervalType: IntervalType = .work
    private var remainingTime: TimeInterval = 0
    private var numBreaks: Int8
    private var curTime: TimeInterval
//    private var cancellable: AnyCancellable?

//     var timeString: Binding<String>

    enum IntervalType {
        case work, shortBreak, longBreak
    }
    
    init() {
        self.timeString = ""
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
//        timer?.invalidate()
        reset()
        print("im in custom setting yo")
        self.pomCount = 0
        self.workTime = workTime * 60
        self.shortTime = shortTime * 60
        self.longTime = longTime * 60
        self.numBreaks = numBreaks
        self.curTime = workTime * 60
        self.isRunning = false
//        self.updateTime()
    }
    
    func defaultSetting() {
//        timer?.invalidate()
        reset()
        print("im in default setting yo")
        self.pomCount = 0
        self.workTime = 25 * 60
        self.shortTime = 5 * 60
        self.longTime = 15 * 60
        self.numBreaks = 4
        self.curTime = 25 * 60
        self.isRunning = false
//        self.updateTime()
    }
    
    func start() {
//        self.updateTime()
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
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                self.decrementTime()
            }
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
    
//    func getTime() -> String {
//        return timeString
//    }
    
    private func decrementTime() {
           guard isRunning else { return }

           if curTime > 0 {
               curTime -= 1
               updateTime()
           } else {
               pomCount += (intervalType == .work ? 1 : 0)
               switchInterval()
           }
       }
    
    private func switchInterval() {
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
//            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(decrementTime), userInfo: nil, repeats: true)
//            RunLoop.current.add(timer!, forMode: .common)
        }
    }
    
    func reset() {
        timer?.invalidate()
        timer = nil
        curType = "Pomodoro"
        isRunning = false
        pomCount = 0
        remainingTime = 0
        intervalType = .work
        curTime = workTime
//        updateTime()
    }
    
    private func updateTime() {
        let minutes = Int(curTime) / 60
        let seconds = Int(curTime) % 60

        timeString = String(format: "%02i:%02i", minutes, seconds) // da problem
    }
    
}
