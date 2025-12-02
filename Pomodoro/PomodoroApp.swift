//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Anthony Naydyuk on 4/5/24.
//

// TODO increment counts and switch to break!
// FIXME fix the memory leaks with @Published

import Foundation
import SwiftUI
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
    @StateObject var timer = PomodoroTimer()

    var body: some Scene {

        MenuBarExtra {
            TimerView(timer: timer)
                .frame(width: 250)
                .cornerRadius(5.0)
        } label: {
            if timer.currState != .start {
                Text(timer.timeString.unsafelyUnwrapped)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .background(Color.blue)
            } else {
                let image: NSImage = {
                    let ratio = $0.size.height / $0.size.width
                    $0.size.height = 25
                    $0.size.width = 25 / ratio
                    $0.isTemplate = true
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
    let paddingValue: CGFloat = 15

    var body: some View {
        HStack {
            Text(timer.currState.stringValue)
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            Text("\($timer.runningPoms.wrappedValue)  🍅")
        }
        .padding([.leading, .trailing], ViewDefaults.padding.value)
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
        Settings(timer: timer)
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

struct Settings: View {
    @ObservedObject var timer: PomodoroTimer

    var body: some View {
        Form {
            VStack {
                HStack {
                    Text("work time")
                        .frame(alignment: .leading)
                    Spacer()
                    TextField("", value: $timer.workTime, format: .number)
                        .frame(width: 50, alignment: .leading)
                }
                .padding([.leading, .trailing], ViewDefaults.padding.value)
                HStack {
                    Text("short break")
                        .frame(alignment: .leading)
                    Spacer()
                    TextField(
                        "", value: $timer.shortBreak,
                        formatter: NumberFormatter()
                    )
                    .frame(width: 50, alignment: .leading)
                }
                .padding([.leading, .trailing], ViewDefaults.padding.value)
                HStack {
                    Text("long break")
                        .frame(alignment: .leading)
                    Spacer()
                    TextField(
                        "", value: $timer.longBreak,
                        formatter: NumberFormatter()
                    )
                    .frame(width: 50, alignment: .trailing)
                }
                .padding([.leading, .trailing], ViewDefaults.padding.value)
                HStack {
                    Text("pomodoros")
                        .frame(alignment: .leading)
                    Spacer()
                    TextField(
                        "", value: $timer.pomCount,
                        formatter: NumberFormatter()
                    )
                    .frame(width: 50, alignment: .leading)
                }
                .padding([.leading, .trailing], ViewDefaults.padding.value)
            }
        }
        .onSubmit {
            timer.updateSettings()
        }
    }
}
