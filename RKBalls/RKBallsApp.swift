//
//  RKBallsApp.swift
//  RKBalls
//
//  Created by Eric Freitas on 2/19/25.
//

import SwiftUI
import Combine

extension KeyEquivalent { //: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.character == rhs.character
    }
}

public typealias KeyInputSubject = PassthroughSubject<KeyEquivalent, Never>

public final class KeyInputSubjectWrapper: ObservableObject, Subject {
    public func send(_ value: Output) {
        objectWillChange.send(value)
    }
    
    public func send(completion: Subscribers.Completion<Failure>) {
        objectWillChange.send(completion: completion)
    }
    
    public func send(subscription: Subscription) {
        objectWillChange.send(subscription: subscription)
    }
    
    public typealias ObjectWillChangePublisher = KeyInputSubject
    public let objectWillChange: ObjectWillChangePublisher
    public init(subject: ObjectWillChangePublisher = .init()) {
        objectWillChange = subject
    }
}

// MARK: Publisher Conformance
public extension KeyInputSubjectWrapper {
    typealias Output = KeyInputSubject.Output
    typealias Failure = KeyInputSubject.Failure
    
    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Failure, S.Input == Output {
        objectWillChange.receive(subscriber: subscriber)
    }
}

@main
struct RKBallsApp: App {
    private let keyInputSubject = KeyInputSubjectWrapper()
    
    var body: some Scene {
        WindowGroup {
            ModelExample()
                .onReceive(keyInputSubject) {
                    print("Key pressed: \($0)")
                }
                .environmentObject(keyInputSubject)
        }
    }
}
