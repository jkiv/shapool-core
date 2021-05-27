.phony : test_benches 
test_benches: sha_round_usage_tb sha_unit_usage_tb shapool_usage_tb external_io_usage_tb

.phony : hardware_tests 
hardware_tests : btc_four_zeroes 

.phony : all
all : test_benches hardware_tests	

.phony : clean
clean : clean_test_benches clean_hardware_tests

.phony : clean_test_benches
clean_test_benches :
	rm -f *.out *.vcd

.phony : clean_hardware_tests
clean_hardware_tests :
	make -C ./btc_four_zeroes clean

# Testbench 

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

# Tests requiring hardware

.phony : btc_four_zeroes
btc_four_zeroes :
	make -C ./btc_four_zeroes run