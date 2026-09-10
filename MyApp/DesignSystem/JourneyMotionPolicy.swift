import Foundation

/// Kişisel İz'in sürekli hareket için tek güvenlik kararı.
struct JourneyMotionPolicy: Equatable {
    let reduceMotion: Bool
    let sceneIsActive: Bool
    let lowPowerMode: Bool
    let thermalState: ProcessInfo.ThermalState

    var pausesContinuousMotion: Bool {
        reduceMotion
            || !sceneIsActive
            || lowPowerMode
            || thermalState == .serious
            || thermalState == .critical
    }

    static let minimumInterval = 1.0 / 60.0
}
