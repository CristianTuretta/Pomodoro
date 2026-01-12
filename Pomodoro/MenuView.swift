//
//  MenuView.swift
//  Pomodoro
//
//  Created by Cristian Turetta on 30/03/22.
//
import SwiftUI

struct MenuView: View {
    @Namespace private var tabAnimation
    @ObservedObject var workingMode: PomodoroWorkingMode

    @AppStorage("mode.selected") private var currentTab: String = "Pomodoro"
    @AppStorage("appearance.glassEnabled") private var glassEnabled: Bool = true
    @AppStorage("appearance.motionEnabled") private var motionEnabled: Bool = true
    @AppStorage("stats.completedSessions") private var completedSessions: Int = 0
    @AppStorage("duration.pomodoro.work") private var pomodoroWorkMinutes: Int = WorkingMode.pomodoroDefaults.work
    @AppStorage("duration.pomodoro.break") private var pomodoroBreakMinutes: Int = WorkingMode.pomodoroDefaults.rest

    @State private var animatedTimeRemaining: Double = 0
    @State private var animatedClock: String = ""
    @State private var animatedStatus: Bool = false
    @State private var didAppear: Bool = false
    @State private var floatUp: Bool = false
    @State private var glowPulse: Bool = false

    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: DrawingConstants.stackSpacing) {
                timeView
                controlButton
                sessionIndicator
                palette
                durationRow
                appearanceRow
                breakDonation
            }
            .padding(DrawingConstants.outerPadding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.cardCornerRadius, style: .continuous))
            .overlay(cardBorder)
            .shadow(color: Palette.shadow, radius: 20, x: 0, y: 8)
            .opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 12)
            .animation(.easeOut(duration: 0.5), value: didAppear)
        }
        .frame(width: DrawingConstants.viewFrame.width, height: DrawingConstants.viewFrame.heigth, alignment: .center)
        .onAppear {
            normalizeStoredDurations()
            applyCurrentDurations(preserveState: workingMode.mode.modality != .inactive)
            didAppear = true
            updateMotion(enabled: motionEnabled)
        }
        .onChange(of: motionEnabled) { newValue in
            updateMotion(enabled: newValue)
        }
        .onChange(of: currentTab) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                applyCurrentDurations(preserveState: false)
            }
        }
    }

    private var timeView: some View {
        ZStack {
            Circle()
                .stroke(Palette.ringBackground, lineWidth: DrawingConstants.lineWidth)
                .opacity(DrawingConstants.backgroundCircleOpacity)

            progressRing

            if motionEnabled {
                Circle()
                    .stroke(modeColor.opacity(glowPulse ? 0.35 : 0.15), lineWidth: DrawingConstants.lineWidth + 6)
                    .blur(radius: 10)
            }

            VStack(spacing: 6) {
                statusIcon

                Text(statusLabel.uppercased())
                    .font(Palette.statusFont)
                    .foregroundColor(Palette.secondaryText)
                    .tracking(1)

                Text(animatedClock)
                    .font(Palette.clockFont)
                    .foregroundColor(Palette.primaryText)
                    .monospacedDigit()
                    .onReceive(timer) { _ in
                        animatedClock = workingMode.mode.timeOnClock
                        updateTimerState()
                    }

                Text(workingMode.mode.description)
                    .font(Palette.captionFont)
                    .foregroundColor(Palette.secondaryText)
            }
        }
        .frame(width: DrawingConstants.timerDiameter, height: DrawingConstants.timerDiameter)
        .offset(y: motionEnabled ? (floatUp ? -4 : 4) : 0)
        .rotationEffect(.degrees(motionEnabled ? (floatUp ? -1.5 : 1.5) : 0))
    }

    @ViewBuilder
    private var progressRing: some View {
        switch workingMode.mode.modality {
        case .inactive:
            Pie(startAngle: Angle(degrees: 360), endAngle: Angle(degrees: 0))
                .stroke(modeColor, lineWidth: DrawingConstants.lineWidth)
        case .working:
            Pie(
                startAngle: Angle(degrees: 360 - 90),
                endAngle: Angle(degrees: (1 - animatedTimeRemaining) * 360 - 90)
            )
            .stroke(modeGradient, style: StrokeStyle(lineWidth: DrawingConstants.lineWidth, lineCap: .round))
            .onAppear {
                startRingAnimation(isWorking: true)
            }
        case .breaking:
            Pie(
                startAngle: Angle(degrees: 360 - 90),
                endAngle: Angle(degrees: (1 - animatedTimeRemaining) * 360 - 90)
            )
            .stroke(modeGradient, style: StrokeStyle(lineWidth: DrawingConstants.lineWidth, lineCap: .round))
            .onAppear {
                startRingAnimation(isWorking: false)
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch workingMode.mode.modality {
        case .inactive:
            Text(" ")
                .font(Palette.iconFont)
                .frame(height: 18)
        case .working:
            Text("🔨")
                .font(Palette.iconFont)
                .rotationEffect(Angle.degrees(motionEnabled ? (animatedStatus ? -20 : 20) : 0))
                .animation(.easeInOut(duration: 0.6), value: animatedStatus)
        case .breaking:
            Text("☕️")
                .font(Palette.iconFont)
        }
    }

    private var controlButton: some View {
        Button(action: toggleTimer) {
            Image(systemName: workingMode.mode.modality != .inactive ? "stop.fill" : "play.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    Circle().fill(controlGradient)
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(glassEnabled ? 0.5 : 0.3), lineWidth: 1)
                )
                .shadow(color: Palette.shadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(motionEnabled ? (floatUp ? 1.02 : 0.98) : 1)
        .accessibilityLabel(workingMode.mode.modality == .inactive ? "Start timer" : "Stop timer")
    }

    private var sessionIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<DrawingConstants.sessionGoal, id: \.self) { index in
                Circle()
                    .fill(index < sessionProgress ? modeColor : Palette.dotInactive)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle().stroke(Color.white.opacity(glassEnabled ? 0.6 : 0.2), lineWidth: 0.5)
                    )
            }
        }
        .opacity(workingMode.mode.modality == .inactive ? 0.6 : 1)
        .accessibilityLabel(Text("Session progress"))
    }

    private var palette: some View {
        HStack(spacing: 8) {
            TabButton(title: "Pomodoro", currentTab: $currentTab, namespace: tabAnimation)
            TabButton(title: "Double Pomodoro", currentTab: $currentTab, namespace: tabAnimation)
        }
    }

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Duration")
                    .font(Palette.captionFont)
                    .foregroundColor(Palette.secondaryText)
                    .tracking(0.4)

                if isDoubleMode {
                    Text("x2")
                        .font(Palette.captionFont)
                        .foregroundColor(Palette.primaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.white.opacity(glassEnabled ? 0.3 : 0.5))
                        )
                }

                Spacer()
            }

            HStack(spacing: 8) {
                DurationPill(
                    title: "Focus",
                    minutes: focusMinutesBinding,
                    range: focusRange,
                    step: focusStep,
                    accent: modeColor,
                    glassEnabled: glassEnabled
                )
                DurationPill(
                    title: "Break",
                    minutes: breakMinutesBinding,
                    range: breakRange,
                    step: breakStep,
                    accent: modeColor,
                    glassEnabled: glassEnabled
                )
            }
        }
    }

    private var appearanceRow: some View {
        HStack(spacing: 16) {
            Toggle("Glass", isOn: $glassEnabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("Motion", isOn: $motionEnabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(SwitchToggleStyle(tint: modeColor))
        .font(Palette.toggleFont)
        .foregroundColor(Palette.primaryText)
    }

    private var breakDonation: some View {
        Link("Offer a ☕️ to 👨‍💻", destination: URL(string: "https://www.paypal.com/donate/?hosted_button_id=S7N5EBEBPG9FQ")!)
            .font(Palette.captionFont)
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Capsule().fill(controlGradient))
            .opacity(workingMode.mode.modality == .breaking ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: workingMode.mode.modality)
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.backgroundTop, Palette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Palette.work.opacity(0.15))
                .frame(width: 220, height: 220)
                .offset(x: -140, y: -120)
                .blur(radius: 30)

            Circle()
                .fill(Palette.breakColor.opacity(0.12))
                .frame(width: 200, height: 200)
                .offset(x: 140, y: 160)
                .blur(radius: 30)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var cardBackground: some View {
        if glassEnabled {
            GlassCard(cornerRadius: DrawingConstants.cardCornerRadius)
        } else {
            RoundedRectangle(cornerRadius: DrawingConstants.cardCornerRadius, style: .continuous)
                .fill(Palette.cardSolid)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: DrawingConstants.cardCornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [Color.white.opacity(glassEnabled ? 0.7 : 0.4), Color.white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: glassEnabled ? 1 : 0.5
            )
    }

    private var statusLabel: String {
        switch workingMode.mode.modality {
        case .inactive:
            return "Ready"
        case .working:
            return "Focus"
        case .breaking:
            return "Break"
        }
    }

    private var modeColor: Color {
        switch workingMode.mode.modality {
        case .inactive:
            return Palette.inactive
        case .working:
            return Palette.work
        case .breaking:
            return Palette.breakColor
        }
    }

    private var modeGradient: LinearGradient {
        switch workingMode.mode.modality {
        case .inactive:
            return LinearGradient(colors: [Palette.inactive, Palette.inactive.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .working:
            return LinearGradient(colors: [Palette.work, Palette.workHighlight], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .breaking:
            return LinearGradient(colors: [Palette.breakColor, Palette.breakHighlight], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var controlGradient: LinearGradient {
        LinearGradient(colors: [modeColor, modeColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var isDoubleMode: Bool {
        currentTab == "Double Pomodoro"
    }

    private var focusMinutesBinding: Binding<Int> {
        Binding(
            get: { displayedFocusMinutes },
            set: { newValue in
                setPomodoroFocusMinutes(fromDisplayed: clamp(newValue, in: focusRange))
                applyCurrentDurations(preserveState: true)
            }
        )
    }

    private var breakMinutesBinding: Binding<Int> {
        Binding(
            get: { displayedBreakMinutes },
            set: { newValue in
                setPomodoroBreakMinutes(fromDisplayed: clamp(newValue, in: breakRange))
                applyCurrentDurations(preserveState: true)
            }
        )
    }

    private var displayedFocusMinutes: Int {
        isDoubleMode ? pomodoroWorkMinutes * 2 : pomodoroWorkMinutes
    }

    private var displayedBreakMinutes: Int {
        isDoubleMode ? pomodoroBreakMinutes * 2 : pomodoroBreakMinutes
    }

    private var focusRange: ClosedRange<Int> {
        let base = DrawingConstants.focusRange
        return isDoubleMode ? (base.lowerBound * 2)...(base.upperBound * 2) : base
    }

    private var breakRange: ClosedRange<Int> {
        let base = DrawingConstants.breakRange
        return isDoubleMode ? (base.lowerBound * 2)...(base.upperBound * 2) : base
    }

    private var focusStep: Int {
        isDoubleMode ? DrawingConstants.focusStep * 2 : DrawingConstants.focusStep
    }

    private var breakStep: Int {
        isDoubleMode ? DrawingConstants.breakStep * 2 : DrawingConstants.breakStep
    }

    private func setPomodoroFocusMinutes(fromDisplayed value: Int) {
        let baseValue = isDoubleMode ? value / 2 : value
        pomodoroWorkMinutes = clamp(baseValue, in: DrawingConstants.focusRange)
    }

    private func setPomodoroBreakMinutes(fromDisplayed value: Int) {
        let baseValue = isDoubleMode ? value / 2 : value
        pomodoroBreakMinutes = clamp(baseValue, in: DrawingConstants.breakRange)
    }

    private func normalizeStoredDurations() {
        pomodoroWorkMinutes = clamp(pomodoroWorkMinutes, in: DrawingConstants.focusRange)
        pomodoroBreakMinutes = clamp(pomodoroBreakMinutes, in: DrawingConstants.breakRange)
    }

    private func applyCurrentDurations(preserveState: Bool) {
        let workMinutes = isDoubleMode ? pomodoroWorkMinutes * 2 : pomodoroWorkMinutes
        let breakMinutes = isDoubleMode ? pomodoroBreakMinutes * 2 : pomodoroBreakMinutes

        workingMode.changeMode(
            to: currentTab,
            workMinutes: workMinutes,
            breakMinutes: breakMinutes,
            preserveState: preserveState
        )
        animatedClock = workingMode.mode.timeOnClock

        if preserveState, workingMode.mode.modality != .inactive {
            refreshRingAnimation()
        } else {
            animatedTimeRemaining = 0
            animatedStatus = false
        }
    }

    private func refreshRingAnimation() {
        switch workingMode.mode.modality {
        case .working:
            startRingAnimation(isWorking: true)
        case .breaking:
            startRingAnimation(isWorking: false)
        case .inactive:
            break
        }
    }

    private func clamp(_ value: Int, in range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private var sessionProgress: Int {
        min(max(completedSessions, 0), DrawingConstants.sessionGoal)
    }

    private func toggleTimer() {
        switch workingMode.mode.modality {
        case .inactive:
            workingMode.start()
        case .working, .breaking:
            workingMode.stop()
        }
    }

    private func startRingAnimation(isWorking: Bool) {
        if isWorking {
            animatedTimeRemaining = workingMode.mode.timerWorking.timeRemainingPercentage
            withAnimation(.linear(duration: workingMode.mode.timerWorking.timeRemaining)) {
                animatedTimeRemaining = 0
            }
        } else {
            animatedTimeRemaining = workingMode.mode.timerBreaking.timeRemainingPercentage
            withAnimation(.linear(duration: workingMode.mode.timerBreaking.timeRemaining)) {
                animatedTimeRemaining = 0
            }
        }
    }

    private func updateTimerState() {
        switch workingMode.mode.modality {
        case .inactive:
            animatedStatus = false
        case .working:
            if motionEnabled {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animatedStatus.toggle()
                }
            } else {
                animatedStatus = false
            }
            if workingMode.mode.timerWorking.timeRemaining == 0 {
                animatedTimeRemaining = 1
                completedSessions = (completedSessions + 1) % DrawingConstants.sessionGoal
                workingMode.switching(to: .breaking)
            }
        case .breaking:
            if workingMode.mode.timerBreaking.timeRemaining == 0 {
                animatedTimeRemaining = 1
                workingMode.switching(to: .working)
            }
        }
    }

    private func updateMotion(enabled: Bool) {
        if enabled {
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                floatUp = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        } else {
            floatUp = false
            glowPulse = false
        }
    }

    struct TabButton: View {
        var title: String
        @Binding var currentTab: String
        var namespace: Namespace.ID

        var body: some View {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    currentTab = title
                }
            } label: {
                ZStack {
                    if currentTab == title {
                        RoundedRectangle(cornerRadius: DrawingConstants.cornerRadius, style: .continuous)
                            .fill(Palette.tabActive)
                            .matchedGeometryEffect(id: "tab", in: namespace)
                    }

                    Text(title)
                        .font(Palette.tabFont)
                        .foregroundColor(currentTab == title ? .white : Palette.primaryText)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .background(
                    RoundedRectangle(cornerRadius: DrawingConstants.cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.001))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DrawingConstants.cornerRadius, style: .continuous)
                        .stroke(Palette.tabBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    struct GlassCard: View {
        var cornerRadius: CGFloat

        var body: some View {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .blendMode(.screen)
                )
        }
    }

    struct DurationPill: View {
        let title: String
        @Binding var minutes: Int
        let range: ClosedRange<Int>
        let step: Int
        let accent: Color
        let glassEnabled: Bool

        var body: some View {
            HStack(spacing: 8) {
                Text(title.uppercased())
                    .font(Palette.captionFont)
                    .foregroundColor(Palette.secondaryText)
                    .tracking(0.5)

                Spacer(minLength: 4)

                Button(action: { adjust(by: -step) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(canDecrease ? accent : Palette.secondaryText)
                }
                .buttonStyle(.plain)
                .disabled(!canDecrease)

                Text("\(minutes)m")
                    .font(Palette.durationFont)
                    .foregroundColor(Palette.primaryText)
                    .monospacedDigit()
                    .frame(minWidth: 36)

                Button(action: { adjust(by: step) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(canIncrease ? accent : Palette.secondaryText)
                }
                .buttonStyle(.plain)
                .disabled(!canIncrease)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DrawingConstants.cornerRadius, style: .continuous)
                    .fill(glassEnabled ? Color.white.opacity(0.25) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DrawingConstants.cornerRadius, style: .continuous)
                    .stroke(Palette.tabBorder, lineWidth: 1)
            )
        }

        private var canDecrease: Bool {
            minutes - step >= range.lowerBound
        }

        private var canIncrease: Bool {
            minutes + step <= range.upperBound
        }

        private func adjust(by delta: Int) {
            let newValue = min(max(minutes + delta, range.lowerBound), range.upperBound)
            if newValue != minutes {
                minutes = newValue
            }
        }
    }

    struct DrawingConstants {
        static let cornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 24
        static let outerPadding: CGFloat = 16
        static let stackSpacing: CGFloat = 12
        static let timerDiameter: CGFloat = 190
        static let lineWidth: CGFloat = 5
        static let backgroundCircleOpacity: Double = 0.4
        static let viewFrame: (width: CGFloat, heigth: CGFloat) = (360, 460)
        static let sessionGoal = 4
        static let focusRange: ClosedRange<Int> = 10...120
        static let breakRange: ClosedRange<Int> = 3...60
        static let focusStep: Int = 5
        static let breakStep: Int = 1
    }

    struct Palette {
        static let backgroundTop = Color(red: 0.99, green: 0.96, blue: 0.92)
        static let backgroundBottom = Color(red: 0.90, green: 0.96, blue: 0.99)
        static let work = Color(red: 0.96, green: 0.46, blue: 0.25)
        static let workHighlight = Color(red: 1.00, green: 0.70, blue: 0.40)
        static let breakColor = Color(red: 0.20, green: 0.70, blue: 0.55)
        static let breakHighlight = Color(red: 0.45, green: 0.86, blue: 0.70)
        static let inactive = Color(red: 0.55, green: 0.55, blue: 0.55)
        static let ringBackground = Color.black.opacity(0.12)
        static let primaryText = Color.black.opacity(0.85)
        static let secondaryText = Color.black.opacity(0.55)
        static let dotInactive = Color.black.opacity(0.12)
        static let shadow = Color.black.opacity(0.18)
        static let cardSolid = Color.white.opacity(0.7)
        static let tabActive = LinearGradient(colors: [work, workHighlight], startPoint: .topLeading, endPoint: .bottomTrailing)
        static let tabBorder = Color.black.opacity(0.12)

        static let statusFont = Font.custom("Avenir Next", size: 10).weight(.semibold)
        static let clockFont = Font.custom("Avenir Next", size: 40).weight(.semibold)
        static let captionFont = Font.custom("Avenir Next", size: 12).weight(.medium)
        static let toggleFont = Font.custom("Avenir Next", size: 11).weight(.medium)
        static let tabFont = Font.custom("Avenir Next", size: 12).weight(.semibold)
        static let iconFont = Font.custom("Avenir Next", size: 16).weight(.regular)
        static let durationFont = Font.custom("Avenir Next", size: 13).weight(.semibold)
    }
}

struct MenuViewPreviews: PreviewProvider {
    static var previews: some View {
        MenuView(workingMode: PomodoroWorkingMode())
    }
}
