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
    shapool_success
);

    parameter JOB_CONFIG_WIDTH = 1;
    parameter DEVICE_CONFIG_WIDTH = 1;
    parameter RESULT_DATA_WIDTH = 1;
    parameter SHAPOOL_RESULT_WIDTH = 1;

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
    input wire [SHAPOOL_RESULT_WIDTH-1 : 0] shapool_result;
    input wire shapool_success;

    // State machine definition
    localparam STATE_IDLE = 2'b00,
               STATE_EXEC = 2'b01,
               STATE_DONE = 2'b10,
               STATE_UNKN = 2'b11;

    reg [1:0] state = STATE_IDLE;

    // State machine process
    always @(posedge clk)
      begin
        if (!reset_n)
          begin
            state <= STATE_IDLE;
            
            result_data <= {(RESULT_DATA_WIDTH){1'b0}};
          end
        else
          begin
            case(state)
              STATE_IDLE:
                if (reset_n)
                  begin
                    state <= STATE_EXEC;
                  end
              STATE_EXEC:
                if (shapool_success)
                  begin
                    state <= STATE_DONE;
                    
                    /* verilator lint_off WIDTHCONCAT */

                    // NOTE: The top POOL_SIZE_LOG2 bits are zeroed.
                    //       Host needs to perform check on all possible combination
                    //       of these bits.
                    // TODO eliminate the need for this ^

                    // NOTE: Success occurred a previous nonce.
                    //       By the time nonce is saved, the hash is for the value
                    //       of nonce - 1. In order to save resources, the host is
                    //       responsible for correcting this offset. 
                    // TODO elimate this comment
                    result_data <= {
                      {(RESULT_DATA_WIDTH-SHAPOOL_RESULT_WIDTH){1'b0}},
                      shapool_result
                    };
                    // TODO actual winning nonce

                    /* verilator lint_on WIDTHCONCAT */
                  end
              STATE_DONE:
                state <= STATE_DONE;
              default:
                state <= STATE_IDLE;
            endcase
          end
      end

    // SPI0 process
    always @(posedge sck0)
      begin
        if (state == STATE_IDLE && !cs0_n)
          begin
            // Shift in data msb-first
            job_config <= { job_config[JOB_CONFIG_WIDTH-2 : 0], sdi0 };
          end
      end

    // SPI1 process
    always @(posedge sck1)
      begin
        if (!cs1_n)
          begin
            if (state == STATE_IDLE)
              begin
                // Shift config data msb-first
                device_config <= { device_config[DEVICE_CONFIG_WIDTH-2 : 0], sdi1 };
              end
            else if (state == STATE_DONE)
              begin
                // Shift result data msb-first
                result_data <= { result_data[RESULT_DATA_WIDTH-2 : 0], sdi1 };
              end
          end
      end

      assign sdo1 = (state == STATE_IDLE) ? device_config[DEVICE_CONFIG_WIDTH-1] :
                    (state == STATE_DONE) ? result_data[RESULT_DATA_WIDTH-1] :
                    1'b0;

endmodule