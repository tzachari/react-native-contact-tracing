import TCNClient
import CryptoKit


@objc( ContactTracing )
class ContactTracing: RCTEventEmitter {

    
    /* CONTACT TRACING API */
    
    @objc( start: reject: ) /* Starts BLE broadcasts and scanning based on the defined protocol */
    func start( resolve: RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock ) { // Resolve: Void
        self.configureContactTracingService( reject: reject )
        self.contactTracingBluetoothService?.start()
        UserDefaults.standard.set( true, forKey: "enabled" )
        resolve( nil )
    }

    @objc( stop: reject: ) /* Disables advertising and scanning */
    func stop( resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock ) { // Resolve: Void
        self.contactTracingBluetoothService?.stop()
        UserDefaults.standard.set( false, forKey: "enabled" )
        resolve( nil )
    }

    @objc( isEnabled: reject: ) /* Indicates whether exposure notifications are currently running for the requesting app */
    func isEnabled( resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock ) { // Resolve: Boolean
        resolve( UserDefaults.standard.bool( forKey: "enabled" ) )
    }
    
    @objc( getTemporaryExposureKeyHistory: reject: ) /* Gets TemporaryExposureKey history to be stored on the server ( after user is diagnosed ) */
    func getTemporaryExposureKeyHistory( resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock ) { // Resolve: Array - Exposure Keys
        reject( "GetTemporaryExposureKeyHistoryError", "Not yet implemented", nil )
    }

    @objc( provideDiagnosisKeys: configuration: token: resolve: reject: ) /* Provides a list of diagnosis key files for exposure checking ( from server ) */
    func provideDiagnosisKeys( keyFiles: NSArray, configuration: NSDictionary, token: NSString, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock ) { // Resolve: Void
        reject( "ProvideDiagnosisKeysError", "Not yet implemented", nil )
    }

    @objc( getExposureSummary: resolve: reject: ) /* Gets a summary of the latest exposure calculation */
    func getExposureSummary( token: NSString, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock ) { // Resolve: Object - Exposure Summary
        reject( "GetExposureSummaryError", "Not yet implemented", nil )
    }

    @objc( getExposureInformation: resolve: reject: ) /* Gets detailed information about exposures that have occurred */
    func getExposureInformation( token: NSString, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock ) { // Resolve: Object - Exposure Information
        reject( "GetExposureInformationError", "Not yet implemented", nil )
    }

    
    /* HELPER OBJECTS & FUNCTIONS */
    
    var hasListeners = false
    var advertisedTcns = [Data]()
    var discoveredTcns = [Data]()
    var contactTracingBluetoothService: TCNBluetoothService?
    var reportAuthorizationKey: ReportAuthorizationKey {
        do {
            guard let storedKey: Curve25519.Signing.PrivateKey = try GenericPasswordStore().readKey( account: "tcn-rak" ) else { throw NSError() }
            return ReportAuthorizationKey( reportAuthorizationPrivateKey: storedKey )
        } catch {
            let newKey = Curve25519.Signing.PrivateKey()
            do {
                try GenericPasswordStore().storeKey( newKey, account: "tcn-rak" )
            } catch {
                NSLog( "Storing report authorization key in Keychain failed: %@", error as CVarArg )
            }
            return ReportAuthorizationKey( reportAuthorizationPrivateKey: newKey )
        }
    }
    
    @objc override func supportedEvents() -> [String]! { return [ "Advertise", "Discovery" ] }
    
    @objc override func startObserving() { hasListeners = true }
    
    @objc override func stopObserving() { hasListeners = false }
    
    @objc override static func requiresMainQueueSetup() -> Bool { return false }
    
