#include <stdlib.h>
#include <stdio.h>
#include "icepool.h"

#define DEVICE_COUNT 1 
#define DUMP_SIZE (64/8)

void print_buffer(const uint8_t* buffer, size_t buffer_len)
{
    for(size_t i = 0; i < buffer_len; )
    {
        for (size_t j = 0; j < 8 && i < buffer_len; j++, i++)
        {
            printf("%02x ", buffer[i]);
        }
        printf("\n");
    }
}

void dump_Kt(IcepoolContext* ctx)
{
    uint8_t dump[DUMP_SIZE] = { 0 };

    icepool_assert_reset(ctx);
    icepool_deassert_reset(ctx);

    // Wait for READY
    while(icepool_poll_ready(ctx) == false) { printf("."); fflush(stdout); }
    printf("\n");

    icepool_spi_assert_daisy(ctx);

    icepool_spi_read_daisy(ctx, dump, DUMP_SIZE);

    icepool_spi_assert_daisy(ctx);

    icepool_assert_reset(ctx);

    printf("0x10_000000\t");
    print_buffer(&dump[0], 4);

    printf("0x10_111111\t");
    print_buffer(&dump[4], 4);
}

int main()
{
    // Set up icepool context
    IcepoolContext* ctx = icepool_new();

    if (!ctx) {
        fprintf(stderr, "Could not initialize IcepoolContext. Quitting...\n");
        exit(EXIT_FAILURE);
    }

    dump_Kt(ctx);

    icepool_free(ctx);

    return EXIT_SUCCESS;
}