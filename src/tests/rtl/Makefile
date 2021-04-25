# Make all
.phony: all
all: icepool-ice40hx8k ice40hx8k-b-evn

# Clean up
.phony: clean
clean:
	make -C ice40hx8k-b-evn/ clean
	make -C icepool-ice40hx8k/ clean

.phony: icepool-ice40hx8k
icepool-ice40hx8k:
	make -C icepool-ice40hx8k/ all

.phony: ice40hx8k-b-evn
ice40hx8k-b-evn:
	make -C ice40hx8k-b-evn/ all

# TODO ice40up5k-b-evn