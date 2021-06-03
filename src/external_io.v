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
    // Control signals
    core_reset_n,
    // From shapool
    shapool_success,
    shapool_result,
    // READY signal
    ready
);

    parameter POOL_SIZE = 2;
    parameter POOL_SIZE_LOG2 = 1;

    parameter DEVICE_CONFIG_WIDTH = 8;        // nonce_start
    parameter JOB_CONFIG_WIDTH    = 256 + 96; // sha_state + message_head
    parameter RESULT_DATA_WIDTH   = 32 + 8;   // nonce + match flags
    // FUTURE scale match_flags?

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
    output reg [   JOB_CONFIG_WIDTH-1 : 0] job_config    = 0;
    // output reg [   JOB_CONFIG_WIDTH-1 : 0] job_config = {
    //   128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5, // SHA starting state
    //   128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df, // ...
    //   96'hdc141787_358b0553_535f0119            // Start of message block
    // };

    output reg core_reset_n = 1;

    reg [RESULT_DATA_WIDTH-1 : 0] result_data = 0;

    // From shapool
    input wire shapool_success;
    input wire [RESULT_DATA_WIDTH-1:0] shapool_result;

    // READY signal
    output reg ready;

    // State machine definition
    localparam STATE_RESET = 2'b00,
               STATE_LOAD  = 2'b01,
               STATE_EXEC  = 2'b10,
               STATE_DONE  = 2'b11;

    reg [1:0] state = STATE_RESET;

    // Synchronize SPI signals to reference `clk`

    reg [2:0] sck0_sync = 0;
    reg [1:0] sdi0_sync = 0;
    wire sck0_sync_rising_edge;
    
    reg [2:0] sck1_sync = 0;
    reg [1:0] sdi1_sync = 0;
    wire sck1_sync_rising_edge;

    always @(posedge clk)
      begin
        sck0_sync <= { sck0_sync[1], sck0_sync[0], sck0 };
        sck1_sync <= { sck1_sync[1], sck1_sync[0], sck1 };

        sdi0_sync <= { sdi0_sync[0], sdi0 };
        sdi1_sync <= { sdi1_sync[0], sdi1 };
      end

    assign sck0_sync_rising_edge  = ~sck0_sync[2] & sck0_sync[1];
    assign sck1_sync_rising_edge  = ~sck1_sync[2] & sck1_sync[1];

    // `sdo1` comes from `result_data` when STATE_DONE, otherwise `device_config`
    assign sdo1 = (state == STATE_DONE)
                    ? result_data[RESULT_DATA_WIDTH-1]
                    : device_config[DEVICE_CONFIG_WIDTH-1];

    // Main state machine process
    always @(posedge clk)
      begin
        case(state)

          STATE_RESET:
            begin
              ready <= 0;          // Deassert READY
              core_reset_n <= 0;   // Halt core
              state <= STATE_LOAD;
            end

          STATE_LOAD:
            begin

              // Go to STATE_EXEC when `reset_n` is deasserted
              if (reset_n)
                begin
                  core_reset_n <= 1;
                  state <= STATE_EXEC;
                end

              // Allow `job_config` and `device_config` to be shifted in while `reset_n` is asserted.
              else
                begin
                  // SPI0
                  if (!cs0_n && sck0_sync_rising_edge)
                    job_config <= { job_config[JOB_CONFIG_WIDTH-2 : 0], sdi0_sync[1] };
                  
                  // SPI1
                  if (!cs1_n && sck1_sync_rising_edge)
                    device_config <= { device_config[DEVICE_CONFIG_WIDTH-2 : 0], sdi1_sync[1] };
                end
            end

          STATE_EXEC:
            begin
              core_reset_n <= 1;

              // Go to STATE_RESET when `reset_n` is asserted
              if (!reset_n)
                begin
                  state <= STATE_RESET;
                end
              // Go to STATE_DONE when `shapool_success` is asserted
              else if (shapool_success)
                begin
                  state <= STATE_DONE;
                  ready <= 1;
                  core_reset_n <= 0;
  
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
              // Go to STATE_DONE when `cs1_n` is asserted
              // FUTURE neighbour READY 
              else if (!cs1_n)
                begin
                  state <= STATE_DONE;
                  ready <= 1;
                  core_reset_n <= 0;
                  result_data <= 0;
                end
            end

          STATE_DONE:
            begin
              if (!reset_n)
                state <= STATE_RESET;

              // Shift-in `result_data` (msb-first) on rising edge
              if (!cs1_n && sck1_sync_rising_edge)
                result_data <= { result_data[RESULT_DATA_WIDTH-2 : 0], sdi1_sync[1] };

            end

          default:
            state <= STATE_RESET;

        endcase
      end

endmodule