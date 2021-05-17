# Make all
.phony: all
all: blinky.bin basic.bin spi_32.bin

# Clean up
.phony: clean
clean:
	rm -f *.json *.asc *.bin

# blinky

blinky.json : top_blinky.v
	yosys -p 'synth_ice40 -top top -json $@ -abc2 -retime' $^

blinky.asc: blinky.json ../../../pinout-icepool-ice40hx8k.pcf
	nextpnr-ice40 --package bg121 --hx8k --json blinky.json --pcf ../../../pinout-icepool-ice40hx8k.pcf --asc blinky.asc

blinky.bin: blinky.asc
	icepack $^ $@ 

blinky: blinky.bin
	iceprog -v -s -S $^

# basic

basic.json : top_basic.v ../../../top.v ../../../external_io.v ../../../shapool.v ../../../sha_unit.v ../../../sha_round.v ../../../w_expand.v ../../../SHA256_K.v ../../../difficulty_map.v
	yosys -p 'synth_ice40 -top top_basic -json $@ -abc2 -retime' $^

basic.asc: basic.json ../../../pinout-icepool-ice40hx8k.pcf
	nextpnr-ice40 --package bg121 --hx8k --json basic.json --pcf ../../../pinout-icepool-ice40hx8k.pcf --asc basic.asc

basic.bin: basic.asc
	icepack $^ $@ 

basic: basic.bin
	iceprog -v -s -S $^

# spi_32

spi_32.json : top_spi_32.v
	yosys -p 'synth_ice40 -top top -json $@ -abc2 -retime' $^

spi_32.asc: spi_32.json ../../../pinout-icepool-ice40hx8k.pcf
	nextpnr-ice40 --package bg121 --hx8k --json spi_32.json --pcf ../../../pinout-icepool-ice40hx8k.pcf --asc spi_32.asc

spi_32.bin: spi_32.asc
	icepack $^ $@ 
	
spi_32: spi_32.bin
	iceprog -v -s -S $^
