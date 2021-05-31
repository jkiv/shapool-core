.phony : all
all : midstate_sha256.so

midstate_sha256.so : midstate_sha256.c
	gcc --std=c99 -Wall -fPIC -shared -o $@ $^

.phony : test
test : midstate_sha256.so
	pytest

.phony : clean
clean :
	rm -f midstate_sha256.so
	rm -rf __pycache__/
	rm -rf .pytest_cache/