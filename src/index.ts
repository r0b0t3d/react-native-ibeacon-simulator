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
      advertiseMode: Types.AndroidAdvertiseMode.ADVERTISE_MODE_LOW_POWER,
      advertiseTxPowerLevel: Types.AndroidAdvertiseTx.ADVERTISE_TX_POWER_MEDIUM
    }
  }
  return NativeBeaconBroadcast.startSharedAdvertisingBeaconWithString(args)
}

function stopAdvertisingBeacon(): boolean {
  return NativeBeaconBroadcast.stopSharedAdvertisingBeacon()
}

function isStarted(): boolean {
  if (Platform.OS === 'ios') return true
  return NativeBeaconBroadcast.isStarted()
}

async function checkTransmissionSupported(): Promise<boolean> {
  if (Platform.OS === 'ios') return true
  const status = await NativeBeaconBroadcast.checkTransmissionSupported() === Types.AndroidSupportedStatuses.SUPPORTED
  return status
}

export {
  startAdvertisingBeaconWithString,
  stopAdvertisingBeacon,
  isStarted,
  checkTransmissionSupported,
  Types,
}