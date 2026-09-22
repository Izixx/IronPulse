import SwiftUI
import AudioToolbox
import UIKit

@Observable
public final class RestTimerViewModel {
    public static let shared = RestTimerViewModel()

    public var timeRemaining: TimeInterval = 0
    public var totalDuration: TimeInterval = 90
    public var isActive: Bool = false
    public var isPresented: Bool = false
    public var exerciseName: String? = nil

    private var timer: Timer?

    public init() {}

    public var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, timeRemaining / totalDuration))
    }

    public var timeFormatted: String {
        let totalSeconds = Int(timeRemaining)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    public func start(duration: TimeInterval = 90, exercise: String? = nil) {
        timer?.invalidate()
        self.totalDuration = duration
        self.timeRemaining = duration
        self.exerciseName = exercise
        self.isActive = true
        self.isPresented = true

        // Planifier la notification locale pour quand l'écran est verrouillé
        NotificationManager.shared.scheduleRestTimerNotification(seconds: duration, exerciseName: exercise)

        // Haptic léger au départ
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 1 {
                self.timeRemaining -= 1
            } else {
                self.timeRemaining = 0
                self.finishTimer()
            }
        }
    }

    public func addSeconds(_ seconds: TimeInterval) {
        timeRemaining += seconds
        totalDuration = max(totalDuration, timeRemaining)
        // Mettre à jour la notification
        NotificationManager.shared.scheduleRestTimerNotification(seconds: timeRemaining, exerciseName: exerciseName)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPresented = false
        NotificationManager.shared.cancelRestTimerNotification()
    }

    private func finishTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false

        // Double vibration haptique forte + bip sonore système
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1005) // Standard iOS Alert chime
    }
}
