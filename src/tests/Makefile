# Run all tests

.phony: all
all: sha_round_usage_tb sha_unit_usage_tb shapool_usage_tb external_io_usage_tb

# Clean up after test benches

.phony : clean
clean :
	rm -f *.out *.vcd

# Test benches

sha_round_usage_tb.out : sha_round_usage_tb.v ../sha_round.v
	iverilog -o $@  $^

sha_round_usage_tb : sha_round_usage_tb.out
	vvp $^

##

sha_unit_usage_tb.out : sha_unit_usage_tb.v ../sha_unit.v ../w_expand.v ../sha_round.v
	iverilog -o $@  $^

sha_unit_usage_tb : sha_unit_usage_tb.out
	vvp $^

##

shapool_usage_tb.out : shapool_usage_tb.v ../shapool.v ../difficulty_map.v ../SHA256_K.v ../sha_unit.v ../w_expand.v ../sha_round.v
	iverilog -o $@  $^

shapool_usage_tb : shapool_usage_tb.out
	vvp $^

##

external_io_usage_tb.out : external_io_usage_tb.v ../external_io.v
	iverilog -o $@  $^

external_io_usage_tb : external_io_usage_tb.out
	vvp $^