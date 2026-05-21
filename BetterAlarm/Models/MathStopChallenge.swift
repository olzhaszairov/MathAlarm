import Foundation

// MARK: - MathStopChallenge

/// 알람 정지용 산술 문제. 피연산자 10…999, 덧셈·뺄셈만.
struct MathStopChallenge: Sendable, Equatable {
    enum Operation: Sendable, Equatable {
        case add
        case subtract
    }

    static let operandRange = 10...999

    let left: Int
    let right: Int
    let operation: Operation

    var correctAnswer: Int {
        switch operation {
        case .add: left + right
        case .subtract: left - right
        }
    }

    /// 예: "45 + 32", "87 - 23"
    var equationText: String {
        let symbol = operation == .add ? "+" : "-"
        return "\(left) \(symbol) \(right)"
    }

    func isCorrect(_ answer: Int) -> Bool {
        answer == correctAnswer
    }

    static func random() -> MathStopChallenge {
        if Bool.random() {
            let left = Int.random(in: operandRange)
            let right = Int.random(in: operandRange)
            return MathStopChallenge(left: left, right: right, operation: .add)
        }

        let left = Int.random(in: operandRange)
        let right = Int.random(in: operandRange.lowerBound...left)
        return MathStopChallenge(left: left, right: right, operation: .subtract)
    }
}
