/* interface
 *
 * IO interface for the top level module.
 */
module external_io(
    clk,
    reset_n,
    // SPI(0)
    sck0,
    sdi0,
    cs0_n,
    // SPI(1)
    sck1,
    sdi1,
    sdo1,
    cs1_n,
    // Stored data
    device_config,
    job_config,
    // From shapool
    shapool_result,
    shapool_success,
    // READY signal
    ready
);

    parameter JOB_CONFIG_WIDTH = 1;
    parameter DEVICE_CONFIG_WIDTH = 1;
    parameter RESULT_DATA_WIDTH = 1;

    // Inputs and outputs

    input wire clk;
    input wire reset_n;

    input wire sck0;
    input wire sdi0;
    input wire cs0_n;

    input wire sck1;
    input wire sdi1;
    output wire sdo1;
    input wire cs1_n; 

    // Stored data
    output reg [DEVICE_CONFIG_WIDTH-1 : 0] device_config = 0;
    output reg [JOB_CONFIG_WIDTH-1 : 0] job_config = 0;
    reg [RESULT_DATA_WIDTH-1 : 0] result_data = 0;

    // From shapool
    input wire [RESULT_DATA_WIDTH-1 : 0] shapool_result;
    input wire shapool_success;

    // READY signal
    output reg ready;

    // State machine definition
    localparam STATE_IDLE = 2'b00,
               STATE_EXEC = 2'b01,
               STATE_DONE = 2'b10,
               STATE_UNKN = 2'b11;

    reg [1:0] state = STATE_IDLE;

    // Synchronize SPI signals to core `clk`

    reg [2:0] sck0_sync = 0;
    reg [1:0] sdi0_sync = 0;
    wire sck0_sync_rising_edge;
    
    reg [2:0] sck1_sync = 0;
    reg [1:0] sdi1_sync = 0;
    wire sck1_sync_rising_edge;
    /* verilator lint_off UNUSED */
    wire sck1_sync_falling_edge;
    /* verilator lint_on UNUSED */

    // Synchronize SPI signals to reference clk
    always @(posedge clk)
      begin
        if (!reset_n)
          begin
            sck0_sync <= 0;
            sdi0_sync <= 0;
            sck1_sync <= 0;
            sdi1_sync <= 0;
          end
        else
          begin
            sck0_sync <= { sck0_sync[1:0], sck0 };
            sdi0_sync <= { sdi0_sync[0], sdi0 };
            sck1_sync <= { sck1_sync[1:0], sck1 };
            sdi1_sync <= { sdi1_sync[0], sdi1 };
          end
      end

    assign sck0_sync_rising_edge = !sck0_sync[2] & sck0_sync[1];
    assign sck1_sync_rising_edge = !sck1_sync[2] & sck1_sync[1];
    assign sck1_sync_falling_edge = sck1_sync[2] & !sck1_sync[1];

    // `sdo1` comes from `result_data` when STATE_DONE, otherwise `device_config`
    assign sdo1 = (state == STATE_DONE) ?
                    result_data[RESULT_DATA_WIDTH-1] :
                    device_config[DEVICE_CONFIG_WIDTH-1];

    // Main state machine process
    always @(posedge clk)
      begin
        if (!reset_n)
          begin
            state <= STATE_IDLE;
            ready <= 1'b0;
          end
        else
          begin

            case(state)

              STATE_IDLE:
                begin
                  // Go to STATE_EXEC when `reset_n` is deasserted
                  if (reset_n)
                      state <= STATE_EXEC;

                  // Allow `job_config` and `device_config` to be shifted in while `reset_n` is asserted.
                  else
                    begin

                      // Shift in `job_config` (msb-first) on rising edge
                      if (!cs0_n && sck0_sync_rising_edge)
                        job_config <= { job_config[JOB_CONFIG_WIDTH-2 : 0], sdi0_sync[1] };
                      
                      // Shift in `device_config` (msb-first) on rising edge
                      if (!cs1_n && sck1_sync_rising_edge)
                        device_config <= { device_config[DEVICE_CONFIG_WIDTH-2 : 0], sdi1_sync[1] };

                    end
                end
              STATE_EXEC:

                if (shapool_success)
                  begin
                    state <= STATE_DONE;
                    ready <= 1'b1;

                    /* verilator lint_off WIDTHCONCAT */

                    // NOTE: The top POOL_SIZE_LOG2 bits are zeroed.
                    //       Host needs to perform check on all possible combination
                    //       of these bits.

                    // NOTE: When "success" occurs, the current nonce value is
                    //       one value ahead of the nonce value that caused the success.
                    //       This is because the nonce value feeds the first hash unit,
                    //       whereas success is determined by the result of the
                    //       second.
                    //       In order to save resources, the host is responsible for
                    //       correcting this offset. 
                    result_data <= shapool_result;
                    /* verilator lint_on WIDTHCONCAT */
                  end

                // Exit STATE_EXEC when `cs1_n` is asserted
                // TODO ready_neighbour signal OR cs1_n, go to DONE?
                else if (!cs1_n)
                  begin
                    ready <= 1'b1; // Forces core to halt
                    state <= STATE_DONE;
                    result_data <= {(RESULT_DATA_WIDTH){1'b0}};
                  end

              STATE_DONE:
                begin
                  // Shift-in `result_data` (msb-first) on rising edge
                  if (!cs1_n && sck1_sync_rising_edge)
                    result_data <= { result_data[RESULT_DATA_WIDTH-2 : 0], sdi1_sync[1] };
                end

              default:
                state <= STATE_IDLE;

            endcase
          end
      end

endmodule