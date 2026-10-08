//
//  SpineUpWidgetBundle.swift
//  SpineUpWidgetExtension
//
//  Created by Antigravity on 2026/10/8.
//

import WidgetKit
import SwiftUI

@main
struct SpineUpWidgetBundle: WidgetBundle {
    var body: some Widget {
        SUPostureWidget()
        SUPostureLiveActivityWidget()
    }
}
