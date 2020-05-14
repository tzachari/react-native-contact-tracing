package org.tcncoalition.contacttracing;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.bluetooth.BluetoothAdapter;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.Manifest.permission;
import android.os.Build;
import android.util.Base64;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import com.facebook.common.logging.FLog;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Promise;
import com.facebook.react.common.ReactConstants;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.ArrayList;
import java.util.List;

import org.tcncoalition.tcnclient.TcnKeys;
import org.tcncoalition.tcnclient.TcnManager;

public class ContactTracingModule extends ReactContextBaseJavaModule {

    private SharedPreferences sharedPreferences = null;
    private TcnManager tcnManager = null;

    public ContactTracingModule( ReactApplicationContext reactContext ) {
        super( reactContext );
        this.tcnManager = new DefaultTcnManager( reactContext );
        this.sharedPreferences = reactContext.getSharedPreferences( "ContactTracing", Context.MODE_PRIVATE );
    }

    @Override
    public String getName() {
        return "ContactTracing";
    }


    /* CONTACT TRACING API */

    @ReactMethod /* Starts BLE broadcasts and scanning based on the defined protocol */
    public void start( Promise promise ) {
        try { // Resolve : Void
            if ( BluetoothAdapter.getDefaultAdapter() != null ) {
                if ( BluetoothAdapter.getDefaultAdapter() != null && !BluetoothAdapter.getDefaultAdapter().isEnabled() ) {
                    getCurrentActivity().startActivityForResult( new Intent( BluetoothAdapter.ACTION_REQUEST_ENABLE ), 1 );
                }
            } else throw new Exception( "No Bluetooth Adapter Available" );
            if ( getReactApplicationContext().checkSelfPermission( permission.ACCESS_COARSE_LOCATION ) != PackageManager.PERMISSION_GRANTED ) {
                getCurrentActivity().requestPermissions( new String[] { permission.ACCESS_COARSE_LOCATION, permission.ACCESS_FINE_LOCATION }, 2 );
            }
            tcnManager.startService();
            sharedPreferences.edit().putBoolean("enabled", true).apply();
            promise.resolve( null );
        } catch ( Exception e ) {
            promise.reject( "StartError", e );
        }
    }

    @ReactMethod /* Disables advertising and scanning */
    public void stop( Promise promise ) {
        try { // Resolve : Void
            tcnManager.stopService();
            sharedPreferences.edit().putBoolean("enabled", false).apply();
            promise.resolve( null );
        } catch ( Exception e ) {
            promise.reject( "StopError", e );
        }
    }

    @ReactMethod /* Indicates whether exposure notifications are currently running for the requesting app */
    public void isEnabled( Promise promise ) {
        try { // Resolve : Boolean
            promise.resolve( sharedPreferences.getBoolean("enabled", false) );
        } catch ( Exception e ) {
            promise.reject( "IsEnabledError", e );
        }
    }

    @ReactMethod /* Gets TemporaryExposureKey history to be stored on the server ( after user is diagnosed ) */
    public void getTemporaryExposureKeyHistory( Promise promise ) { // Resolve : Array - Exposure Keys
        promise.reject( "GetTemporaryExposureKeyHistoryError", "Not yet implemented" );
    }

    @ReactMethod /* Provides a list of diagnosis key files for exposure checking ( from server ) */
    public void provideDiagnosisKeys( ReadableArray keyFiles, ReadableMap configuration, String token, Promise promise ) { // Resolve : Void
        promise.reject( "ProvideDiagnosisKeysError", "Not yet implemented" );
    }

    @ReactMethod /* Gets a summary of the latest exposure calculation */
    public void getExposureSummary( String token, Promise promise ) { // Resolve : Object - Exposure Summary
        promise.reject( "GetExposureSummaryError", "Not yet implemented" );
    }

    @ReactMethod /* Gets detailed information about exposures that have occurred */
    public void getExposureInformation( String token, Promise promise ) { // Resolve : Object - Exposure Information
        promise.reject( "GetExposureInformationError", "Not yet implemented" );
    }


    /* HELPER CLASSES */

    private class DefaultTcnManager extends TcnManager {

        private List<byte[]> advertisedTcns = new ArrayList<>();
        private List<byte[]> discoveredTcns = new ArrayList<>();
        private Context context;
        private TcnKeys tcnKeys;

        public DefaultTcnManager(Context context) {
            super( context );
            this.context = context;
            this.tcnKeys = new TcnKeys( context );
        }

        @Override
        public NotificationCompat.Builder foregroundNotification() {
            if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ) {
                NotificationChannel serviceChannel = new NotificationChannel( "ContactTracing", "Foreground Service Channel", NotificationManager.IMPORTANCE_DEFAULT );
                ContextCompat.getSystemService( context, NotificationManager.class ).createNotificationChannel( serviceChannel );
            }
            return new NotificationCompat.Builder( context, "ContactTracing" ).setPriority( NotificationManagerCompat.IMPORTANCE_HIGH )
                    .setContentTitle( "Contact tracing is running" ).setSmallIcon( context.getApplicationInfo().icon ).setCategory( Notification.CATEGORY_SERVICE )
                    .setContentIntent( PendingIntent.getActivity( context, 0, new Intent(context, getCurrentActivity().getClass() ), PendingIntent.FLAG_UPDATE_CURRENT ) );
        }

        @Override
        public void bluetoothStateChanged(boolean bluetoothOn) {
            String title = bluetoothOn ? "Contact tracing is running" : "Turn on Bluetooth to enable contact tracing";
            ContextCompat.getSystemService( context, NotificationManager.class ).notify( NOTIFICATION_ID, foregroundNotification().setContentTitle( title ).build() );
        }

        @Override
        public byte[] generateTcn() {
            byte[] tcn = tcnKeys.generateTcn();
            advertisedTcns.add( tcn );
            if ( advertisedTcns.size() > 65535 ) {
                advertisedTcns.remove( 0 );
            }
            ( ( ReactContext ) context ).getJSModule( DeviceEventManagerModule.RCTDeviceEventEmitter.class ).emit( "Advertise", Base64.encodeToString( tcn, Base64.DEFAULT) );
            return tcn;
        }

        @Override
        public void onTcnFound( byte[] tcn, Double estimatedDistance ) {
            if ( advertisedTcns.contains( tcn ) || discoveredTcns.contains( tcn ) ) return;
            discoveredTcns.add( tcn );
            if ( discoveredTcns.size() > 1024 ) {
                discoveredTcns.remove( 0 );
            }
            ( ( ReactContext ) context ).getJSModule( DeviceEventManagerModule.RCTDeviceEventEmitter.class ).emit( "Discovery", Base64.encodeToString( tcn, Base64.DEFAULT) );
        }

    }

}