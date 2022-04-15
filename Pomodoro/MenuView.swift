//
//  MenuView.swift
//  Pomodoro
//
//  Created by Cristian Turetta on 30/03/22.
//
import SwiftUI

struct MenuView: View {
    @Namespace private var animation
    @ObservedObject var workingMode: PomodoroWorkingMode
    @State var currentTab: String = "Pomodoro"
    @State var animatedTimeRemaining: Double = 0
    @State var animatedClock: String = ""
    @State var animatedStatus: Bool = false
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            timeView
                .onChange(of: currentTab){ newVaule in
                    withAnimation {
                        workingMode.changeMode(to: newVaule)
                    }
                }
                .padding()
            
            Image(systemName: workingMode.mode.modality != .inactive ? "stop" : "play")
                .resizable()
                .frame(width: DrawingConstants.imageFrame.width, height: DrawingConstants.imageFrame.heigth, alignment: .center)
                .background(
                    Circle()
                        .fill(.orange)
                        .frame(
                            width: DrawingConstants.imageFrame.width * 2,
                            height: DrawingConstants.imageFrame.heigth * 2,
                            alignment: .center
                        )
                )
                .onTapGesture {
                    withAnimation{
                        switch workingMode.mode.modality {
                        case .inactive:
                            workingMode.start()
                            
                        case .working:
                            workingMode.stop()

                        case .breaking:
                            workingMode.stop()
                        }
                    }
                }
                .padding()
            Divider()
            
            palette
        }
        .frame(width: DrawingConstants.viewFrame.width, height: DrawingConstants.viewFrame.heigth, alignment: .center)
    }
    
    var timeView: some View {
        VStack {
            ZStack {
                Group {
                    Pie(
                        startAngle: Angle(degrees: 360),
                        endAngle: Angle(degrees: 0)
                    )
                    .stroke(lineWidth: DrawingConstants.lineWidth)
                    .foregroundColor(.gray)
                    .opacity(DrawingConstants.backgroundCircleOpacity)
                    
                    switch workingMode.mode.modality {
                        case .inactive:
                            Pie(
                                startAngle: Angle(degrees: 360),
                                endAngle: Angle(degrees: 0)
                            )
                            .stroke(lineWidth: DrawingConstants.lineWidth)
                            .foregroundColor(.orange)
                        
                        case .working:
                            Pie(
                                startAngle: Angle(degrees: 360 - 90),
                                endAngle: Angle(degrees: (1 - animatedTimeRemaining) * 360 - 90)
                            )
                            .stroke(
                                style: StrokeStyle(
                                    lineWidth: DrawingConstants.lineWidth,
                                    lineCap: .round)
                            )
                            .foregroundColor(.orange)
                            .onAppear {
                                animatedTimeRemaining = workingMode.mode.timerWorking.timeRemainingPercentage
                                withAnimation(.linear(duration: workingMode.mode.timerWorking.timeRemaining)){
                                    animatedTimeRemaining = 0
                                }
                            }
                        
                        case .breaking:
                            Pie(
                                startAngle: Angle(degrees: 360 - 90),
                                endAngle: Angle(degrees: (1 - animatedTimeRemaining) * 360 - 90)
                            )
                            .stroke(
                                style: StrokeStyle(
                                    lineWidth: DrawingConstants.lineWidth,
                                    lineCap: .round)
                            )
                            .foregroundColor(.green)
                            .onAppear {
                                animatedTimeRemaining = workingMode.mode.timerBreaking.timeRemainingPercentage
                                withAnimation(.linear(duration: workingMode.mode.timerBreaking.timeRemaining)){
                                    animatedTimeRemaining = 0
                                }
                            }
                    }
                }
                withAnimation {
                    VStack {
                        Group {
                            
                            switch workingMode.mode.modality{
                            case .inactive:
                                withAnimation {
                                    Text(" ")
                                        .font(.title)
                                        .padding(.bottom, 3)
                                }
                            case .working:
                                withAnimation {
                                    Text("🔨")
                                        .rotationEffect(Angle.degrees(animatedStatus ? -45 : 45))
                                        .animation(Animation.linear.repeatForever(autoreverses: false), value: 1)
                                        .font(.title)
                                        .padding(.bottom, 3)
                                }
                            case .breaking:
                                withAnimation {
                                    Text("☕️")
                                        .font(.title)
                                        .padding(.bottom, 3)
                                }
                            }
                            
                            Text(workingMode.mode.description)
                                .foregroundColor(.gray)
                            
                            Text(animatedClock)
                                .font(.system(.largeTitle))
                                .onAppear {
                                    animatedClock = workingMode.mode.timeOnClock
                                }
                                .onReceive(timer) { input in
                                    animatedClock = workingMode.mode.timeOnClock
                                    
                                    switch workingMode.mode.modality {
                                    case .inactive:
                                        break
                                    case .working:
                                        animatedStatus.toggle()
                                        if workingMode.mode.timerWorking.timeRemaining == 0 {
                                            animatedTimeRemaining = 1
                                            workingMode.switching(to: .breaking)
                                        }
                                    case .breaking:
                                        if workingMode.mode.timerBreaking.timeRemaining == 0 {
                                            animatedTimeRemaining = 1
                                            workingMode.switching(to: .working)
                                        }
                                    }
                            }
                        
                            withAnimation {
                                Link("Offer a ☕️ to 👨‍💻", destination: URL(string: "https://www.paypal.com/donate/?hosted_button_id=S7N5EBEBPG9FQ")!)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(
                                        Capsule(style: .continuous).fill(.blue)
                                    ).opacity(workingMode.mode.modality == .breaking ? 1 : 0)

                            }
                        }
                    }
                }
            }
        }

    }
    
    var palette: some View {
        HStack {
            TabButton(title: "Pomodoro", currentTab: $currentTab)
            TabButton(title: "Double Pomodoro", currentTab: $currentTab)
        }
        .padding()
    }
    
    struct TabButton: View {
        var title: String
        @Binding var currentTab: String
        
        var body: some View {
            Button{
                withAnimation {
                    currentTab = title
                }
            } label: {
                Text(title)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(currentTab == title ? .white : .primary)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if currentTab == title {
                                RoundedRectangle(cornerRadius: DrawingConstants.cornerRadius)
                                    .fill(.blue)
                            } else {
                                RoundedRectangle(cornerRadius: DrawingConstants.cornerRadius)
                                    .stroke(.primary)
                            }
                        }
                    ).contentShape(RoundedRectangle(cornerRadius: DrawingConstants.cornerRadius))
                    
            }
            .buttonStyle(PlainButtonStyle())
        }
        
    }
    
    // MARK: - Drawing Constants
    struct DrawingConstants {
        static let cornerRadius: CGFloat = 4
        static let imageFrame: (width: CGFloat, heigth: CGFloat) = (16, 16)
        static let viewFrame: (width: CGFloat, heigth: CGFloat) = (400, 400)
        static let lineWidth: CGFloat = 5
        static let backgroundCircleOpacity = 0.5
    }
}


struct MenuViewPreviews: PreviewProvider {
    static var previews: some View {
        MenuView(workingMode: PomodoroWorkingMode())
    }
}
