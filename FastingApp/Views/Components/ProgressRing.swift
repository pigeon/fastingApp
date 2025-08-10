import SwiftUI

struct ProgressRing: View {
    var progress: Double // 0...1

    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(gradient: Gradient(colors: [.blue, .green, .mint]), center: .center), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.3), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.title2).bold()
        }
    }
}
