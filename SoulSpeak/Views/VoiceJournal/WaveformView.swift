import SwiftUI

/// Animated waveform visualization that responds to audio levels.
struct WaveformView: View {
    let levels: [CGFloat]
    let isActive: Bool
    var barColor: Color = SSColors.primary

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        isActive
                            ? barColor.opacity(0.6 + Double(level) * 0.4)
                            : Color.gray.opacity(0.3)
                    )
                    .frame(
                        width: 4,
                        height: isActive ? max(4, level * 50) : 4
                    )
                    .animation(
                        .easeInOut(duration: 0.08),
                        value: level
                    )
            }
        }
        .frame(height: 55)
    }
}

/// Idle waveform with subtle ambient animation
struct IdleWaveformView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let barWidth: CGFloat = 4
            let spacing: CGFloat = 3
            let totalBars = Int(size.width / (barWidth + spacing))

            for i in 0..<totalBars {
                let x = CGFloat(i) * (barWidth + spacing)
                let normalizedX = CGFloat(i) / CGFloat(totalBars)
                let wave = sin((normalizedX * .pi * 3) + phase) * 0.3 + 0.15
                let barHeight = max(4, wave * size.height * 0.5)

                let rect = CGRect(
                    x: x,
                    y: midY - barHeight / 2,
                    width: barWidth,
                    height: barHeight
                )
                let path = RoundedRectangle(cornerRadius: 2).path(in: rect)
                context.fill(path, with: .color(SSColors.primary.opacity(0.3)))
            }
        }
        .frame(height: 55)
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
