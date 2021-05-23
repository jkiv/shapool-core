ICEPOOL_PATH=./icepool-driver/src/
LIBICEPOOL_PATH=./icepool-driver/src/
FTDI_PATH=/usr/include/ftdi1
LIBFTDI_PATH=/usr/lib

.phony : run
run : btc_four_zeroes flash
	./btc_four_zeroes

btc_four_zeroes : main.c libicepool-d.a
	gcc --std=c99 -g -o $@ -I$(ICEPOOL_PATH) -I$(FTDI_PATH) $< -L$(LIBICEPOOL_PATH) -licepool-d -L$(LIBFTDI_PATH) -lftdi1

.phony : clean
clean :
	make -C icepool-driver/src/ clean
	rm -f btc_four_zeroes

.phony : libicepool-d.a
libicepool-d.a :
	make -C $(ICEPOOL_PATH) $@

.phony : flash 
flash :
	make -C ../../ burn-icepool-ice40hx8k