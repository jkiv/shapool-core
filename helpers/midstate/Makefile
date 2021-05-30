.phony : all
all : midstate.so

midstate.so : midstate.c
	gcc --std=c99 -Wall -fPIC -shared -o $@ $^

midstate.o : midstate.c

.phony : clean
clean :
	rm -f midstate.so