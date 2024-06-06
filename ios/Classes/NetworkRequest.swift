import Foundation

class NetworkRequest{
    var bToken: NSString?
    var iToken: NSString?
    var tenant: Tenant?
    required init(tenant: Tenant!,bToken: NSString?,iToken: NSString?){
        self.bToken = bToken
        self.iToken = iToken
        self.tenant = tenant
    }
    
    func putStatus(meetingId: NSString, encounterId: NSString, status: NSString,  completion: @escaping (Bool)->()) {
        let schemeName = Bundle.main.infoDictionary!["CURRENT_SCHEME_NAME"] as! String
        guard let url = URL(string: self.tenant == Tenant.Carechart ?
        "\(schemeName == "dev" ? "https://dev-api.carechartathome.ca/verto/api/v1" : "https://api.carechartathome.ca/verto/api/v1")/meetings/\(meetingId)/status/"
        :
        "\(schemeName == "dev" ? "https://dev-api.carepathdigitalhealth.ca/verto/api/v1" : "https://api.carepathdigitalhealth.ca/verto/api/v1")/meetings/\(meetingId)/status/") else {
            print("Error: cannot create URL")
            return
        }
        
        let json: [String: Any] = ["status": status,
                                   "encounterId": Int(encounterId as String)]

        let jsonBody = try? JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonBody
        request.setValue("Bearer " + (bToken as! String), forHTTPHeaderField: "Authorization")
        request.setValue("Identity " + (iToken as! String), forHTTPHeaderField: "Identity")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error: error calling PUT")
                print(error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                print("Error: HTTP request failed")
                return
            }
            completion(true)

        }.resume()
    }
    func getCallInfo(cognitoId: String?, program: String?, completion: @escaping ([String : Any])->(), onError: @escaping (_ param: Bool) -> Void) {

        let schemeName = Bundle.main.infoDictionary!["CURRENT_SCHEME_NAME"] as! String
        let uri =
        self.tenant == Tenant.Carechart ? "\(schemeName == "dev" ? "https://dev-api.carechartathome.ca/verto/api/v1" : "https://api.carechartathome.ca/verto/api/v1")/encounter/active/call-info/"
        :
        "\(schemeName == "dev" ? "https://dev-api.carepathdigitalhealth.ca/verto/api/v1" : "https://api.carepathdigitalhealth.ca/verto/api/v1")/carepath/portal-users/\(cognitoId!)/programs/\(program!)/encounters/active/call-info/"
        guard let url = URL(string: uri) else {
            print("Error: cannot create URL")
            onError(true)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer " + (bToken as! String), forHTTPHeaderField: "Authorization")
        request.setValue("Identity " + (iToken as! String), forHTTPHeaderField: "Identity")

        URLSession.shared.dataTask(with: request) { data, response, error in

            guard error == nil else {
                print("Error: error calling GET")
                print(error!)
                onError(true)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                onError(true)
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                if((response as? HTTPURLResponse)?.statusCode == 401){
                    onError(true)
                }
                else if((response as? HTTPURLResponse)?.statusCode == 404){
                    onError(false)
                }

                print("Error: HTTP request failed")
                onError(true)
                return
            }
            do {
                guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("Error: Cannot convert data to JSON object")
                    onError(true)
                    return
                }
                completion(jsonObject)

            } catch {
                onError(true)
                return
            }

        }.resume()
    }
    
    func refreshToken( clientId: String?, rToken: String?,  completion: @escaping ([String : Any])->()) {
        let authJson: [String: Any] = [
            "REFRESH_TOKEN": rToken!
        ]
        let json: [String: Any] = ["AuthFlow": "REFRESH_TOKEN_AUTH",
                                   "ClientId": clientId!,
                                   "AuthParameters":authJson]

        let jsonBody = try? JSONSerialization.data(withJSONObject: json)
        guard let url = URL(string: "https://cognito-idp.ca-central-1.amazonaws.com/") else {
            print("Error: cannot create URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("AWSCognitoIdentityProviderService.InitiateAuth", forHTTPHeaderField: "X-Amz-Target")
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonBody
        URLSession.shared.dataTask(with: request) { data, response, error in

            guard error == nil else {
                print("Error: error calling PUT")
                print(error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                print("Error: HTTP request failed")
                return
            }
            do {
                guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("Error: Cannot convert data to JSON object")
                    return
                }
                guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                    print("Error: Cannot convert JSON object to Pretty JSON data")
                    return
                }
                guard let prettyPrintedJson = String(data: prettyJsonData, encoding: .utf8) else {
                    print("Error: Could print JSON in String")
                    return
                }

                completion(jsonObject)
                print("prettyPrintedJson \(prettyPrintedJson)")
            } catch {
                print("Error: Trying to convert JSON data to string")
                return
            }
        }.resume()
    }
    
    
}
