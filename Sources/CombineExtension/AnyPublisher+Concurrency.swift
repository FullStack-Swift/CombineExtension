import Foundation
import Combine
import _Concurrency

// MARK: - Extension : AnyPublisher + _Concurrency
public extension AnyPublisher {
  func asyncSink(
    continuations: inout [CheckedContinuation<Output, any Error>],
    cancellables: inout Set<AnyCancellable>,
    completion: @autoclosure @escaping(() async throws -> ()) = {}(),
    finishedWithoutValue : @autoclosure @escaping(() async throws -> ()) = {}()
  ) async throws -> Output {
    return try await withCheckedThrowingContinuation { continuation in
      continuations.append(continuation)
      var isFinishedWithoutValue = true
      self.sink { result in
        Task { try await completion() }
        switch result {
          case .failure(let error):
            continuation.resume(with: .failure(error))
          case .finished:
            if isFinishedWithoutValue {
              Task { try await finishedWithoutValue() }
            }
        }
      } receiveValue: { result in
        isFinishedWithoutValue = false
        continuation.resume(with: .success(result))
      }
      .store(in: &cancellables)
    }
  }
}

public extension AnyPublisher {
  func asyncFirst(
    continuations: inout [CheckedContinuation<Output, any Error>],
    completion: @autoclosure @escaping(() async throws -> ()) = {}(),
    finishedWithoutValue : @autoclosure @escaping(() async throws -> ()) = {}()
  ) async throws -> Output {
    try await withCheckedThrowingContinuation { continuation in
      continuations.append(continuation)
      var cancellable: AnyCancellable?
      var isFinishedWithoutValue = true
      var isCompletion = false
      cancellable = first()
        .sink { result in
          if !isCompletion {
            Task { try await completion() }
          }
          switch result {
            case .finished:
              if isFinishedWithoutValue {
                Task { try await finishedWithoutValue() }
              }
            case let .failure(error):
              continuation.resume(throwing: error)
          }
          cancellable?.cancel()
        } receiveValue: { value in
          isCompletion = true
          Task { try await completion() }
          isFinishedWithoutValue = false
          continuation.resume(with: .success(value))
        }
    }
  }
}
