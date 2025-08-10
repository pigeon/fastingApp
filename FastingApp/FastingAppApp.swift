//
//  FastingAppApp.swift
//  FastingApp
//
//  Created by Dmytro Golub on 10/08/2025.
//

import SwiftUI

//@main
//struct FastingAppApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


@main
struct FastingApp: App {
    @StateObject private var vm = FastingViewModel()

    var body: some Scene {
        WindowGroup { RootView().environmentObject(vm) }
        #if os(watchOS)
        WKNotificationScene(controller: NotificationController.self, category: "fasting")
        #endif
    }
}
