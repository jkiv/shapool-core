# ICE40UP5K-B-EVN
#top-pcf = pinout-up5k-ice40up5k-b-evni.pcf
#arachne-params = -d 5k -P sg48
#icetime-params = -d 5k -P sg48 

shapool_up5k.json : top_up5k.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v
	yosys -p 'synth_ice40 -top top_up5k -json shapool_up5k.json -abc2 -retime' $^ 

shapool_up5k_ice40up5k-b-evn.asc : shapool_up5k.json pinout-up5k-ice40up5k-b-evn.pcf
	nextpnr-ice40 --up5k --package sg48 --json shapool_up5k.json --pcf pinout-up5k-ice40up5k-b-evn.pcf --asc $@

shapool_up5k_ice40up5k-b-evn.bin : shapool_up5k_ice40up5k-b-evn.asc
	icepack $^ $@

time_up5k_ice40up5k-b-evn : shapool_up5k_ice40up5k-b-evn.asc
	icetime -t -m -d up5k -P sg48 -p pinout-up5k-ice40up5k-b-evn.pcf -o - $^

burn_up5k_ice40up5k-b-evn : shapool_up5k_ice40up5k-b-evn.bin
	iceprog $^

# ICE40HX8K-B-EVN
#top-pcf = pinout-hx8k-ice40hx8k-b-evn.pcf
#arachne-params = -d 8k -P ct256
#icetime-params = -d hx8k -P ct256

shapool_hx8k.json : top_hx8k.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v
	yosys -p 'synth_ice40 -top top_hx8k -json shapool_hx8k.json -abc2 -retime' $^ 
# ... for ICEPOOL as well.

shapool_hx8k_ice40hx8k-b-evn.asc : shapool_hx8k.json pinout-hx8k-ice40hx8k-b-evn.pcf
	nextpnr-ice40 --hx8k --package ct256 --json shapool_hx8k.json --pcf pinout-hx8k-ice40hx8k-b-evn.pcf --asc $@

shapool_hx8k_ice40hx8k-b-evn.bin : shapool_hx8k_ice40hx8k-b-evn.asc
	icepack $^ $@

time_hx8k_ice40hx8k-b-evn : shapool_hx8k_ice40hx8k-b-evn.asc
	icetime -t -m -d hx8k -P ct256 -p pinout-hx8k-ice40hx8k-b-evn.pcf -o - $^

burn_hx8k_ice40hx8k-b-evn : shapool_hx8k_ice40hx8k-b-evn.bin
	iceprog $^

# ICEPOOL
#top-pcf = pinout-hx8k-icepool.pcf
#arachne-params = -d 8k -P cm121
#icetime-params = -d hx8k -P cm121 

shapool_hx8k_icepool.asc : shapool_hx8k.json pinout-hx8k-icepool.pcf
	nextpnr-ice40 --hx8k --package cm121 --json shapool_hx8k.json --pcf pinout-hx8k-icepool.pcf --asc $@

shapool_hx8k_icepool.bin : shapool_hx8k_icepool.asc
	icepack $^ $@

time_hx8k_icepool : shapool_hx8k_icepool.asc
	icetime -t -m -d hx8k -P cm121 -p pinout-hx8k-icepool.pcf -o - $^

burn_hx8k_icepool : shapool_hx8k_icepool.bin
	iceprog $^

# Make target binary and upload to device

# Validate verilog code...

lint : top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v
	verilator -Wall -cc top.v

.phony: lint

# Run tests...

test_top.out : tests/top_test.v top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v difficulty_map.v
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

# TODO .phony test

# Miscellaneous tests...

# TODO specify board to load test onto?
# TODO update to nextpnr-ice40

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

# TODO phony burn_test?

# Helpers...

# TODO update for current structure
shapool.dot : top.v shapool.v sha_unit.v sha_round.v w_expand.v SHA256_K.v
	yosys -p 'show -format dot -prefix shapool' $^

shapool.svg : shapool.dot
	dot -Tsvg $^ -o $@

# Cleanup...

clean_tests :
	rm -f test_top.out \
	      test_multi_top.out \
	      test_shapool.out \
		  test_sha_unit.out \
		  top_power.blif top_power.asc top_power.bin \
	      top_idle.blif top_idle.asc top_idle.bin \
	      top_RAM.blif top_RAM.asc top_RAM.bin \
	      top_tri.blif top_tri.asc top_tri.bin \
	      top_single_39.blif top_single_39.asc top_single_39.bin

.phony: clean_tests

clean_build :
	rm -f shapool_*.out  \
	      shapool_*.json \
	      shapool_*.asc  \
	      shapool_*.bin

.phony: clean_build

clean_helpers :
	rm -f shapool.dot \
	      shapool.svg

.phony: clean_helpers

clean: clean_build clean_tests clean_helpers

.phony: clean

default:
	echo 'TODO message here about targets'
	echo ''
