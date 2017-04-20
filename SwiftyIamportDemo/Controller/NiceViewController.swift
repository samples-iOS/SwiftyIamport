//
//  NiceViewController.swift
//  SwiftIamportDemo
//
//  Created by JosephNK on 2017. 4. 20..
//  Copyright © 2017년 JosephNK. All rights reserved.
//

import UIKit
import SwiftyIamport

class NiceViewController: UIViewController {
    lazy var webView: UIWebView = {
        var view = UIWebView()
        view.backgroundColor = UIColor.clear
        view.delegate = self
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(webView)
        self.webView.frame = self.view.bounds
        
        // 결제 정보 데이타
        let parameters: IAMPortParameters = [
            "merchant_uid": String(format: "merchant_%@", String(Int(NSDate().timeIntervalSince1970 * 1000))),
            "name": "결제테스트",
            "amount": "1004",
            "buyer_email": "iamport@siot.do",
            "buyer_name": "구매자",
            "buyer_tel": "010-1234-5678",
            "buyer_addr": "서울특별시 강남구 삼성동",
            "buyer_postcode": "123-456",
            "custom_data": ["A1": 123, "B1": "Hello"]
            //"custom_data": "24"
        ]
        
        // 결제 환경 설정
        IAMPortPay.sharedInstance.configure(scheme: "iamporttest",
                                            storeIdentifier: "imp84043725",
                                            pgType: .nice,
                                            pgIdName: nil,
                                            parameters: parameters,
                                            webView: self.webView,
                                            m_redirect_url: nil)
        
        // ISP 취소시 이벤트 (NicePay만 가능)
        IAMPortPay.sharedInstance.setCancelListenerForNicePay { [weak self] _ in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: nil, message: "ISP 결제 취소", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
        
        // 결제 웹페이지(Local) 파일 호출
        if let url = IAMPortPay.sharedInstance.urlFromLocalHtmlFile() {
            let request = URLRequest(url: url)
            self.webView.loadRequest(request)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension NiceViewController: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        // 해당 함수는 redirecURL의 결과를 직접 처리하고 할 때 사용하는 함수 (IAMPortPay.sharedInstance.configure m_redirect_url 값을 설정해야함.)
        IAMPortPay.sharedInstance.webViewRedirectUrl(shouldStartLoadWith: request, parser: { (data, response, error) -> Any? in
            // Background Thread 처리
            var resultData: [String: Any]?
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                switch statusCode {
                case 200:
                    resultData = [
                        "isSuccess": "OK"
                    ]
                    break
                default:
                    break
                }
            }
            return resultData
        }) { (pasingData) in
            // Main Thread 처리
        }
        
        //
        return IAMPortPay.sharedInstance.webView(webView, shouldStartLoadWith: request, navigationType: navigationType)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // 결제 환경으로 설정에 의한 웹페이지(Local) 호출 결과
        IAMPortPay.sharedInstance.requestIAMPortPayWebViewDidFinishLoad(webView) { (error) in
            if error != nil {
                switch error! {
                case .custom(let reason):
                    print("error: \(reason)")
                    break
                }
            }else {
                print("OK")
            }
        }
    }
}