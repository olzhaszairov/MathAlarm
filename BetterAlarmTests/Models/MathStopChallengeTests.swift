import XCTest
@testable import BetterAlarm

final class MathStopChallengeTests: XCTestCase {

    func test_addition_correctAnswer() {
        let challenge = MathStopChallenge(left: 45, right: 32, operation: .add)
        XCTAssertEqual(challenge.correctAnswer, 77)
        XCTAssertEqual(challenge.equationText, "45 + 32")
        XCTAssertTrue(challenge.isCorrect(77))
        XCTAssertFalse(challenge.isCorrect(78))
    }

    func test_subtraction_correctAnswer() {
        let challenge = MathStopChallenge(left: 60, right: 23, operation: .subtract)
        XCTAssertEqual(challenge.correctAnswer, 37)
        XCTAssertEqual(challenge.equationText, "60 - 23")
        XCTAssertTrue(challenge.isCorrect(37))
    }

    func test_random_operandsWithinRange() {
        for _ in 0..<200 {
            let challenge = MathStopChallenge.random()
            XCTAssertTrue(MathStopChallenge.operandRange.contains(challenge.left))
            XCTAssertTrue(MathStopChallenge.operandRange.contains(challenge.right))
            if challenge.operation == .subtract {
                XCTAssertGreaterThanOrEqual(challenge.left, challenge.right)
            }
        }
    }
}
