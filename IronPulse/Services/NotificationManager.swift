import Foundation
import UserNotifications

public final class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}

    public func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - Minuteur de repos
    public func scheduleRestTimerNotification(seconds: TimeInterval, exerciseName: String? = nil) {
        cancelRestTimerNotification()
        guard seconds > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ Repos terminé !"
        if let name = exerciseName, !name.isEmpty {
            content.body = "Prêt pour votre prochaine série sur : \(name)"
        } else {
            content.body = "C'est l'heure d'attaquer la prochaine série !"
        }
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "IronPulse.RestTimer", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur notification repos: \(error.localizedDescription)")
            }
        }
    }

    public func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["IronPulse.RestTimer"])
    }

    // MARK: - Rappel d'entraînement hebdomadaire
    public func scheduleWorkoutReminder(weekday: Int, hour: Int, minute: Int) {
        let identifier = "IronPulse.Reminder.Day\(weekday)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday // 1 = Dimanche, 2 = Lundi...
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "🏋️ Heure de l'entraînement !"
        content.body = "Votre séance IronPulse vous attend. Prêt à repousser vos limites ?"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    public func cancelAllReminders() {
        let identifiers = (1...7).map { "IronPulse.Reminder.Day\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
