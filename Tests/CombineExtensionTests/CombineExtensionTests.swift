import XCTest
import Combine

@testable import CombineExtension

final class CombineExtensionTests: XCTestCase {
  
  var continuations = [CheckedContinuation<Int, any Error>]()
  var cancellables = Set<AnyCancellable>()
  
  func testExampleAsyncFirst() async throws {
    XCTAssertEqual(1, 1)
    let publisher: AnyPublisher<Int, Never> = Array(1..<100).publisher
      .eraseToAnyPublisher()
    let value = try await publisher
      .asyncFirst(
        completion: {
          XCTAssertEqual(1, 1)
          print("completion")
        }()
      )
    XCTAssertEqual(1, value)
  }
  
  func testExampleAsyncSink() async throws {
    XCTAssertEqual(1, 1)
    let publisher: AnyPublisher<Int, Never> = Array(1..<100).publisher
      .eraseToAnyPublisher()
    let value = try await publisher
      .asyncSink(cancellables: &cancellables)
    let array = Array(1..<100)
    XCTAssertEqual(array.first!, value)
  }

  func testExampleAsyncThrowingStream() async throws {
    XCTAssertEqual(1, 1)
    let publisher: AnyPublisher<Int, Never> = Array(1..<100).publisher
      .eraseToAnyPublisher()
    var valueAsync = [Int]()
    for try await item in publisher.asyncThrowingStream {
      if item == 100 {
        throw NSError(domain: "Error", code: 100)
      }
      valueAsync.append(item)
    }
    var valueSink = [Int]()
    publisher.sink { value in
      valueSink.append(value)
    }
    .store(in: &cancellables)
    XCTAssertEqual(valueAsync, valueAsync)
  }

  func testExampleAsyncStream() async throws {
    XCTAssertEqual(1, 1)
    let publisher: AnyPublisher<Int, Never> = Array(1..<100).publisher
      .eraseToAnyPublisher()

    var valueAsync = [Int]()
    for await item in publisher.asyncStream {
      valueAsync.append(item)
    }
    var valueSink = [Int]()
    publisher.sink { value in
      valueSink.append(value)
    }
    .store(in: &cancellables)

    XCTAssertEqual(valueAsync, valueAsync)
  }
}
