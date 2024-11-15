import Flutter
import UIKit
import CallKit
import AVFoundation
import Foundation
import PushKit

@available(iOS 10.0, *)
public class SwiftFlutterCallkitPlugin: NSObject, FlutterPlugin, PKPushRegistryDelegate, CXProviderDelegate, CXCallObserverDelegate, FlutterStreamHandler {

    @objc public private(set) static var sharedInstance: SwiftFlutterCallkitPlugin!
    var uuid: UUID = UUID()
    var callRedirectKey: String = "callRedirectPref"
    var clientIdKey: String = "clientIdKey"
    var rTokenKey: String = "rTokenKey"
    var cognitoIdKey: String = "cognitoIdKey"
    var programKey: String = "programKey"
    var deviceToken: String?
    var tenant: Tenant?
    var preferences = UserDefaults.standard
    var provider: CXProvider!
    let cxCallController = CXCallController()
    var callState: String = CallKitState.onOffline
    private var sink: FlutterEventSink?
    var isCallEnded: Bool = false
    var isCallAnswered: Bool = false
    var isCallDeclined: Bool = false
    var isAppOpenedUsingCallKit: Bool = false
    var timer: Timer?
    var timerCount: Int = 0
    var callObserver = CXCallObserver()
    var callKitChannel: FlutterMethodChannel!
    var currentCallState: String = "ended"
    var isCallEndingRequestProgress: Bool = false