    func configureContactTracingService( reject: @escaping RCTPromiseRejectBlock ) {
        guard contactTracingBluetoothService == nil else { return }
        contactTracingBluetoothService = TCNBluetoothService(
            
            tcnGenerator: { () -> Data in
                var temporaryContactKey: TemporaryContactKey
                do {
                    guard let data = UserDefaults.standard.object( forKey: "tck" ) as? Data else { throw NSError() }
                    try temporaryContactKey = TemporaryContactKey( serializedData: data )
                } catch {
                    temporaryContactKey = self.reportAuthorizationKey.initialTemporaryContactKey
                }
                let temporaryContactNumber = temporaryContactKey.temporaryContactNumber
                if let newTck = temporaryContactKey.ratchet() { // Ratch key for next TCN
                    UserDefaults.standard.set( newTck.serializedData(), forKey: "tck" )
                }
                self.advertisedTcns.append( temporaryContactNumber.bytes )
                if self.advertisedTcns.count > 1024 {
                    self.advertisedTcns.removeFirst()
                }
                self.sendEvent( withName: "Advertise", body: temporaryContactNumber.bytes.base64EncodedString() )
                return temporaryContactNumber.bytes
            },
            
            tcnFinder: { ( data, estimatedDistance ) in
                guard !self.advertisedTcns.contains( data ), !self.discoveredTcns.contains( data ) else { return }
                self.discoveredTcns.append( data )
                if self.discoveredTcns.count > 1024 {
                    self.discoveredTcns.removeFirst()
                }
                self.sendEvent( withName: "Discovery", body: data.base64EncodedString() )
            },
            
            errorHandler: { ( error ) in
                reject( "ServiceError", "ContactTracing service failed. Check BLE & Permissions settings.", error )
            }
        )
    }
        
}


/* HELPER STRUCTS, PROTOCOLS, & EXTENSIONS */

struct GenericPasswordStore {
    
    /// Stores a CryptoKit key in the keychain as a generic password.
    public func storeKey<T: GenericPasswordConvertible>( _ key: T, account: String ) throws {
        let status = SecItemAdd( [ kSecClass: kSecClassGenericPassword, kSecAttrAccount: account, kSecValueData: key.rawRepresentation, kSecUseDataProtectionKeychain: true, kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly ] as CFDictionary, nil )
        guard status == errSecSuccess else { throw KeyStoreError( "Unable to store item: \( status.message )" ) }
    }
    
    /// Reads a CryptoKit key from the keychain as a generic password.
    public func readKey<T: GenericPasswordConvertible>( account: String ) throws -> T? {
        var item: CFTypeRef?
        switch SecItemCopyMatching( [ kSecClass: kSecClassGenericPassword, kSecAttrAccount: account, kSecUseDataProtectionKeychain: true, kSecReturnData: true ] as CFDictionary, &item ) {
            case errSecSuccess:
                guard let data = item as? Data else { return nil }
                return try T( rawRepresentation: data )  // Convert back to a key.
            case errSecItemNotFound:
                return nil
            case let status:
                throw KeyStoreError( "Keychain read failed: \( status.message )" )
        }
    }
    
}

/// The interface needed to create a key for SecKey conversion.
protocol GenericPasswordConvertible: CustomStringConvertible {
    init<D>( rawRepresentation data: D ) throws where D: ContiguousBytes
    var rawRepresentation: Data { get }
}

/// Extend with a string version of the key for visual inspection. ( IMPORTANT: Never log the actual key data )
extension GenericPasswordConvertible {
    public var description: String { return self.rawRepresentation.withUnsafeBytes { bytes in return "Key representation contains \( bytes.count ) bytes." } }
}

/// Declare that the Curve25519 keys are generic passord convertible.
extension Curve25519.Signing.PrivateKey: GenericPasswordConvertible {}

/// An error we can throw when something goes wrong.
struct KeyStoreError: Error, CustomStringConvertible {
    var message: String
    init( _ message: String ) { self.message = message }
    public var description: String { return message }
}

/// Extend status with a human readable message.
extension OSStatus {
    var message: String { return ( SecCopyErrorMessageString( self, nil ) as String? ) ?? String( self ) }
}
