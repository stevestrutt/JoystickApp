//
//  ViewController.swift
//  JoystickTestApp
//


import UIKit
import Starscream


class ViewController: UIViewController, WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("Received text: \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("Received data: \(data.count)")
    }
    
    var socket = WebSocket(url: URL(string: "http://192.168.1.76:81")!, protocols: ["chat"])
    
    @IBAction func writeText(_ sender: UIBarButtonItem) {
        socket.write(string: "hello there!")
    }
    
    // MARK: Disconnect Action
    @IBAction func disconnect(_ sender: UIButton) {
    
        if socket.isConnected {
            sender.setTitle("Connect", for: .normal)
            socket.disconnect()
        } else {
            sender.setTitle("Disconnect", for: .normal)
            socket.connect()
        }
    }

    var timer : Timer?
    func startTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.postWsMethod), userInfo: nil, repeats: true)
        }
    }
    
    func StopTimerNotication(notification: NSNotification){
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }

    
    @IBOutlet weak var leftMagnitude: UILabel!
    @IBOutlet weak var leftTheta: UILabel!
    @IBOutlet weak var rightMagnitude: UILabel!
    @IBOutlet weak var rightTheta: UILabel!

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: Selector(("StopTimerNoticationFunction:")), name:NSNotification.Name(rawValue: "StopTimerNotification"), object: nil)
        socket.delegate = self
        socket.connect()
        
        
        
        
        }
        // Do any additional setup after loading the view, typically from a nib.
    
   
    
    
    var count = 0;
    public var sendTimerFired: Bool = false;
    func postWsMethod() {
        count += 1;
        sendTimerFired = true;
        //print("Timer fired: "); print( "\(count)");
       
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        
        // Rate limit date sent to ESP32
        startTimer();
   
        // Create 'fixed' joystick
        let rect = view.frame
        let size = CGSize(width: 80.0, height: 80.0)
        let joystick1Frame = CGRect(origin: CGPoint(x: 40.0, y: (rect.height - size.height - 40.0)), size: size)
        let joystick1 = JoyStickView(frame: joystick1Frame)
        joystick1.monitor = { angle, displacement in
            
            

            // Rate limit by only sending latest values when timer fires 10 times a second.
            // Check if timer has fired and send to ESP32 if yes
            if (self.sendTimerFired) {
                var sentAngle: Int
                sentAngle = Int(round(angle));
                self.sendTimerFired = false;   // reset timerfired flag until next timer iteration
                // send data to web socket
                let webdata = "\(sentAngle)";
                self.socket.write(string: webdata);
                print("time:  "); print(Date());
            }
            
            // update display
            self.leftTheta.text = "\(angle)"
            self.leftMagnitude.text = "\(displacement)"
            
            
            
        }

        view.addSubview(joystick1)

        joystick1.movable = false
        joystick1.alpha = 1.0
        joystick1.baseAlpha = 0.5 // let the background bleed thru the base
        joystick1.handleTintColor = UIColor.green // Colorize the handle

        let joystick2Frame = CGRect(origin: CGPoint(x: (rect.width - size.width - 40.0),
                                                    y: (rect.height - size.height - 40.0)),
                                    size: size)
        let joystick2 = JoyStickView(frame: joystick2Frame)
        joystick2.monitor = { angle, displacement in
            self.rightTheta.text = "\(angle)"
            self.rightMagnitude.text = "\(displacement)"
        }

        view.addSubview(joystick2)

        joystick2.movable = false
        joystick2.alpha = 1.0
        joystick2.baseAlpha = 0.5 // let the background bleed thru the base
        joystick2.handleTintColor = UIColor.blue // Colorize the handle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

