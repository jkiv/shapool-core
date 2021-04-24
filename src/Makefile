# ICE40UP5K-B-EVB
#top-pcf = pinout-up5k-sg48i.pcf
#arachne-params = -d 5k -P sg48
#icetime-params = -d 5k -P sg48 

# ICE40HX8K-B-EVN
#top-pcf = pinout-hx8k-ct256.pcf
#arachne-params = -d 8k -P ct256
#icetime-params = -d hx8k -P ct256

shapool_hx8k.blif : top_hx8k.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	yosys -p 'synth_ice40 -top top_hx8k -blif $@ -abc2 -retime' $^

shapool_up5k.blif : top_up5k.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	yosys -p 'synth_ice40 -top top_up5k -blif $@ -abc2 -retime' $^

# Route for given device...

shapool_hx8k_ct256.asc : shapool_hx8k.blif pinout-hx8k-ct256.pcf
	arachne-pnr -d 8k -P ct256 -o $@ -p pinout-hx8k-ct256.pcf shapool_hx8k.blif

shapool_hx8k_bg121.asc : shapool_hx8k.blif pinout-hx8k-bg121.pcf
	arachne-pnr -d 8k -P cm121 -o $@ -p pinout-hx8k-bg121.pcf shapool_hx8k.blif

shapool_up5k_sg48.asc : shapool_up5k.blif pinout-up5k-sg48.pcf
	arachne-pnr -d 5k -P sg48 -o $@ -p pinout-up5k-sg48.pcf shapool_up5k.blif

# Make target binary only...

shapool_hx8k_ct256.bin : shapool_hx8k_ct256.asc
	icepack $^ $@

shapool_hx8k_bg121.bin : shapool_hx8k_bg121.asc
	icepack $^ $@

shapool_up5k_sg48.bin : shapool_up5k_sg48.asc
	icepack $^ $@

# Run timing tests using icetime...

time_hx8k_ct256 : shapool_hx8k_ct256.asc
	icetime -t -m -d hx8k -P ct256 -p pinout-hx8k-ct256.pcf -o - $^

time_hx8k_bg121 : shapool_hx8k_bg121.asc
	icetime -t -m -d hx8k -P cm121 -p pinout-hx8k-bg121.pcf -o - $^

time_up5k_sg48 : shapool_up5k_sg48.asc
	icetime -t -m -d up5k -P sg48 -p pinout-up5k-sg48.pcf -o - $^

.phony: time

# Make target binary and upload to device
burn_hx8k_ct256 : shapool_hx8k_ct256.bin
	iceprog $^

burn_hx8k_bg121 : shapool_hx8k_bg121.bin
	iceprog $^

burn_up5k_sg48 : shapool_up5k_sg48.bin
	iceprog $^


# Validate verilog code...

lint : top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	verilator -Wall -cc top.v

.phony: lint

# Run tests...

test_top.out : tests/top_test.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v external_io.v
	iverilog -o $@  $^

test_top : test_top.out
	vvp $^ 

test_multi_top.out : tests/multi_top_test.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v
	iverilog -o $@  $^

test_multi_top : test_multi_top.out
	vvp $^ 

test_shapool.out : tests/shapool_test.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v
	iverilog -o $@  $^

test_shapool : test_shapool.out
	vvp $^

test_sha_unit.out : tests/sha_unit_test.v sha_unit.v sha_round.v w_expand.v
	iverilog -o $@  $^

test_sha_unit : test_sha_unit.out
	vvp $^

# Miscellaneous tests...

burn_basic_test: top_basic.v top.v external_io.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v
	yosys -p 'synth_ice40 -top top_basic -json top_basic.json -abc2 -retime' $^
	nextpnr-ice40 --package bg121 --hx8k --json top_basic.json --pcf pinout-hx8k-bg121.pcf --asc top_basic.asc
	icepack top_basic.asc top_basic.bin 
	iceprog top_basic.bin 

icepool_test.asc : icepool_test.json pinout.pcf
	#arachne-pnr -d 8k -P ct256 -o $@ -p pinout.pcf icepool_test.blif


# VVV obsolete TODO remove

burn_power_test: tests/hx8k-b-evn/top_power.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v
	yosys -p 'synth_ice40 -top top_power -blif top_power.blif -abc2' $^ 
	arachne-pnr -d 8k -p ct256 -o top_power.asc -p tests/hx8k-b-evn/top_power.pcf top_power.blif
	icepack top_power.asc top_power.bin 
	iceprog top_power.bin 

.phony: burn_power_test

burn_idle_test: tests/hx8k-b-evn/top_idle.v
	yosys -p 'synth_ice40 -top top_idle -blif top_idle.blif -abc2' $^ 
	arachne-pnr -d 8k -p ct256 -o top_idle.asc -p tests/hx8k-b-evn/top_idle.pcf top_idle.blif
	icepack top_idle.asc top_idle.bin 
	iceprog top_idle.bin 

.phony: burn_idle_test

burn_RAM_test: tests/hx8k-b-evn/top_RAM.v SHA256_K.v
	yosys -p 'synth_ice40 -top top_RAM -blif top_RAM.blif -abc2' $^ 
	arachne-pnr -d 8k -p ct256 -o top_RAM.asc -p tests/hx8k-b-evn/top_RAM.pcf top_RAM.blif
	icepack top_RAM.asc top_RAM.bin 
	iceprog top_RAM.bin 

.phony: burn_RAM_test

burn_tri_test: tests/hx8k-b-evn/top_tri.v
	yosys -p 'synth_ice40 -top top_tri -blif top_tri.blif -abc2' $^ 
	arachne-pnr -d 8k -p ct256 -o top_tri.asc -p tests/hx8k-b-evn/top_tri.pcf top_tri.blif
	icepack top_tri.asc top_tri.bin 
	iceprog top_tri.bin 

.phony: burn_tri_test

burn_single_39_test: tests/hx8k-b-evn/top_single_39.v shapool.v difficulty_map.v SHA256_K.v sha_unit.v sha_round.v w_expand.v
	yosys -p 'synth_ice40 -top top_single_39 -blif top_single_39.blif -abc2' $^ 
	arachne-pnr -d 8k -p ct256 -o top_single_39.asc -p tests/hx8k-b-evn/top_single_39.pcf top_single_39.blif
	icepack top_single_39.asc top_single_39.bin 
	iceprog top_single_39.bin 

.phony: burn_single_39_test

# Helpers...

# TODO update for current structure
shapool.dot : top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v
	yosys -p 'show -format dot -prefix shapool' $^

shapool.svg : shapool.dot
	dot -Tsvg $^ -o $@

# Cleanup...

clean_build :
	rm -f shapool_*.out \
		  shapool_*.blif \
		  shapool_*.asc \
		  shapool_*.bin

.phony: clean_build

clean_helpers :
	rm -f shapool.dot \
		  shapool.svg

.phony: clean_helpers

clean: clean_build clean_helpers

.phony: clean