import Foundation
import Combine
import _Concurrency
import SwiftUI

public extension View {
  func task(
    priority: TaskPriority = .userInitiated,
    _ action: @escaping () async -> Void
  ) -> some View {
    modifier(TaskModifier(
      priority: priority,
      action: action
    ))
  }
}

private struct TaskModifier: ViewModifier {
  var priority: TaskPriority
  var action: () async -> Void

  @State private var task: Task<Void, Never>?

  func body(content: Content) -> some View {
    content
      .onAppear {
        task = Task(priority: priority) {
          await action()
        }
      }
      .onDisappear {
        task?.cancel()
        task = nil
      }
  }
}

public extension AnyPublisher {
  var asyncThrowingStream: AsyncThrowingStream<Output, Error> {
    AsyncThrowingStream { continuation in
      var cancellable: AnyCancellable?
      let onTermination = { cancellable?.cancel() }
      continuation.onTermination = { @Sendable _ in
        onTermination()
      }
      cancellable = sink(
        receiveCompletion: { completion in
          switch completion {
            case .finished:
              continuation.finish()
            case .failure(let error):
              continuation.finish(throwing: error)
          }
        }, receiveValue: { value in
          continuation.yield(value)
        }
      )
    }
  }
}

public extension AnyPublisher where Failure == Never {
  var asyncStream: AsyncStream<Output> {
    AsyncStream { continuation in
      var cancellable: AnyCancellable?
      let onTermination = { cancellable?.cancel() }
      continuation.onTermination = { @Sendable _ in
        onTermination()
      }
      cancellable = sink(
        receiveCompletion: { _ in
          continuation.finish()
        }, receiveValue: { value in
          continuation.yield(value)
        }
      )
    }
  }
}

  // MARK: - Extension : AnyPublisher + _Concurrency
public extension AnyPublisher {
  func asyncSink(
    cancellables: inout Set<AnyCancellable>,
    completion: @autoclosure @escaping(() async throws -> ()) = {}(),
    finishedWithoutValue : @autoclosure @escaping(() async throws -> ()) = {}()
  ) async throws -> Output {
    var checkedContinuation: CheckedContinuation<Output, Error>?
    return try await withCheckedThrowingContinuation { continuation in
      checkedContinuation = continuation
      var isFinishedWithoutValue = true
      self.sink { result in
        Task { try await completion() }
        switch result {
          case .failure(let error):
            checkedContinuation?.resume(with: .failure(error))
            checkedContinuation = nil
          case .finished:
            if isFinishedWithoutValue {
              Task { try await finishedWithoutValue() }
            }
        }
      } receiveValue: { result in
        isFinishedWithoutValue = false
        checkedContinuation?.resume(with: .success(result))
        checkedContinuation = nil
      }
      .store(in: &cancellables)
    }
  }
}

public extension AnyPublisher {
  func asyncFirst(
    completion: @autoclosure @escaping(() async throws -> ()) = {}(),
    finishedWithoutValue : @autoclosure @escaping(() async throws -> ()) = {}()
  ) async throws -> Output {
    var checkedContinuation: CheckedContinuation<Output, Error>?
    return try await withCheckedThrowingContinuation { continuation in
      checkedContinuation = continuation
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
              checkedContinuation?.resume(throwing: error)
              checkedContinuation = nil
          }
          cancellable?.cancel()
        } receiveValue: { value in
          isCompletion = true
          Task { try await completion() }
          isFinishedWithoutValue = false
          checkedContinuation?.resume(with: .success(value))
          checkedContinuation = nil
        }
    }
  }
}
