# Build all bitstreams

.phony: all

all: shapool-ice40hx8k-b-evn.bin shapool-icepool-ice40hx8k.bin # shapool-icepool-ice40up5k.bin 

# Validate verilog code

.phony: lint

lint : top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	verilator -Wall -cc top.v

# Clean up

.phony: clean
clean :
	rm -f shapool-*.out \
		  shapool-*.json \
		  shapool-*.asc \
		  shapool-*.bin
	rm -rf ./obj_dir

# Synthesize for device type

shapool-ice40-hx8k.json : top_hx8k.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	yosys -p 'synth_ice40 -top top_hx8k -json $@ -abc2 -retime' $^

shapool-ice40-up5k.json : top_up5k.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	yosys -p 'synth_ice40 -top top_up5k -json $@ -abc2 -retime' $^

# Route for target board

shapool-ice40hx8k-b-evn.asc : shapool-ice40-hx8k.json pinout-ice40hx8k-b-evn.pcf
	nextpnr-ice40 --package ct256 --hx8k --json shapool-ice40-hx8k.json --pcf pinout-ice40hx8k-b-evn.pcf --asc $@

#shapool-icepool-ice40up5k.asc : shapool-ice40-up5k.json pinout-ice40up5k-b-evn.pcf
#	nextpnr-ice40 --package sg48 --up5k --json shapool-ice40-up5k.json --pcf pinout-ice40up5k-b-evn.pcf --asc $@

shapool-icepool-ice40hx8k.asc : shapool-ice40-hx8k.json pinout-icepool-ice40hx8k.pcf
	nextpnr-ice40 --package bg121 --hx8k --json shapool-ice40-hx8k.json --pcf pinout-icepool-ice40hx8k.pcf --asc $@

# Generate bitstream for target board

shapool-ice40hx8k-b-evn.bin : shapool-ice40hx8k-b-evn.asc
	icepack $^ $@

#shapool-icepool-ice40up5k.bin : shapool-icepool-ice40up5k.asc
#	icepack $^ $@

shapool-icepool-ice40hx8k.bin : shapool-icepool-ice40hx8k.asc
	icepack $^ $@

# Run timing simulations

.phony: time-ice40hx8k-b-evn
time-ice40hx8k-b-evn : shapool-ice40hx8k-v-evn.asc
	icetime -t -m -d hx8k -P ct256 -p pinout-ice40hx8k-b-evn.pcf -o - $^

#.phony: time-ice40up5k-b-evn
#time-ice40up5k-b-evn : shapool-icepool-ice40up5k.asc
#	icetime -t -m -d up5k -P sg48 -p pinout-ice40up5k-b-evn.pcf -o - $^

.phony: time-icepool-ice40hx8k
time-icepool-ice40hx8k : shapool-icepool-ice40hx8k.asc
	#icetime -t -m -d hx8k -P cm121 -p pinout-icepool-ice40hx8k.pcf -o - $^
	icetime -t -m -d hx8k -P bg121 -p pinout-icepool-ice40hx8k.pcf -o - $^

# Make target binary and upload to device

.phony: flash-ice40hx8k-b-evn
flash-ice40hx8k-b-evn : shapool-ice40-hx8k-ct256.bin
	iceprog -v -S $^

#.phony: flash-ice40up5k-b-evn
#flash-ice40up5k-b-evn : shapool-icepool-ice40up5k.bin
#	iceprog -v -S $^

.phony: flash-icepool-ice40hx8k
flash-icepool-ice40hx8k : shapool-icepool-ice40hx8k.bin
	iceprog -v -S $^
