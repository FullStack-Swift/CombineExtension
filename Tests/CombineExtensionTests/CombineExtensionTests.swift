import XCTest
import Combine

@testable import CombineExtension

final class CombineExtensionTests: XCTestCase {
  
  var continuations = [CheckedContinuation<Int, any Error>]()
  
  func testExample() async throws {
    XCTAssertEqual(1, 1)
    let value = try await Just(1)
      .eraseToAnyPublisher()
      .delay(for: 1, scheduler: DispatchQueue.main)
      .eraseToAnyPublisher()
      .asyncFirst(
        continuations: &continuations,
        completion: XCTAssertEqual(1, 1)
      )
    XCTAssertEqual(1, value)
  }
  
  func testExample2() async throws {
    XCTAssertEqual(1, 1)
    let value = try await Just(1)
      .eraseToAnyPublisher()
      .delay(for: 1, scheduler: DispatchQueue.main)
      .eraseToAnyPublisher()
      .asyncFirst(
        continuations: &continuations
      )
    XCTAssertEqual(1, value)
  }
}
