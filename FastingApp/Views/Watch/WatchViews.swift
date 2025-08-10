import SwiftUI
#if os(watchOS)
import WatchKit

final class NotificationController: WKUserNotificationHostingController<NotificationView> {
    override var body: NotificationView { NotificationView() }
}

struct NotificationView: View {
    var body: some View { Text("Fasting complete") }
}

struct WatchMainView: View {
    @EnvironmentObject var vm: FastingViewModel
    var body: some View {
        VStack(spacing: 12) {
            ProgressRing(progress: vm.progress())
                .frame(width: 90, height: 90)
            if vm.status == .fasting { Button("Stop Fast") { vm.endFast() } } else { Button("Start Fast") { Task { await vm.startFast() } } }
        }.padding()
    }
}
#endif
