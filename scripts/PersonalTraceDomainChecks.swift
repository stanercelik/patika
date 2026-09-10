import Foundation

@main
enum PersonalTraceDomainChecks {
    static func main() {
        checkPhaseBoundaries()
        checkPhaseStarts()
        checkFallbackMeasurementPhase()
        checkTechniqueSummary()
        checkRouteLayout()
        print("PersonalTraceDomainChecks passed")
    }

    private static func checkPhaseBoundaries() {
        let expected: [(day: Int, phase: PathPhase)] = [
            (1, .relief),
            (3, .relief),
            (4, .awareness),
            (7, .awareness),
            (8, .skill),
            (14, .skill),
            (15, .behavior),
            (20, .behavior),
            (21, .closing),
        ]

        for item in expected {
            require(
                PathPlan.phase(on: item.day, length: .threeWeeks) == item.phase,
                "day \(item.day) should belong to \(item.phase.rawValue)"
            )
        }
    }

    private static func checkPhaseStarts() {
        for day in [1, 4, 8, 15, 21] {
            require(
                PathPlan.startsPhase(on: day, length: .threeWeeks),
                "day \(day) should start a phase"
            )
        }

        for day in [2, 7, 14, 20] {
            require(
                !PathPlan.startsPhase(on: day, length: .threeWeeks),
                "day \(day) should not start a phase"
            )
        }
    }

    private static func checkFallbackMeasurementPhase() {
        let row = PathPlan.Row.measurement(day: 7, isFirst: true)
        require(
            PathPlan.phase(for: row, length: .threeWeeks) == .awareness,
            "day 7 measurement should stay in the awareness phase"
        )
    }

    private static func checkTechniqueSummary() {
        require(
            BlockLibrary.techniqueSummary(for: [
                "breath.awareness.v1",
                "unknown.future.block",
                "body.grounding.v1",
            ]) == "Nefesi fark etmek · Bedene dönmek",
            "known block titles should stay ordered and unknown blocks should be skipped"
        )
        require(
            BlockLibrary.techniqueSummary(for: ["unknown.future.block"]) == nil,
            "an entirely unknown block list should not invent a technique"
        )
    }

    private static func checkRouteLayout() {
        let phases: [PathPhase?] = [
            .relief,
            .relief,
            .awareness,
            .skill,
            .closing,
        ]
        let positions = JourneyRouteLayout.positions(
            for: phases,
            usesAccessibleLayout: false
        )

        require(positions.count == phases.count, "route position count should match row count")
        require(positions[0].currentX == 0.40, "relief should begin near the center")
        require(positions[1].currentX == 0.58, "relief should use its compact second turn")
        require(positions[2].currentX == 0.38, "awareness should use its phase rhythm")
        require(positions[3].currentX == 0.74, "skill should use the widest phase rhythm")
        require(positions[4].currentX == 0.46, "closing should settle near the center")
        require(
            positions[2].previousX == positions[1].currentX
                && positions[2].nextX == positions[3].currentX,
            "neighbor coordinates should meet at the same row boundary"
        )
        require(
            JourneyRouteLayout.positions(for: [], usesAccessibleLayout: false).isEmpty,
            "an empty path should produce no positions"
        )

        let accessible = JourneyRouteLayout.positions(
            for: phases,
            usesAccessibleLayout: true
        )
        require(
            accessible.allSatisfy {
                $0.previousX == 0.10 && $0.currentX == 0.10 && $0.nextX == 0.10
            },
            "accessibility layout should use one stable left rail"
        )
        require(
            positions == JourneyRouteLayout.positions(
                for: phases,
                usesAccessibleLayout: false
            ),
            "the same path should always produce the same geometry"
        )
    }

    private static func require(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String
    ) {
        guard condition() else { fatalError(message()) }
    }
}
