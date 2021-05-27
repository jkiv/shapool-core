SHAPOOL_PATH=../../../
SHAPOOL_DEPS=$(SHAPOOL_PATH)top.v \
			 $(SHAPOOL_PATH)shapool.v \
			 $(SHAPOOL_PATH)sha_unit.v \
			 $(SHAPOOL_PATH)sha_round.v \
			 $(SHAPOOL_PATH)w_expand.v \
			 $(SHAPOOL_PATH)SHA256_K.v \
			 $(SHAPOOL_PATH)difficulty_map.v \
			 $(SHAPOOL_PATH)external_io.v

SHAPOOL_PCF=$(SHAPOOL_PATH)pinout-icepool-ice40hx8k.pcf

.phony : build
build : shapool.bin

.phony: flash
flash : shapool.bin
	iceprog -v -S $^

shapool.bin : shapool.asc
	icepack $^ $@

shapool.asc : shapool.json $(SHAPOOL_PCF)
	nextpnr-ice40 --package bg121 --hx8k --json shapool.json --pcf $(SHAPOOL_PCF) --asc $@

shapool.json : ./top_test.v $(SHAPOOL_DEPS)
	yosys -p 'synth_ice40 -top top_test -json $@ -abc2 -retime' $^

# Clean up
.phony: clean
clean :
	rm -f shapool.out \
		  shapool.json \
		  shapool.asc \
		  shapool.bin