    public static func sharePluginWithRegister(with registrar: FlutterPluginRegistrar) {
        if (sharedInstance == nil) {
            sharedInstance = SwiftFlutterCallkitPlugin(messenger: registrar.messenger())
        }
        sharedInstance.shareHandlers(with: registrar)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        sharePluginWithRegister(with: registrar)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    public init(messenger: FlutterBinaryMessenger) {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
     }

    private func shareHandlers(with registrar: FlutterPluginRegistrar) {
        callKitChannel = FlutterMethodChannel(name: "flutter_callkit_channel", binaryMessenger: registrar.messenger())
        let callKitEventChannel = FlutterEventChannel(name: "flutter_callkit_event_channel", binaryMessenger: registrar.messenger())
        callKitEventChannel.setStreamHandler(self)
        self.initCallKitChannelMethods()
        self.initCallKit()
    }
    
    @objc func applicationDidBecomeActive() {
            self.checkAppStatus(uuid: uuid)
     }

    func initCallKit() {
     if (getBundleId() != nil && getBundleId()!.contains("carechart")) {
         tenant = Tenant.Carechart
         } else {
         tenant = Tenant.Carepath
         }
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.desiredPushTypes = Set([PKPushType.voIP])
        voipRegistry.delegate = self
        let providerConfiguration = CXProviderConfiguration(localizedName: "\(tenant == Tenant.Carechart ? "Carechart" : "Carepath") Digital Health")
        if let appIconImage = UIImage(named: "CallKitIcon") {
            providerConfiguration.iconTemplateImageData = appIconImage.pngData()
        }
        provider = CXProvider(configuration: providerConfiguration)
        callObserver.setDelegate(self, queue: nil)
    }

    func initCallKitChannelMethods(){
         callKitChannel.setMethodCallHandler({
             [self] (call: FlutterMethodCall, result:  @escaping FlutterResult) -> Void in
                 if (call.method == "callRedirect") {
                     if (self.preferences.string(forKey: callRedirectKey) == nil) {
                         result(false)
                     } else {
                         let currentVal = self.preferences.string(forKey: callRedirectKey)
                         if currentVal != nil {
                             let dateFormatter = DateFormatter()
                             dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                             let dt = dateFormatter.date(from: currentVal!) ?? Date()
                             let curdate = Date()
                             if (dt != nil && curdate < dt.addingTimeInterval(TimeInterval(1.0 * 60.0))) {
                                 result(true)
                             } else {
                                 result(false)
                             }
                         }
                         result(false)
                     }
                 } else if (call.method == "endAllCalls") {
                   self.endCall(uuid: uuid)
                 } else if (call.method == "deleteCallPref") {
                     self.deleteCallPref()
                 } else if (call.method == "printData") {
                     NSLog("data_sent: \(call.arguments)")
                 } else if (call.method == "getCachedProgram") {
                     let program = self.preferences.string(forKey: self.programKey)
                     result(program)
                 } else if (call.method == "appState") {
                     let state = UIApplication.shared.applicationState
                     if state == .active {
                         result("active")
                     } else if state == .inactive {
                         result("inactive")
                     } else if state == .background {
                         result("background")
                     }
                 }
                 else if (call.method == "storeCredential") {
                     let result = call.arguments as? [String: Any]
                     UserDefaults.standard.set(result?["rToken"], forKey: self.rTokenKey)
                     UserDefaults.standard.set(result?["clientID"], forKey: self.clientIdKey)
                     UserDefaults.standard.set(result?["cognitoId"], forKey: self.cognitoIdKey)
                     self.preferences.synchronize()
                 }
                 else
                 if (call.method == "checkCallAnswered") {
                     result(self.isCallAnswered)
                 } else if (call.method == "checkCallDeclined") {
                     result(self.isCallDeclined)
                 } else if (call.method == "getVoipToken") {
                     result(deviceToken)
                 } else
                 if (call.method == "setAppOpenedUsingCallKit") {
                     let result = call.arguments as! Bool
                     isAppOpenedUsingCallKit = result
                 }
            })
    }
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        deviceToken = pushCredentials.token.reduce("", {$0 + String(format: "%02X", $1) })
    }
    public func pushRegistry(_ registry: PKPushRegistry,didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        UserDefaults.standard.set(Date().iso8601withFractionalSeconds, forKey: self.callRedirectKey)
        self.preferences.synchronize()
        let rToken = self.preferences.string(forKey: self.rTokenKey)
        let clientId = self.preferences.string(forKey: self.clientIdKey)
        guard let payloadDict = payload.dictionaryPayload as? [String: Any] else {
               return
           }
        if let program = payloadDict["program"] as? String {
            UserDefaults.standard.set(program, forKey: self.programKey)
           }
        self.isCallEnded = false
        self.isCallDeclined = false
        let state = UIApplication.shared.applicationState
        let callerName = "\(tenant == Tenant.Carechart ? "CareChart" : program=="cancer" || program=="chronic-disease" || program=="elder-care" ? "Carepath" : "Mental Health") Clinician is calling you"
        provider.setDelegate(self, queue: nil)
        let update = CXCallUpdate()
        update.localizedCallerName = callerName
        provider.configuration.supportsVideo = true
        update.hasVideo = true
        provider.configuration.supportedHandleTypes = [.generic]
        provider.reportNewIncomingCall(with: uuid, update: update, completion: {
            error in
            if let error = error {
                print("Error: \(error)")
            } else {
                self.isCallAnswered = false
                if(clientId == ""){
                        self.endCall(uuid: self.uuid)
                }else{
                    self.timerCount = 0
                    self.callState = CallKitState.onStartCall
                    NetworkRequest.init(tenant: self.tenant, bToken: nil, iToken: nil)
                        .refreshToken(clientId: clientId, rToken: rToken,completion: { (jsonObj) -> () in
                            let tokenResp = jsonObj["AuthenticationResult"] as! [String: Any]
                            DispatchQueue.main.async { [weak self] in
                                self?.timer = Timer.scheduledTimer(timeInterval: 5.0,
                                                                   target: self,
                                                                   selector: #selector(self?.eventWith(timer:)),
                                                                   userInfo: tokenResp,
                                                                   repeats: true)
                            }


                        })
                    if(self.sink != nil){
                        var message = [String: Any]()
                        message["event"] = "\(CallKitState.onStartCall)"
                        self.sink!(message)
                    }
                }

            }
        })
        self.currentCallState = "connected"
        completion()
        self.checkAppStatus(uuid: self.uuid);

    }
    @objc func eventWith(timer: Timer!) {
        let tokenResp = timer.userInfo as! [String : Any]
        let cognitoId = self.preferences.string(forKey: self.cognitoIdKey)
        let program = self.preferences.string(forKey: self.programKey)
        NetworkRequest.init(tenant: self.tenant, bToken: tokenResp["AccessToken"] as! NSString, iToken: tokenResp["IdToken"] as! NSString).getCallInfo(
            cognitoId: cognitoId,
            program: program,
            completion: { (jsonObject) -> () in
                if(jsonObject != nil){
                    let jsObject = jsonObject as! [String: Any]
                    let jsCallInfo = jsonObject["callInfo"] as! [String: Any]
                    let duration: Int = jsonObject["callRingDuration"] as? Int ?? 1
                    if(jsCallInfo["callStatus"] as! String == "initiated"){
                        if ( self.timerCount >= duration*60 ){
                            var callInfo = [String:Any]()
                            callInfo = jsonObject["callInfo"] as! [String:Any]
                            if(self.callState == "\(CallKitState.onStartCall)"){
                                let rToken = self.preferences.string(forKey: self.rTokenKey)
                                let clientId = self.preferences.string(forKey: self.clientIdKey)
                                NetworkRequest.init(tenant: self.tenant, bToken: tokenResp["AccessToken"] as! NSString, iToken: tokenResp["IdToken"] as! NSString).putStatus(meetingId: callInfo["meetingId"] as? NSString ?? "", encounterId: "\(callInfo["encounterId"])" as NSString, status: "missed",completion: { (jsonObject) -> () in

                                })
                            }
                            self.clearTimer(isEndCallNeeded: true)
                        }
                    }
                    else{
                        self.clearTimer(isEndCallNeeded: true)
                    }
                    self.timerCount = self.timerCount+5
                }
                else{
                    self.clearTimer(isEndCallNeeded: true)
                }
            },onError: { (err) -> () in
                self.clearTimer(isEndCallNeeded: !err)
            })
    }
    func clearTimer(isEndCallNeeded: Bool){
        self.callState = CallKitState.onOffline
        if(isEndCallNeeded){
        self.endCall(uuid: self.uuid)
        }
        self.timerCount = 0
        timer?.invalidate()
    }
    private func sendMessageToFlutter(method:String,argument:String){
        self.callKitChannel.invokeMethod(method, arguments: argument)
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            sink = events
        return nil
    }


    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        sink = nil
        return nil
    }
    func endCall(uuid: UUID, completion: ((Error?) -> Void)? = nil) {
        if(!isCallEndingRequestProgress && self.currentCallState != "ended"){
            self.isCallEndingRequestProgress = true
            let endCallAction = CXEndCallAction(call: uuid)
            let transaction = CXTransaction(action: endCallAction)
            cxCallController.request(transaction) { error in
                self.timerCount = 0
                self.isCallEnded = true
                self.callState = CallKitState.onCallEnd
                self.provider.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
                if let error = error {
                    print("Error ending call: \(error.localizedDescription)")
                    self.isCallEndingRequestProgress = false
                    return
                }
                self.isCallEndingRequestProgress = false
                completion?(error)
            }
        }
    }

    public func providerDidReset(_ provider: CXProvider) {

    }

    public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        var message = [String: Any]()
        if call.hasEnded && !self.isCallEnded {
                   self.isCallDeclined = true
                   let rToken = self.preferences.string(forKey: self.rTokenKey)
                   let clientId = self.preferences.string(forKey: self.clientIdKey)
                   let cognitoId = self.preferences.string(forKey: self.cognitoIdKey)
                   let program = self.preferences.string(forKey: self.programKey)
            NetworkRequest.init(tenant: self.tenant, bToken: nil, iToken: nil).refreshToken(clientId: clientId, rToken: rToken,completion: { (jsonObj) -> () in
                       let tokenResp = jsonObj["AuthenticationResult"] as! [String: Any]
                NetworkRequest.init(tenant: self.tenant, bToken: tokenResp["AccessToken"] as! NSString, iToken: tokenResp["IdToken"] as! NSString).getCallInfo(
                           cognitoId: cognitoId,
                           program: program,
                           completion: { (jsonObject) -> () in
                               if(jsonObject != nil){
                                   let duration: Int = jsonObject["callRingDuration"] as? Int ?? 1
                                   var callInfo = [String:Any]()
                                   callInfo = jsonObject["callInfo"] as! [String:Any]
                                   if(self.callState == "\(CallKitState.onStartCall)"){
                                       NetworkRequest.init(tenant: self.tenant,bToken: tokenResp["AccessToken"] as! NSString, iToken: tokenResp["IdToken"] as! NSString).putStatus(meetingId: callInfo["meetingId"] as? NSString ?? "", encounterId: "\(callInfo["encounterId"])" as NSString, status: "rejected",completion: { (jsonObject) -> () in

                                       })
                                   }
                                   self.callState = CallKitState.onOffline

                               }

                           },onError: { (_) -> () in

                           })
                   })
           }
        if call.hasEnded{
            self.currentCallState = "ended"
        }else if call.hasConnected{
            self.currentCallState = "connected"
        }else{
            self.currentCallState = "ringing"
        }
       }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
         self.currentCallState = "answered"
        self.isAppOpenedUsingCallKit = true
        self.isCallAnswered = true
        timer?.invalidate()
        self.callState = CallKitState.onAnswerCall
        UserDefaults.standard.set(Date().iso8601withFractionalSeconds, forKey: self.callRedirectKey)
        self.preferences.synchronize()
        if(self.sink != nil){
            var message = [String: Any]()
            message["event"] = "\(CallKitState.onAnswerCall)"
            self.sink!(message)
        }
        self.checkAppStatus(uuid: uuid);
        action.fulfill()
    }
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        self.currentCallState = "ended"
        self.isAppOpenedUsingCallKit = false
        self.timerCount = 0
        timer?.invalidate()
        if(self.sink != nil){
            if(self.sink != nil){
                var message = [String: Any]()
                if(self.isCallEnded){
                    message["event"] = "\(CallKitState.onCallEnd)"
                }else{
                    message["event"] = "\(CallKitState.onRejectCall)"
                }
              self.sink!(message)
            }
        }
        action.fulfill()
    }

    private func checkAppStatus(uuid: UUID){
        let state = UIApplication.shared.applicationState
        if state == .active {
        if(!isAppOpenedUsingCallKit){
            self.endCall(uuid: uuid)
            }
        }
        else if state == .inactive {

        }
        else if state == .background {

        }

    }
    private func deleteCallPref(){
        preferences.removeObject(forKey: callRedirectKey)
    }
}

 func getBundleId() -> String? {
   return Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
 }

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options) {
        self.init()
        self.formatOptions = formatOptions
    }
}
extension String {
    var iso8601withFractionalSeconds: Date? { return Formatter.iso8601withFractionalSeconds.date(from: self) }
}
extension Date {
    var iso8601withFractionalSeconds: String { return Formatter.iso8601withFractionalSeconds.string(from: self) }
}
extension Formatter {
    static let iso8601withFractionalSeconds = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}
enum CallKitState {
    static let onAnswerCall = "onAnswerCall"
    static let onCallEnd = "onCallEnd"
    static let onStartCall = "onStartCall"
    static let onRejectCall = "onRejectCall"
    static let onOffline = "onOffline"
}
enum AppState {
    static let onActive = "active"
    static let onInactive = "inactive"
    static let onBackground = "background"
}

enum Tenant {
    case Carechart
    case Carepath
}
