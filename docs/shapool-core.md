## About `shapool-core`

`shapool-core` is an FPGA core that computes double-SHA256 hashes for the purposes of cryptocurrency mining, e.g. Bitcoin.

`shapool-core` is intended to be used in a cluster-like environment but should work as a stand-alone core, i.e. a cluster of one.

Each `shapool-core` device in a cluster is given the same job data by the host device. Each device works on the job until it either finishes or is interrupted by the host device.

The work required for each job can be divided among the cluster by providing each `shapool-core` device with unique a device parameters such that no two devices will perform the same work.

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
* `ready_n_ts` - active-low, open-drain "data ready" output
* `status_led_n` - active-low indicator LED output

SPI interface 0 is a one-to-many interface which allows the host device load the same job data to all `shapool-core` devices on the SPI bus. Note that this interface does not have a data output.

SPI interface 1 is a daisy-chained interface which allows the host device to load each `shapool-core` with device-specific data, as well as read device-specific results back.

Both SPI interfaces are SPI mode 0, 0 and most-significant-bit-first.

## Behavioural Description

`shapool-core` has three main states:

1. `IDLE` - Reset / Idle
2. `EXEC` - Execute job
3. `DONE` - Done executing / Read result

The device enters the `IDLE` state whenever the device's `reset_n` signal is asserted. This state resets execution state but retains job and configuration data.

While `reset_n` is asserted, both SPI interfaces 0 and 1 are active. Job data and device configuration data can be written to SPI interfaces 0 and 1 respectively while `reset_n` is asserted.

After the device is loaded with its job and configuration data, `reset_n` is de-asserted and the device immediately enters the `EXEC` state.

The device will work on the provided job until it is done. If/when the device is done working on its job, the device will enter the `DONE` state.

Each device who successfully completes its job will assert its `ready` signal. The `ready` signal tells the host device that work is completed and the result can be read on SPI interface 1. If the host asserts `cs1_n` while devices are in the `EXEC` state, this will force executing devices to enter the `DONE` state.

Once all devices are in the `DONE` state, SPI interface 1 is available. Devices who successfully finished their job will provide the result of their job. Otherwise, the device will provide a result of all zeros.

After reading the results from the devices, the host can repeat the process by asserting `reset_n` and loading a new job on SPI interface 0.

## Device configurations

Device-specific configuration data can be written to the device using SPI interface 1 while `reset_n` is asserted.

This typically only needs to be done when the device is initialized, e.g. after a power cycle or reprogramming.

```
TODO wavedrom register
```

## Job configuration

Job configuration data can be written to the device using SPI interface 0 while `reset_n` is asserted.

This is done as often as required, e.g. after completed or expired jobs.

```
TODO wavedrom register
```

## Job results

Job result data can be read using SPI interface 1 when `reset_n` is de-asserted.

Asserting `cs1_n` will cause all devices to stop executing.

Devices who did not finish their work will return all zeros as a result.

Job result data is typically only read when `ready_n` is asserted by a device.

```
TODO wavedrom register
```