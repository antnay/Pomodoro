//
//  VIewDefaults.swift
//  Pomodoro
//
//  Created by Anthony on 11/25/25.
//

import SwiftUI

enum ViewDefaults: CGFloat {
    case padding

    var value: CGFloat {
        switch self {
        case .padding: return 15
        }
    }
}
