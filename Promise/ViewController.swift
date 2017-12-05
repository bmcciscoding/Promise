//
//  ViewController.swift
//  Promise
//
//  Created by bmcc on 2017/12/5.
//  Copyright © 2017年 qiupeng. All rights reserved.
//

import UIKit

enum PromiseError: Error {
    case wrongInfo
    case network
    case system
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

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

        // Promise
        fecthNetworkDataByPromise(url: "api/v1/list")
            .then { (result) -> Promise<Bool> in
                return self.fecthSystemDataByPromise()
            }
            .then { (result) -> Promise<Bool> in
                return self.fecthNetworkDataByPromise(url: "api/v1/info")
            }
            .then { (result) -> String in
                print("ok")
                return "ok"
            }
            .fail { (error) in
                print(error)
            }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    typealias AsyncCallback = (Bool) -> ()

    func fetchNetworkData(url: String, _ callback: @escaping AsyncCallback) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            callback(true)
        }
    }

    func fecthSystemData(_ callback: @escaping AsyncCallback) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            callback(true)
        }
    }

    func fecthNetworkDataByPromise(url: String) -> Promise<Bool> {
        return Promise<Bool>.init({ (fulfill, reject) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let result = arc4random_uniform(20)
                if result > 3 {
                    fulfill(true)
                } else {
                    reject(PromiseError.network)
                }
            }
        })
    }

    func fecthSystemDataByPromise() -> Promise<Bool> {
        return Promise<Bool>.init({ (fulfill, reject) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let result = arc4random_uniform(10)
                if result > 3 {
                    fulfill(true)
                } else {
                    reject(PromiseError.system)
                }
            }
        })
    }

}


