#include <stdlib.h>
#include <stdio.h>
#include "munit/munit.h"
#include "icepool.h"

#define DEVICE_CONFIG_LEN (8/8)
#define DEVICE_RESULT_LEN (40/8) 
#define JOB_CONFIG_LEN (352/8)

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

void test_spi_daisy_no_exec(IcepoolContext* ctx)
{
    // Set up device data
    uint8_t device_config[DEVICE_CONFIG_LEN] = { 0 };

    uint8_t result[DEVICE_CONFIG_LEN] = { 0 };

    // Try immediate read-after-write

    icepool_assert_reset(ctx);

    icepool_spi_assert_daisy(ctx);

    icepool_spi_write_daisy(ctx, device_config, DEVICE_CONFIG_LEN);

    icepool_spi_read_daisy(ctx, result, DEVICE_CONFIG_LEN);

    icepool_spi_deassert_daisy(ctx);
    
    munit_assert_memory_equal(DEVICE_CONFIG_LEN, device_config, result);
}

void test_spi_daisy_with_exec(IcepoolContext* ctx)
{
    // Set up device data
    uint8_t device_config[DEVICE_CONFIG_LEN] = { 0 };

    uint8_t result[DEVICE_CONFIG_LEN] = { 0 };

    // Try EXEC and reset 
    icepool_assert_reset(ctx);

    icepool_spi_assert_daisy(ctx);

    icepool_spi_write_daisy(ctx, device_config, DEVICE_CONFIG_LEN);

    icepool_spi_deassert_daisy(ctx);

    icepool_deassert_reset(ctx);

    // TODO usleep

    icepool_assert_reset(ctx);

    icepool_spi_assert_daisy(ctx);

    icepool_spi_read_daisy(ctx, result, DEVICE_CONFIG_LEN);

    icepool_spi_deassert_daisy(ctx);

    munit_assert_memory_equal(DEVICE_CONFIG_LEN, device_config, result);
}

void test_btc_four_zeroes(IcepoolContext *ctx)
{
    // Set up device data
    uint8_t device_config[DEVICE_CONFIG_LEN] = { 0 };

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
    };
    // Expected nonce: 39
    // Expected hash: c7f3244e501edf780c420f63a4266d30ffe1bdb53f4fde3ccd688604f15ffd03

    // Assert reset_n
    icepool_assert_reset(ctx);

    // Send device data
    icepool_spi_assert_daisy(ctx);

    icepool_spi_write_daisy(ctx, device_config, DEVICE_CONFIG_LEN);

    icepool_spi_deassert_daisy(ctx);

    // Send job data
    icepool_spi_assert_shared(ctx);

    icepool_spi_write_shared(ctx, job_config, JOB_CONFIG_LEN);

    icepool_spi_deassert_shared(ctx);

    // Deassert reset_n (start executing)
    icepool_deassert_reset(ctx);

    // Wait for READY
    bool ready = false;
    for (size_t i = 0; !ready && i < 1e9; i++)
    {
        ready = icepool_poll_ready(ctx);
    }

    munit_assert_true(ready);

    // Get result

    uint8_t expected_result[DEVICE_RESULT_LEN] = { 0x01, 0x00, 0x00, 0x00, 0x29 };
    uint8_t result[DEVICE_RESULT_LEN] = { 0xFF };

    icepool_spi_assert_daisy(ctx);

    icepool_spi_read_daisy(ctx, result, DEVICE_RESULT_LEN);

    icepool_spi_assert_daisy(ctx);

    // Assert reset_n
    icepool_assert_reset(ctx);

    print_buffer(result, DEVICE_RESULT_LEN);

    munit_assert_memory_equal(DEVICE_RESULT_LEN, result, expected_result);
}

int main()
{
    // Set up icepool context
    IcepoolContext* ctx = icepool_new();

    if (!ctx) {
        fprintf(stderr, "Could not initialize IcepoolContext. Quitting...\n");
        exit(EXIT_FAILURE);
    }

    test_spi_daisy_no_exec(ctx);

    test_spi_daisy_with_exec(ctx);

    test_btc_four_zeroes(ctx);

    icepool_free(ctx);

    return EXIT_SUCCESS;
}