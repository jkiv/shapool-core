#include <stdlib.h>
#include <stdio.h>
#include "icepool.h"

#define DEVICE_COUNT 3
#define DEVICE_CONFIG_LEN (8/8)
#define DEVICE_RESULT_LEN (32/8) 
#define JOB_CONFIG_LEN (360/8)

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

int main()
{
    // Set up icepool context
    IcepoolContext* ctx = icepool_new();

    // Assert reset_n
    icepool_assert_reset(ctx);

    // Set up device data
    
    uint8_t device_config[DEVICE_COUNT*DEVICE_CONFIG_LEN] = {
        // Device 3
        0xB0,
        // Device 2
        0x60,
        // Device 1
        0x00
    };

    // Set up job data

    uint8_t job_config[JOB_CONFIG_LEN] = {
        // SHA initial state:
        0xdc, 0x6a, 0x3b, 0x8d, 0x0c, 0x69, 0x42, 0x1a,
        0xcb, 0x1a, 0x54, 0x34, 0xe5, 0x36, 0xf7, 0xd5,
        0xc3, 0xc1, 0xb9, 0xe4, 0x4c, 0xbb, 0x9b, 0x8f,
        0x95, 0xf0, 0x17, 0x2e, 0xfc, 0x48, 0xd2, 0xdf,
        // Message head:
        0xdc, 0x14, 0x17, 0x87, 0x35, 0x8b, 0x05, 0x53,
        0x53, 0x5f, 0x01, 0x19,
        // Difficulty offset (BASE_DIFFICULTY + 3 = 4 bits)
        0x03
    };
        // Expected nonce: 39
        // Expected hash: c7f3244e501edf780c420f63a4266d30ffe1bdb53f4fde3ccd688604f15ffd03

    // Send device data
    icepool_spi_assert_daisy(ctx);

    for (size_t n = 0; n < DEVICE_COUNT; n++) {
        icepool_spi_write_daisy(ctx, &device_config[0], DEVICE_COUNT*DEVICE_CONFIG_LEN);
    }

    icepool_spi_deassert_daisy(ctx);

    // Send job data
    icepool_spi_assert_shared(ctx);

    icepool_spi_write_shared(ctx, job_config, JOB_CONFIG_LEN);

    icepool_spi_deassert_shared(ctx);

    // Deassert reset_n (start executing)
    icepool_deassert_reset(ctx);

    // Wait for READY
    while(!icepool_poll_ready(ctx));

    // Get result

    uint8_t results[DEVICE_COUNT*DEVICE_RESULT_LEN] = { 0 };

    icepool_spi_assert_daisy(ctx);

    icepool_spi_read_daisy(ctx, results, DEVICE_COUNT*DEVICE_RESULT_LEN);

    icepool_spi_assert_daisy(ctx);

    // Test nonce

    print_buffer(results, DEVICE_COUNT*DEVICE_RESULT_LEN);

    // Clean up

    icepool_free(ctx);

    return EXIT_SUCCESS;
}