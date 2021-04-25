SHAPOOL_DIR = ../../

# Make all
.phony: all
all: top_basic.bin

# Clean up
.phony: clean
clean:
	rm -f *.json *.asc *.bin

# top_basic

top_basic.json : top_basic.v ../../top.v ../../external_io.v ../../shapool.v ../../sha_unit.v ../../sha_round.v ../../w_expand.v ../../SHA256_K.v ../../difficulty_map.v
	yosys -p 'synth_ice40 -top top_basic -json top_basic.json -abc2 -retime' $^

top_basic.asc: top_basic.json ../../pinout-ice40-hx8k-bg121.pcf
	nextpnr-ice40 --package bg121 --hx8k --json top_basic.json --pcf ../../pinout-ice40-hx8k-bg121.pcf --asc top_basic.asc

top_basic.bin: top_basic.asc
	icepack top_basic.asc top_basic.bin

burn_top_basic: top_basic.bin
	iceprog top_basic.bin