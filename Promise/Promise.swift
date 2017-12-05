//
//  Promise.swift
//  Promise
//
//  Created by bmcc on 2017/12/5.
//  Copyright © 2017年 qiupeng. All rights reserved.
//

import Foundation

enum State<Value> {
    case pending
    case fulfilled(value: Value)
    case rejected(error: Error)
}

class Promise<Value> {
    var state = State<Value>.pending

    typealias OnFulfilled = (Value) -> Void
    typealias OnRejected = (Error) -> Void

    typealias Task = (@escaping OnFulfilled, @escaping OnRejected) -> Void
    var task: Task!
    init(_ task: @escaping Task) {
        task(self.onFulfilled, self.onRejected)
    }

    init(_ value: Value) {
        onFulfilled(value)
    }

    init(_ error: Error) {
        onRejected(error)
    }

    init() {}

    var fulfillCallbacks: [OnFulfilled] = []
    var rejectCallbacks: [OnRejected] = []

    func onFulfilled(_ value: Value) {
        state = .fulfilled(value: value)
        for callback in fulfillCallbacks {
            callback(value)
        }
        fulfillCallbacks.removeAll()
    }

    func onRejected(_ error: Error) {
        state = .rejected(error: error)
        for callback in rejectCallbacks {
            callback(error)
        }
        rejectCallbacks.removeAll()
    }

    @discardableResult
    func then(_ onFulfilled: @escaping OnFulfilled, _ onRejected: @escaping OnRejected) -> Promise<Value> {
        switch state {
        case .pending:
            fulfillCallbacks.append({ (value) in
                onFulfilled(value)
            })
            rejectCallbacks.append({ (error) in
                onRejected(error)
            })
        case .fulfilled(let value):
            onFulfilled(value)
        case .rejected(let error):
            onRejected(error)
        }
        return self
    }

    @discardableResult
    func then<NewValue>(_ onFulfilled: @escaping (Value) -> Promise<NewValue>) -> Promise<NewValue> {
        return Promise<NewValue>.init({ (fulfill, reject) in
            switch self.state {
            case .pending:
                self.fulfillCallbacks.append({ (value) in
                    onFulfilled(value).then(fulfill, reject)
                })
                self.rejectCallbacks.append({ (error) in
                    reject(error)
                })
            case .fulfilled(let value):
                onFulfilled(value).then(fulfill, reject)
            case .rejected(let error):
                reject(error)
            }
        })
    }

    @discardableResult
    func then<NewValue>(_ onFulfilled: @escaping (Value) -> NewValue) -> Promise<NewValue> {
        return Promise<NewValue>.init({ (fulfill, reject) in
            switch self.state {
            case .pending:
                self.fulfillCallbacks.append({ (value) in
                    let newValue = onFulfilled(value)
                    fulfill(newValue)
                })
                self.rejectCallbacks.append({ (error) in
                    reject(error)
                })
            case .fulfilled(let value):
                let newValue = onFulfilled(value)
                fulfill(newValue)
            case .rejected(let error):
                reject(error)
            }
        })
    }

    @discardableResult
    func fail(_ reject: @escaping OnRejected ) -> Promise<Value> {
        return then({_ in}, reject)
    }
}
