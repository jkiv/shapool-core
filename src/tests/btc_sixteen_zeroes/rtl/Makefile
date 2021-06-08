SHAPOOL_PATH=../../../
SHAPOOL_DEPS=$(SHAPOOL_PATH)top.v \
			 $(SHAPOOL_PATH)shapool.v \
			 $(SHAPOOL_PATH)sha_unit.v \
			 $(SHAPOOL_PATH)sha_round.v \
			 $(SHAPOOL_PATH)w_expand.v \
			 $(SHAPOOL_PATH)SHA256_K.v \
			 $(SHAPOOL_PATH)external_io.v

TEST_NAME=btc_sixteen_zeroes
SHAPOOL_PCF=$(SHAPOOL_PATH)pinout-icepool-ice40hx8k.pcf

.phony : build
build : $(TEST_NAME).bin

.phony: flash
flash : $(TEST_NAME).bin
	iceprog -v -S $^

$(TEST_NAME).bin : $(TEST_NAME).asc
	icepack $^ $@

$(TEST_NAME).asc : $(TEST_NAME).json $(SHAPOOL_PCF)
	nextpnr-ice40 --package bg121 --hx8k --json $(TEST_NAME).json --pcf $(SHAPOOL_PCF) --asc $@

$(TEST_NAME).json : ./top_test.v $(SHAPOOL_DEPS)
	yosys -p 'synth_ice40 -top top_test -json $@ -abc2 -retime' $^

# Clean up
.phony: clean
clean :
	rm -f $(TEST_NAME).out \
		  $(TEST_NAME).json \
		  $(TEST_NAME).asc \
		  $(TEST_NAME).bin