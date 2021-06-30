package com.ibeacon.simulator;

import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseSettings;
import android.os.Build;
import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

import org.altbeacon.beacon.Beacon;
import org.altbeacon.beacon.BeaconParser;
import org.altbeacon.beacon.BeaconTransmitter;

import java.util.HashMap;
import java.util.Map;


public class BeaconBroadcast extends ReactContextBaseJavaModule {
    private static final String TAG = "BeaconBroadcast";

    private static final String SUPPORTED = "SUPPORTED";
    private static final String NOT_SUPPORTED_MIN_SDK = "NOT_SUPPORTED_MIN_SDK";
    private static final String NOT_SUPPORTED_BLE = "NOT_SUPPORTED_BLE";
    private static final String NOT_SUPPORTED_CANNOT_GET_ADVERTISER_MULTIPLE_ADVERTISEMENTS = "NOT_SUPPORTED_CANNOT_GET_ADVERTISER_MULTIPLE_ADVERTISEMENTS";
    private static final String NOT_SUPPORTED_CANNOT_GET_ADVERTISER = "NOT_SUPPORTED_CANNOT_GET_ADVERTISER";

    private static final String ADVERTISE_MODE_LOW_POWER = "ADVERTISE_MODE_LOW_POWER";
    private static final String ADVERTISE_MODE_BALANCED = "ADVERTISE_MODE_BALANCED";
    private static final String ADVERTISE_MODE_LOW_LATENCY = "ADVERTISE_MODE_LOW_LATENCY";

    private static final String ADVERTISE_TX_POWER_ULTRA_LOW = "ADVERTISE_TX_POWER_ULTRA_LOW";
    private static final String ADVERTISE_TX_POWER_LOW = "ADVERTISE_TX_POWER_LOW";
    private static final String ADVERTISE_TX_POWER_MEDIUM = "ADVERTISE_TX_POWER_MEDIUM";
    private static final String ADVERTISE_TX_POWER_HIGH = "ADVERTISE_TX_POWER_HIGH";

    private static android.content.Context applicationContext;
    private static BeaconTransmitter beaconTransmitter = null;
    private final ReactApplicationContext context;

    public BeaconBroadcast(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context = reactContext;
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put(SUPPORTED, BeaconTransmitter.SUPPORTED);
        constants.put(NOT_SUPPORTED_MIN_SDK, BeaconTransmitter.NOT_SUPPORTED_MIN_SDK);
        constants.put(NOT_SUPPORTED_BLE, BeaconTransmitter.NOT_SUPPORTED_BLE);
        constants.put(NOT_SUPPORTED_CANNOT_GET_ADVERTISER_MULTIPLE_ADVERTISEMENTS, BeaconTransmitter.NOT_SUPPORTED_CANNOT_GET_ADVERTISER_MULTIPLE_ADVERTISEMENTS);
        constants.put(NOT_SUPPORTED_CANNOT_GET_ADVERTISER, BeaconTransmitter.NOT_SUPPORTED_CANNOT_GET_ADVERTISER);

        constants.put(ADVERTISE_MODE_LOW_POWER, AdvertiseSettings.ADVERTISE_MODE_LOW_POWER);
        constants.put(ADVERTISE_MODE_BALANCED, AdvertiseSettings.ADVERTISE_MODE_BALANCED);
        constants.put(ADVERTISE_MODE_LOW_LATENCY, AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY);

        constants.put(ADVERTISE_TX_POWER_ULTRA_LOW, AdvertiseSettings.ADVERTISE_TX_POWER_ULTRA_LOW);
        constants.put(ADVERTISE_TX_POWER_LOW, AdvertiseSettings.ADVERTISE_TX_POWER_LOW);
        constants.put(ADVERTISE_TX_POWER_MEDIUM, AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM);
        constants.put(ADVERTISE_TX_POWER_HIGH, AdvertiseSettings.ADVERTISE_TX_POWER_HIGH);
        return constants;
    }

    @Override
    public String getName() {
        return TAG;
    }

    @ReactMethod
    public void checkTransmissionSupported(Promise promise) {
        promise.resolve(BeaconTransmitter.checkTransmissionSupported(context));
    }

    @ReactMethod
    public void isStarted(Promise promise) {
        if (beaconTransmitter != null) {
            promise.resolve(beaconTransmitter.isStarted());
        }
        promise.resolve(false);
    }

    @ReactMethod
    public void startSharedAdvertisingBeaconWithString(ReadableMap args, final Promise promise) {
        String uuid = args.getString("uuid");
        int major = args.getInt("major");
        int minor = args.getInt("minor");
        String identifier = args.getString("identifier");
        int txPower = args.getInt("txPower");
        int advertiseMode = args.getInt("advertiseMode");
        int advertiseTxPowerLevel = args.getInt("advertiseTxPowerLevel");

        int manufacturer = 0x4C;
        try {
            Beacon beacon = new Beacon.Builder()
                    .setId1(uuid)
                    .setId2(String.valueOf(major))
                    .setId3(String.valueOf(minor))
                    .setManufacturer(manufacturer)
                    .setBluetoothName(identifier)
                    .setTxPower(txPower)
                    .build();
            BeaconParser beaconParser = new BeaconParser()
                    .setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");

            beaconTransmitter = new BeaconTransmitter(context, beaconParser);
            beaconTransmitter.setAdvertiseMode(advertiseMode);
            beaconTransmitter.setAdvertiseTxPowerLevel(advertiseTxPowerLevel);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                beaconTransmitter.startAdvertising(beacon, new AdvertiseCallback() {
                    @Override
                    public void onStartFailure(int errorCode) {
                        String errorMessage = "Error on start advertising " + errorCode;
                        Log.e(TAG, errorMessage);
                        promise.reject(String.valueOf(errorCode), errorMessage);
                    }

                    @Override
                    public void onStartSuccess(AdvertiseSettings settingsInEffect) {
                        String successMessage = "Success on start advertising " + settingsInEffect.toString();
                        Log.d(TAG, successMessage);
                        promise.resolve(true);
                    }
                });
            }
        } catch (Exception ex) {
            promise.reject(ex);
        }
    }

    @ReactMethod
    public void stopSharedAdvertisingBeacon(Promise promise) {
        if (beaconTransmitter != null) {
            try {
                beaconTransmitter.stopAdvertising();
                promise.resolve(true);
            } catch (Exception ex) {
                Log.e(TAG, "Error on stop advertising ", ex);
                promise.resolve(false);
            }
        }
        promise.resolve(true);
    }
}
