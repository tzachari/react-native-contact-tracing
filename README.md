# react-native-contact-tracing

React Native Module for Bluetooth contact tracing


## Getting started

    npm install tzachari/react-native-contact-tracing --save

### iOS Setup

#### `Podfile`

Modify the project's `ios/Podfile` to target platform iOS ≥13:

```ruby
platform :ios, '13.0'
```

Then add the following pod:

```ruby
pod "TCNClient", :git => 'git@github.com:TCNCoalition/tcn-client-ios.git', :commit => '4d1aedb'
```

Run install to update:

    pod install

#### `Info.plist`

Include Bluetooth permission descriptions & set background modes in `ios/<project>/Info.plist`:

```xml
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Bluetooth is used for contact tracing</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is used for contact tracing</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
</array>
```

### Android Setup

#### `build.gradle`

Modify the project's `android/build.gradle` to target min SDK ≥ 23 & compile SDK ≥ 29:

```gradle
ext {
    buildToolsVersion = "29.0.0"
    minSdkVersion = 23
    compileSdkVersion = 29
    targetSdkVersion = 29
}
```


## Usage

```javascript
import { NativeEventEmitter, NativeModules } from 'react-native';}
import ContactTracing from 'react-native-contact-tracing';

/* Starts BLE broadcasts and scanning */
ContactTracing.start()
  .then( () => { /* Success : () */ } )
  .catch( ( error ) => { /* Failure : ( Error ) */ } );

/* Disables advertising and scanning */
ContactTracing.stop()
  .then( () => { /* Success : () */ } )
  .catch( ( error ) => { /* Failure : ( Error ) */ } );

/* Indicates whether contact tracing is currently running on the app */
ContactTracing.isEnabled()
  .then( ( enabled ) => { /* Success : ( Boolean ) */ } )
  .catch( ( error ) => { /* Failure : ( Error ) */ } );

/* Listen to Advertise & Discovery events - May be deprecated in future versions */
const eventEmitter = new NativeEventEmitter( NativeModules.ContactTracing );
eventEmitter.addListener( 'Advertise', ( advertisedTCN ) => { /* Event : ( String ) */ } );
eventEmitter.addListener( 'Discovery', ( discoveredTCN ) => { /* Event : ( String ) */ } );
eventEmitter.removeAllListeners(); /* Remove when no longer needed */
```


## Related Projects

- [cordova-plugin-contact-tracing](https://github.com/tzachari/cordova-plugin-contacttracing) : Cordova Plugin for Bluetooth contact tracing on Android & iOS
- [contact-tracing](https://github.com/lab11/contact-tracing) : Node app for Bluetooth contact tracing on stationary devices
- [coviddb-app](https://github.com/covid19database/coviddb-app) : Smartphone app for contact tracing