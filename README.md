# 实现自己的 Promise

### 为什么要使用 Promise

首先需要明白，Promise  是解决异步操作某些问题的一套开源的解决方法

参考 [PromiseA+](https://promisesaplus.com)

闭包是 Swift 中常用的回调方式，但是连续使用闭包写起来会有一些奇怪

比如

```swift
typealias AsyncCallback = (Bool) -> ()
func fetchNetworkData(url: String, _ callback: @escaping AsyncCallback) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        callback(true)
    }
}
func fecthSystemData(_ callback: @escaping AsyncCallback) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        callback(true)
    }
}
```

首先，我在 ViewController 定义了这两个方法模拟实际开发中异步操作，比如从服务端获取数据，一些系统框架的异步返回的数据。

使用起来就会变成这样

```swift
// Callback hell
fetchNetworkData(url: "api/v1/list") { (result) in
    if result {
        self.fecthSystemData({ (result) in
            if result {
                self.fetchNetworkData(url: "api/v1/info", { (result) in
                    if result {
                        // do something
                    } else {
                        // handler error
                    }
                })
            } else {
                // handle error
            }
        })
    } else {
        // handle error
    }
}
```

这样的代码看起来会比较费劲，造成维护十分不方便，如果你遇到了这样的情况，想重构代码可以参考 Promise 的实现。使用 Promise 就会变成这样

```swift
// Promise
fecthNetworkDataByPromise(url: "api/v1/list")
    .then { (result) -> Promise<Bool> in
        return self.fecthSystemDataByPromise()
    }
    .then { (result) -> Promise<Bool> in
        return self.fecthNetworkDataByPromise(url: "api/v1/info")
    }
    .then { (result) -> String in
        return "ok"
    }
    .fail { (error) in
        print(error)
    }
```

只用定义两个方法

```Swift
  func fecthNetworkDataByPromise(url: String) -> Promise<Bool> {
      return Promise<Bool>.init({ (fulfill, reject) in
          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              fulfill(true)
          }
      })
  }

  func fecthSystemDataByPromise() -> Promise<Bool> {
      return Promise<Bool>.init({ (fulfill, reject) in
          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              fulfill(true)
          }
      })
  }
```

Github 上也有很多优秀的第三方库，比如 [PromiseKit](https://github.com/mxcl/PromiseKit) 可以直接使用，但是你也可以选择自己去实现。一个简单的

Promise 代码也就100行。

### 怎么实现 Promise

Promise 是一个对象，有三种状态，分别是 pending、fulfilled、rejected。

当状态是 pending 时，可以变为 fulfilled，并且携带一个 Value。也可以变为 rejected，需要抛出一个异常，说明 reject 的原因。

写成代码就是

```swift
enum State<Value> {
    case pending
    case fulfilled(value: Value)
    case rejected(error: Error)
}

class Promise<Value> {
  var state = State.pending
}
```

他需要一个 then 方法，这个方法会需要两个参数，onFulfilled 和 onRejected。当 Promise 的状态变为 fulfilled 时触发 onFulfilled。变为 rejected 时触发 onRejected。

```swift
// 定义两个回调
typealias OnFulfilled = (Value) -> Void
typealias OnRejected = (Error) -> Void
// 保存回调，在合适的时候执行
var fulfillCallbacks: [OnFulfilled] = []
var rejectCallbacks: [OnRejected] = []
// 传入两个参数
func then(_ onFulfilled: @escaping OnFulfilled, 
          _ onRejected: @escaping OnRejected) -> Promise<Value> {
  switch state {
  // 若此时 promise 还没执行完，则需要保存
  case .pending:
      fulfillCallbacks.append({ (value) in
          fulfill(value)
      })
      rejectCallbacks.append({ (error) in
          reject(error)
      })
  // 直接处理
  case .fulfilled(let value):
      fulfill(value)
  case .rejected(let error):
      reject(error)
  }
  return self
}
```

之后补上 Promise 的初始化方法

```swift
typealias Task = (@escaping OnFulfilled, @escaping OnRejected) -> Void
// 立即执行
init(_ task: @escaping Task) {
    task(self.onFulfilled, self.onRejected)
}
// fulfilled 的 Promise
init(_ value: Value) {
    onFulfilled(value)
}
// reject 的 Promise
init(_ error: Error) {
    onRejected(error)
}		
```

至此，已经基本实现了 Promise，但是使用起来还是不太方便。比如说，希望一个 Promise 之后再执行一个 Promise。或者希望把 Promise 的值转换成变的格式。

### Map

```swift
@discardableResult 
func then<NewValue>(_ onFulfilled: @escaping (Value) -> NewValue) -> Promise<NewValue> {
    return Promise<NewValue>.init({ (fulfill, reject) in
        switch self.state {
        // 保存
        case .pending:
            self.fulfillCallbacks.append({ (value) in
                let newValue = onFulfilled(value)
                fulfill(newValue)
            })
            self.rejectCallbacks.append({ (error) in
                reject(error)
            })
        // 直接执行
        case .fulfilled(let value):
            let newValue = onFulfilled(value)
            fulfill(newValue)
        case .rejected(let error):
            reject(error)
        }
    })
}
```

### FlatMap

```swift
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
```

这样实现之后，就可以像一开始的那样使用了。但是这仅仅是一部分，未完待续...
