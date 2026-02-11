import SwiftUI

struct StressGraphView: View {
    let entries: [StressEntry]
    @State private var lineProgress: CGFloat = 0

    private var dataPoints: [(date: Date, weather: InnerWeather)] {
        entries.compactMap { entry in
            guard let weather = InnerWeather(rawValue: entry.weather) else { return nil }
            return (date: entry.timestamp, weather: weather)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#10B981"))
                Text("Today")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
            }

            if dataPoints.isEmpty {
                emptyState
            } else {
                graphContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text("Start monitoring to see your stress trajectory")
            .font(.system(size: 12))
            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 60)
    }

    // MARK: - Graph Content

    private var graphContent: some View {
        VStack(spacing: 4) {
            // Y-axis labels + chart
            HStack(alignment: .top, spacing: 6) {
                // Y-axis labels
                VStack {
                    Image(systemName: "sun.max")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#10B981"))
                    Spacer()
                    Image(systemName: "cloud")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#8BA4B0"))
                    Spacer()
                    Image(systemName: "cloud.bolt.rain")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#7B6B9E"))
                }
                .frame(width: 16, height: 56)

                // Chart area
                GeometryReader { geometry in
                    let size = geometry.size
                    let points = calculatePoints(in: size)

                    ZStack {
                        // Horizontal guide lines
                        ForEach(0..<3) { i in
                            let y = CGFloat(i) * size.height / 2
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            }
                            .stroke(Color(hex: "#C7E8DE").opacity(0.06), lineWidth: 0.5)
                        }

                        // Line
                        if points.count > 1 {
                            smoothLine(points: points, in: size)
                                .trim(from: 0, to: lineProgress)
                                .stroke(
                                    LinearGradient(
                                        colors: gradientColors(for: dataPoints),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                                )
                        }

                        // Dots
                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            let isLast = index == points.count - 1
                            let weather = dataPoints[index].weather
                            let dotColor = weatherColor(weather)

                            Circle()
                                .fill(dotColor)
                                .frame(width: isLast ? 8 : 5, height: isLast ? 8 : 5)
                                .overlay(
                                    isLast ?
                                    Circle()
                                        .fill(dotColor.opacity(0.3))
                                        .frame(width: 14, height: 14)
                                    : nil
                                )
                                .position(point)
                                .opacity(lineProgress > CGFloat(index) / CGFloat(max(points.count - 1, 1)) ? 1 : 0)
                        }
                    }
                }
                .frame(height: 56)
            }

            // Time labels
            HStack {
                Spacer().frame(width: 22) // offset for y-axis
                timeLabels
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                lineProgress = 1
            }
        }
    }

    // MARK: - Time Labels

    private var timeLabels: some View {
        GeometryReader { geometry in
            let points = calculatePoints(in: CGSize(width: geometry.size.width, height: 56))
            let labelCount = min(dataPoints.count, maxVisibleLabels(width: geometry.size.width))
            let step = max(1, dataPoints.count / labelCount)
            let formatter = DateFormatter()

            ZStack {
                ForEach(Array(stride(from: 0, to: dataPoints.count, by: step)), id: \.self) { index in
                    let safeIndex = min(index, points.count - 1)
                    let _ = {
                        formatter.dateFormat = "ha"
                        formatter.amSymbol = "am"
                        formatter.pmSymbol = "pm"
                    }()
                    Text(formatter.string(from: dataPoints[index].date).lowercased())
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                        .position(x: safeIndex < points.count ? points[safeIndex].x : 0, y: 6)
                }
            }
        }
        .frame(height: 14)
    }

    // MARK: - Helpers

    private func calculatePoints(in size: CGSize) -> [CGPoint] {
        guard dataPoints.count > 0 else { return [] }
        if dataPoints.count == 1 {
            return [CGPoint(x: size.width / 2, y: yPosition(for: dataPoints[0].weather, height: size.height))]
        }

        return dataPoints.enumerated().map { index, point in
            let x = CGFloat(index) / CGFloat(dataPoints.count - 1) * size.width
            let y = yPosition(for: point.weather, height: size.height)
            return CGPoint(x: x, y: y)
        }
    }

    private func yPosition(for weather: InnerWeather, height: CGFloat) -> CGFloat {
        let padding: CGFloat = 4
        let usable = height - padding * 2
        switch weather {
        case .clear: return padding
        case .cloudy: return padding + usable / 2
        case .stormy: return padding + usable
        }
    }

    private func smoothLine(points: [CGPoint], in size: CGSize) -> Path {
        Path { path in
            guard points.count >= 2 else { return }
            path.move(to: points[0])

            if points.count == 2 {
                path.addLine(to: points[1])
                return
            }

            for i in 1..<points.count {
                let prev = points[i - 1]
                let curr = points[i]
                let midX = (prev.x + curr.x) / 2
                path.addCurve(
                    to: curr,
                    control1: CGPoint(x: midX, y: prev.y),
                    control2: CGPoint(x: midX, y: curr.y)
                )
            }
        }
    }

    private func gradientColors(for points: [(date: Date, weather: InnerWeather)]) -> [Color] {
        if points.count <= 1 {
            return [weatherColor(points.first?.weather ?? .clear)]
        }
        return points.map { weatherColor($0.weather) }
    }

    private func weatherColor(_ weather: InnerWeather) -> Color {
        switch weather {
        case .clear: return Color(hex: "#10B981")
        case .cloudy: return Color(hex: "#8BA4B0")
        case .stormy: return Color(hex: "#7B6B9E")
        }
    }

    private func maxVisibleLabels(width: CGFloat) -> Int {
        max(2, Int(width / 50))
    }
}
