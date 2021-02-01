import {
  NativeModules,
  Platform,
} from 'react-native'
import * as Types from './types'

const NativeBeaconBroadcast = NativeModules.BeaconBroadcast

async function startAdvertisingBeaconWithString(args: Types.StartBeaconArgs): Promise<boolean> {
  if (Platform.OS === 'android') {
    args = {
      ...args,
      txPower: -56, 
      advertiseMode: Types.AndroidAdvertiseMode.ADVERTISE_MODE_BALANCED,
      advertiseTxPowerLevel: Types.AndroidAdvertiseTx.ADVERTISE_TX_POWER_MEDIUM
    }
  }
  return NativeBeaconBroadcast.startSharedAdvertisingBeaconWithString(args)
}

function stopAdvertisingBeacon(): boolean {
  return NativeBeaconBroadcast.stopSharedAdvertisingBeacon()
}

async function isStarted(): Promise<boolean> {
  return NativeBeaconBroadcast.isStarted()
}

async function checkTransmissionSupported(): Promise<boolean> {
  return Platform.select({
    android: async () => {
      const checkStatus = await NativeBeaconBroadcast.checkTransmissionSupported()
      return (checkStatus !== Types.AndroidSupportedStatuses.NOT_SUPPORTED_BLE && 
        checkStatus !== Types.AndroidSupportedStatuses.NOT_SUPPORTED_MIN_SDK)
    },
    ios: async () => {
      return Boolean(await NativeBeaconBroadcast.checkTransmissionSupported())
    }
  })()
}

export {
  startAdvertisingBeaconWithString,
  stopAdvertisingBeacon,
  isStarted,
  checkTransmissionSupported,
  Types,
}
