import XCTest
import Combine

@testable import CombineExtension

final class CombineExtensionTests: XCTestCase {
  func testExample() async throws {
    XCTAssertEqual(1, 1)
    let value = try await Just(1)
      .eraseToAnyPublisher()
      .delay(for: 1, scheduler: DispatchQueue.main)
      .eraseToAnyPublisher()
      .async(
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
      .async()
    XCTAssertEqual(1, value)
  }
}
