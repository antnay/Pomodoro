//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Anthony Naydyuk on 4/5/24.
//

// TODO increment counts and switch to break!
// FIXME fix the memory leaks with @Published

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
//    @StateObject var timer: PomodoroTimer = PomodoroTimer()
        @ObservedObject var timer: PomodoroTimer = PomodoroTimer()

    var body: some Scene {
        MenuBarExtra {
            TimerView(timer: timer)
//            TimerView()
//                .environmentObject(timer)
                .frame(width: 250)
                .cornerRadius(5.0)
        } 
    label: {
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
//    @EnvironmentObject var timer: PomodoroTimer
    var timer: PomodoroTimer
    @State var setting: Bool = false
    @State var workTime: TimeInterval = 25
    @State var shortTime: TimeInterval = 5
    @State var longTime: TimeInterval = 15
    @State var numBreaks: Int8 = 4
    @State var pomCounter: Int8 = 0
    let paddingValue: CGFloat = 15
    
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
