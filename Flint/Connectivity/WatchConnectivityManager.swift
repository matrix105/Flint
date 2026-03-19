import Foundation
import WatchConnectivity

struct WatchTodayData {
    let calories: Double
    let target: Double
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbsTarget: Double
    let fat: Double
    let fatTarget: Double
    let streak: Int
}

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    @Published var isReachable: Bool = false
    @Published var todayData: WatchTodayData?
    @Published var lastMealName: String?
    @Published var lastMealTime: String = ""
    @Published var lastMealCalories: Int?
    @Published var pendingQuickLog: String?

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Send today's data to Watch

    func syncTodayToWatch(
        calories: Double, target: Double,
        protein: Double, proteinTarget: Double,
        carbs: Double, carbsTarget: Double,
        fat: Double, fatTarget: Double,
        streak: Int,
        lastMeal: (name: String, time: String, calories: Int)?
    ) {
        guard WCSession.default.activationState == .activated else { return }

        var context: [String: Any] = [
            "calories": calories,
            "target": target,
            "protein": protein,
            "proteinTarget": proteinTarget,
            "carbs": carbs,
            "carbsTarget": carbsTarget,
            "fat": fat,
            "fatTarget": fatTarget,
            "streak": streak,
        ]

        if let meal = lastMeal {
            context["lastMealName"] = meal.name
            context["lastMealTime"] = meal.time
            context["lastMealCalories"] = meal.calories
        }

        try? WCSession.default.updateApplicationContext(context)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let cal = applicationContext["calories"] as? Double {
                self.todayData = WatchTodayData(
                    calories: cal,
                    target: applicationContext["target"] as? Double ?? 2100,
                    protein: applicationContext["protein"] as? Double ?? 0,
                    proteinTarget: applicationContext["proteinTarget"] as? Double ?? 160,
                    carbs: applicationContext["carbs"] as? Double ?? 0,
                    carbsTarget: applicationContext["carbsTarget"] as? Double ?? 200,
                    fat: applicationContext["fat"] as? Double ?? 0,
                    fatTarget: applicationContext["fatTarget"] as? Double ?? 65,
                    streak: applicationContext["streak"] as? Int ?? 0
                )
            }

            self.lastMealName = applicationContext["lastMealName"] as? String
            self.lastMealTime = applicationContext["lastMealTime"] as? String ?? ""
            self.lastMealCalories = applicationContext["lastMealCalories"] as? Int
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let quickLog = message["quickLog"] as? String {
            DispatchQueue.main.async {
                self.pendingQuickLog = quickLog
                NotificationCenter.default.post(
                    name: .watchQuickLogReceived,
                    object: nil,
                    userInfo: ["description": quickLog]
                )
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}

extension Notification.Name {
    static let watchQuickLogReceived = Notification.Name("watchQuickLogReceived")
}
