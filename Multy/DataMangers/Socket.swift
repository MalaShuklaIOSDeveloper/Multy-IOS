//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import SocketIO

class Socket: NSObject {
    static let shared = Socket()
    var manager : SocketManager
    var socket : SocketIOClient

    
    //do exp timeout
    
    override init() {
        //dev:  6680
        //prod: 7780
        manager = SocketManager(socketURL: URL(string: "http://88.198.47.112:7780/")!, config: [.log(true), .compress, .forceWebsockets(true), .reconnectAttempts(3), .forcePolling(false)])
        socket = manager.defaultSocket
    }
    
    func start() {
        DataManager.shared.getAccount { (account, error) in
            guard account != nil else {
                return
            }
            
            let header = ["userID": "\(account?.userID)",
                "deviceType": "\(account?.deviceType)",
                "jwtToken": "\(account?.token)"]
            
            self.manager = SocketManager(socketURL: URL(string: "http://88.198.47.112:7780")!, config: [.log(true), .compress, .forceWebsockets(true), .reconnectAttempts(3), .forcePolling(false), .extraHeaders(header)])
            self.socket = self.manager.defaultSocket
            
            
            //        let socket = manager.defaultSocket
            
            self.socket.on(clientEvent: .connect) {data, ack in
                print("socket connected")
                self.getExchangeReq()
            }
            
            self.socket.on("exchangeAll") {data, ack in
                print("-----exchangeAll: \(data)")
            }
            //"exchangeUpdate"
            self.socket.on("exchangePoloniex") {data, ack in
                print("-----exchangeUpdate: \(data)")
                if !(data is NSNull) {
                    exchangeCourse = ((data[0] as! NSDictionary)["btc_usd"] as! NSNumber).doubleValue
                }//"BTCtoUSD"
            }
            
            
            
            self.socket.on("currentAmount") {data, ack in
                guard let cur = data[0] as? Double else { return }
                
                self.socket.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
                    self.socket.emit("update", ["amount": cur + 2.50])
                }
                
                ack.with("Got your currentAmount", "dude")
            }
            
            self.socket.connect()
        }
    }
    
    func getExchangeReq() {
        let abc = NSDictionary(dictionary: ["From": "USD",
                                            "To": "BTC"]).socketRepresentation()
        
        socket.emitWithAck("/getExchangeReq", abc).timingOut(after: 0) { (data) in
            print("\n\n\n\n\n\n\n")
            print(data)
            print("\n\n\n\n\n\n\n")
        }
    }
}


