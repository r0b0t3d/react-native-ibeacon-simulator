export interface StartBeaconArgs {
    uuid: string
    major: number
    minor: number
    identifier: string
    txPower?: number
    advertiseMode?: number
    advertiseTxPowerLevel?: number
}

export enum AndroidSupportedStatuses {
    'SUPPORTED',
    'NOT_SUPPORTED_MIN_SDK',
    'NOT_SUPPORTED_BLE',
    'DEPRECATED_NOT_SUPPORTED_MULTIPLE_ADVERTISEMENTS',
    'NOT_SUPPORTED_CANNOT_GET_ADVERTISER',
    'NOT_SUPPORTED_CANNOT_GET_ADVERTISER_MULTIPLE_ADVERTISEMENTS'
}

export enum AndroidAdvertiseMode {
    'ADVERTISE_MODE_LOW_POWER',
    'ADVERTISE_MODE_BALANCED',
    'ADVERTISE_MODE_LOW_LATENCY'
}

export enum AndroidAdvertiseTx {
    'ADVERTISE_TX_POWER_ULTRA_LOW',
    'ADVERTISE_TX_POWER_LOW',
    'ADVERTISE_TX_POWER_MEDIUM',
    'ADVERTISE_TX_POWER_HIGH',
}