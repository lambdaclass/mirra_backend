use rustler::NifStruct;
use std::time::{SystemTime, UNIX_EPOCH};
use std::{thread, time};

#[derive(Debug, Clone, Copy, NifStruct)]
#[module = "LambdaGameEngine.MyrraEngine.Player"]
pub struct MillisTime {
    pub high: u64,
    pub low: u64,
}

pub fn millis_to_u128(time: MillisTime) -> u128 {
    return ((time.high as u128) << 64) + time.low as u128;
}

pub fn u128_to_millis(time: u128) -> MillisTime {
    let low = time as u64;
    let high = (time >> 64) as u64;

    MillisTime { high, low }
}

pub fn add_millis(t1: MillisTime, t2: MillisTime) -> MillisTime {
    let sum = millis_to_u128(t1) + millis_to_u128(t2);
    return u128_to_millis(sum);
}

pub fn sub_millis(t1: MillisTime, t2: MillisTime) -> MillisTime {
    let sub = millis_to_u128(t1).saturating_sub(millis_to_u128(t2));
    return u128_to_millis(sub);
}

/// Returns the current system time in seconds. Note that system time is
/// unreliable as it's not guaranteed to be monotonic.
pub fn time_now() -> MillisTime {
    let start = SystemTime::now();
    let since_the_epoch = start
        .duration_since(UNIX_EPOCH)
        .expect("Time went backwards");

    u128_to_millis(since_the_epoch.as_millis())
}

pub fn _sleep(milliseconds: MillisTime) {
    let duration = time::Duration::from_millis(millis_to_u128(milliseconds) as u64);
    thread::sleep(duration);
}
