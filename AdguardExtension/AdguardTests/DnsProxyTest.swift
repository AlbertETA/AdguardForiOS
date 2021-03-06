/**
            This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
            Copyright © Adguard Software Limited. All rights reserved.

            Adguard for iOS is free software: you can redistribute it and/or modify
            it under the terms of the GNU General Public License as published by
            the Free Software Foundation, either version 3 of the License, or
            (at your option) any later version.

            Adguard for iOS is distributed in the hope that it will be useful,
            but WITHOUT ANY WARRANTY; without even the implied warranty of
            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
            GNU General Public License for more details.

            You should have received a copy of the GNU General Public License
            along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
*/

import XCTest

class LogWriterMock: NSObject, DnsLogRecordsWriterProtocol {
    
    var whitelistFilterId: NSNumber?
    
    var userFilterId: NSNumber?
    
    var otherFilterIds: [NSNumber]?
    
    var server: String = ""
    
    func handleEvent(_ event: AGDnsRequestProcessedEvent) {
        
    }
}

class DnsProxyTest: XCTestCase {
    
    var proxyService = DnsProxyService(logWriter: LogWriterMock());
    let request = Data(base64Encoded: "RQAAQkGPAAD/ETb1rBDRAsYSAAHOlAA1AC47HU+xAQAAAQAAAAAAAAdjbGllbnRzAWwGZ29vZ2xlA2NvbQAAAQAB")

    override func setUp() {
        XCTAssert(proxyService.start(upstreams: ["1.1.1.1"], bootstrapDns: ["8.8.8.8"], fallbacks: ["8.8.8.8"], serverName: "cloudflare", filtersJson: "", userFilterId: 1, whitelistFilterId: 2, ipv6Available: true))
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testResolve() {
        
        let expectation = XCTestExpectation(description: "expectation")
        
        proxyService.resolve(dnsRequest: request!) { (response) in
            XCTAssertNotNil(response)
            XCTAssert(response!.count > 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testRestart() {
        
        let expectation = XCTestExpectation(description: "expectation")
        proxyService.resolve(dnsRequest: request!) { (response) in
            XCTAssertNotNil(response)
            XCTAssert(response!.count > 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
        
        proxyService.stop() {}
        XCTAssert(proxyService.start(upstreams: ["1.1.1.1"], bootstrapDns: ["8.8.8.8"], fallbacks: ["8.8.8.8"], serverName: "cloudflare", filtersJson: "", userFilterId: 1, whitelistFilterId: 2, ipv6Available: true))
        
        let expectation2 = XCTestExpectation(description: "expectation2")
        
        proxyService.resolve(dnsRequest: request!) { (response) in
            XCTAssertNotNil(response)
            XCTAssert(response!.count > 0)
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 15)
    }
    
    func testStopAndResolve() {
        
        let expectation = XCTestExpectation(description: "expectation")
        
        proxyService.stop() { [weak self] in
            self!.proxyService.resolve(dnsRequest: self!.request!) { (response) in
                XCTAssertNil(response)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15)
        
    }
    
    func testResolveAfterStop() {
        
        let expectation = XCTestExpectation(description: "expectation")
        
        proxyService.stop() { expectation.fulfill() }
        
        wait(for: [expectation], timeout: 15)
        
        let expectation2 = XCTestExpectation(description: "expectation2")
        
        proxyService.resolve(dnsRequest: request!) { (response) in
            XCTAssertNil(response)
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 15)
    }
}
