ICEPOOL_PATH=../vendor/icepool-driver/src/
LIBICEPOOL_PATH=../vendor/icepool-driver/src/
FTDI_PATH=/usr/include/ftdi1/
LIBFTDI_PATH=/usr/lib/

.phony : build
build : ram_init_test gateware

.phony : run
run : build flash
	./ram_init_test

ram_init_test : main.c libicepool
	gcc --std=c99 -g -o $@ -I$(ICEPOOL_PATH) -I$(FTDI_PATH) $< -L$(LIBICEPOOL_PATH) -licepool-d -L$(LIBFTDI_PATH) -lftdi1

.phony : libicepool
libicepool :
	make -C $(ICEPOOL_PATH) libicepool-d.a 

.phony : gateware
gateware :
	make -C ./rtl build 

.phony : flash 
flash :
	make -C rtl/ flash

.phony : clean
clean :
	make -C ./rtl clean
	rm -f ./ram_init_test