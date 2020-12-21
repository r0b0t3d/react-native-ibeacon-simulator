import {
  NativeModules,
  Platform,
} from 'react-native'
import * as Types from './types'

const NativeBeaconBroadcast = NativeModules.BeaconBroadcast

export async function startAdvertisingBeaconWithString(args: Types.StartBeaconArgs): Promise<boolean> {
  if (Platform.OS === 'android') {
    args = {
      ...args,
      txPower: -56, 
      advertiseMode: Types.AndroidAdvertiseMode.ADVERTISE_MODE_LOW_POWER,
      advertiseTxPowerLevel: Types.AndroidAdvertiseTx.ADVERTISE_TX_POWER_MEDIUM
    }
  }
  return NativeBeaconBroadcast.startSharedAdvertisingBeaconWithString(args)
}

export function stopAdvertisingBeacon(): boolean {
  return NativeBeaconBroadcast.stopSharedAdvertisingBeacon()
}

export function isStarted(): boolean {
  if (Platform === 'ios') return true
  return NativeBeaconBroadcast.isStarted()
}

export function checkTransmissionSupported(): boolean {
  if (Platform === 'ios') return true
  const status = NativeBeaconBroadcast.checkTransmissionSupported() === Types.AndroidSupportedStatuses.SUPPORTED
  return status
}

export * from './types'

export default {
  startAdvertisingBeaconWithString,
  stopAdvertisingBeacon,
  isStarted,
  checkTransmissionSupported,
};
