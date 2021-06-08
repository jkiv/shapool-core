## About `shapool-core`

`shapool-core` is an FPGA core that computes double-SHA256 hashes for the purposes of cryptocurrency mining, e.g. Bitcoin.

`shapool-core` is intended to be used in a cluster-like environment but should work as a stand-alone core, i.e. a cluster of one.

Each `shapool-core` device in a cluster is given the same job data by the host device. Each device works on the job until it either finishes or is interrupted by the host device.

The work required for each job can be divided among the cluster by providing each `shapool-core` device with unique parameters such that no two devices will perform the same work.

## Signal Descriptions

```
             shapool-core
           +---------------+
    clk ---|>              |--> ready_n
           |               |
reset_n -->|               |--> status_led_n
           |               |
   sck0 -->|               |
   sdi0 -->|     SPI 0     |
  cs0_n -->|               |
           |               |
   sck1 -->|               |
   sdi1 -->|     SPI 1     |--> sdo1
  cs1_n -->|               |
           +---------------+
```

* `clk` - external core clock input
* `reset_n` - external asynchronous reset input
* `sck0` - serial data clock input (SPI interface 0)
* `sdi0` - serial data input (SPI interface 0)
* `cs0_n` - active-low chip-select input (SPI interface 0)
* `sck1` - serial data clock input (SPI interface 1)
* `sdi1` - serial data input (SPI interface 1)
* `sdo1` - serial data output (SPI interface 1)
* `cs1_n` - active-low chip-select input (SPI interface 1)
* `ready_n` - active-low, open-drain "data ready" output
* `status_led_n` - active-low indicator LED output

SPI interface 0 is a one-to-many interface which allows the host device load the same job data to all `shapool-core` devices on the SPI bus. Note that this interface does not have a data output.

SPI interface 1 is a daisy-chained interface which allows the host device to load each `shapool-core` with device-specific data, as well as read device-specific results back.

Both SPI interfaces are SPI mode 0, 0 and most-significant-bit-first.

## Behavioural Description

`shapool-core` has four main states:

1. `RESET` - Reset
2. `LOAD` - Load device and job data
3. `EXEC` - Execute job
4. `DONE` - Done executing, read result

The device enters the `RESET` state whenever the device's `reset_n` signal is asserted. This state resets execution state but retains job and configuration data.

Immediately after resetting, the device enters the `LOAD` state, while `reset_n` is still asserted. During the `LOAD` state, both SPI interfaces 0 and 1 are active. Job data and device configuration data can be written to SPI interfaces 0 and 1 respectively.

After the device is loaded with its job and configuration data, `reset_n` can be de-asserted to put the device into the `EXEC` state.

The device will work on the provided job until it is done. If and when the device is done its job, the device will enter the `DONE` state.

Each device who successfully completes its job will assert its `ready_n` signal. The `ready_n` signal tells the host device that work is completed and the result can be read on SPI interface 1. If the host asserts `cs1_n` while devices are in the `EXEC` state, this will force all devices to enter the `DONE` state.

Once all devices are in the `DONE` state, SPI interface 1 is available to read from. Devices who successfully finished their job will provide the result of their job. Otherwise, the device will provide a result of all zeros.

After reading the results from the devices, the host can repeat the process by asserting `reset_n` and loading a new job on SPI interface 0.

## Device configurations

Device-specific configuration data can be written to the device using SPI interface 1 while `reset_n` is asserted.

This typically only needs to be done when the device is initialized, e.g. after a power cycle or reprogramming.

<img src="https://svg.wavedrom.com/{reg:[{name: 'nonce start (MSB)', bits: 8}], config:{bits: 8}}" />

* `nonce start (MSB)`: the most-significant byte of the initial value for the nonce (0-255).

## Job configuration

Job configuration data can be written to the device using SPI interface 0 while `reset_n` is asserted.

This is done as often as required, e.g. after completed or expired jobs.

<img src="https://svg.wavedrom.com/{reg:[{name: 'message head', bits: 96},{name: 'SHA256 state', bits: 256}],config:{bits: 352, lanes: 11}}" />

* `SHA256 state`: the internal state of the first SHA256 after the first block is hashed but before the second block is hashed.
* `message head`: the start of the second block of the first hash.

## Job results

Job result data can be read using SPI interface 1 when `cs1_n` is asserted, `reset_n` is de-asserted, and all devices have entered the `DONE` state.

Devices who did not finish their work will provide all zeros as a result.

<img src="https://svg.wavedrom.com/{reg: [{name: 'winning nonce', bits: 32},{name: 'match flags', bits: 8}],config:{bits: 40, lanes: 1}}" />

* `match flags`: bit positions having `1` denote pipelines (cores) that generated a winning hash.
* `winning nonce`: the nonce that caused the winning hash (uncorrected), or zero if no winning nonce found.

The `winning nonce` provided by devices is "uncorrected." This means that the host is responsible for reconstructing the actual nonce from `match flags` and other knowledge about the devices.

1. The nonce value is +2 greater than the actual nonce that caused the match.
2. Any hard-coded most-significant-bits are zeroed (e.g. in a multi-core configuration.)
3.  `nonce_start_MSB` has not been applied to the returned value.

So, reconstructing the nonce can be done as follows:

1. Subtract 2 from the nonce.

2. Correct the most-significant-bits using the value of match flags and the number of hard-coded bits per device.

   For example, if there are 8 cores per device then there are `ceil(log2(8)) = 3` hard-coded bits per core. If match flags is `0x04` (bit position 2), then the most-significant-bits are `b010 = 2**2`.

3. Apply `nonce_start_MSB` corresponding to the device that supplied the nonce.

   For example, if `nonce_start_MSB = 0x80` and there are 3 hard-coded bits per core, then XOR the result with `0x80 << (24-3) = 0x01000000`