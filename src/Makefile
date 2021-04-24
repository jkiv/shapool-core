# ICE40UP5K-B-EVB
#top-pcf = pinout-up5k-sg48i.pcf
#arachne-params = -d 5k -P sg48
#icetime-params = -d 5k -P sg48 

# ICE40HX8K-B-EVN
#top-pcf = pinout-hx8k-ct256.pcf
#arachne-params = -d 8k -P ct256
#icetime-params = -d hx8k -P ct256

# TODO update for next-pnr, e.g.
##	yosys -p 'synth_ice40 -top top_basic -json top_basic.json -abc2 -retime' $^
##	nextpnr-ice40 --package bg121 --hx8k --json top_basic.json --pcf ../../pinout-hx8k-bg121.pcf --asc top_basic.asc

# Synthesize for device

shapool-ice40-hx8k.json : top_hx8k.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	yosys -p 'synth_ice40 -top top_hx8k -json $@ -abc2 -retime' $^

shapool-ice40-up5k.json : top_up5k.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	yosys -p 'synth_ice40 -top top_up5k -blif $@ -abc2 -retime' $^

# Route for device and package

shapool-ice40-hx8k-ct256.asc : shapool-ice40-hx8k.json pinout-ice40-hx8k-ct256.pcf
	nextpnr-ice40 --package ct256 --hx8k --json shapool-ice40-hx8k.json --pcf pinout-ice40-hx8k-ct256.pcf --asc $@

shapool-ice40-hx8k-bg121.asc : shapool-ice40-hx8k.json pinout-ice40-hx8k-bg121.pcf
	nextpnr-ice40 --package bg121 --hx8k --json shapool-ice40-hx8k.json --pcf pinout-ice40-hx8k-bg121.pcf --asc $@

shapool-ice40-up5k-sg48.asc : shapool-ice40-up5k.json pinout-ice40-up5k-sg48.pcf
	nextpnr-ice40 --package sg48 --up5k --json shapool-ice40-up5k.json --pcf pinout-ice40-up5k-sg48.pcf --asc $@

# Generate bitstream

shapool-ice40-hx8k-ct256.bin : shapool-ice40-hx8k-ct256.asc
	icepack $^ $@

shapool-ice40-hx8k-bg121.bin : shapool-ice40-hx8k-bg121.asc
	icepack $^ $@

shapool-ice40-up5k-sg48.bin : shapool-ice40-up5k-sg48.asc
	icepack $^ $@

# Run timing simulations

time-ice40-hx8k-ct256 : shapoo-ice40-hx8k-ct256.asc
	icetime -t -m -d hx8k -P ct256 -p pinout-icepool-hx8k-ct256.pcf -o - $^

time-ice40-hx8k-bg121 : shapool-ice40-hx8k-bg121.asc
	icetime -t -m -d hx8k -P cm121 -p pinout-icepool-hx8k-bg121.pcf -o - $^
	# TODO bg121 supported?

time-ice40-up5k-sg48 : shapool-ice400-up5k-sg48.asc
	icetime -t -m -d up5k -P sg48 -p pinout-icepool-up5k-sg48.pcf -o - $^

.phony: time

# Make target binary and upload to device
burn-ice40-hx8k-ct256 : shapool-ice40-hx8k-ct256.bin
	iceprog $^

burn-ice40-hx8k-bg121 : shapool-ice40-hx8k-bg121.bin
	iceprog $^

burn-ice40-up5k-sg48 : shapool-ice40-up5k-sg48.bin
	iceprog $^

# Validate verilog code...

lint : top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	verilator -Wall -cc top.v

.phony: lint

# Clean up

.phony: clean_build
clean_build :
	rm -f shapool-*.out \
		  shapool-*.blif \
		  shapool-*.asc \
		  shapool-*.bin

.phony: clean
clean: clean_build