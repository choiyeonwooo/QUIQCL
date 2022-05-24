`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 20:28:05
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//  The FILE_TYPE of this file is set to SystemVerilog to utilize SystemVerilog features.
//  Generally to apply SystemVerilog syntax, the file extension should be ".sv" rather than ".v"
//  If you want to choose between verilog2001 and SystemVerilog without changing the file extension, 
//  right-click on the file name in "Design Sources", choose "Source Node Properties...", and 
//  change FILE_TYPE in Properties tab.
//////////////////////////////////////////////////////////////////////////////////
function integer bits_to_represent; //https://www.beyond-circuits.com/wordpress/2008/11/constant-functions/
    input integer value;
    begin
        for (bits_to_represent=0; value>0; bits_to_represent=bits_to_represent+1)
            value = value>>1;
    end
endfunction

module main(
    input Uart_RXD,
    output Uart_TXD,
    input CLK100MHZ,
    
    // Board1
    output ja_7, //powerdown1
    inout ja_6, //sdio1
    output ja_5, //csb1
    output ja_4, //reset
    output ja_3, // sclk
    output ja_2, // powerdown2
    inout ja_1, //sdio2
    output ja_0, // csb2
    
    // Board2
    output jb_7, //powerdown1
    inout jb_6, //sdio1
    output jb_5, //csb1
    output jb_4, //reset
    output jb_3, // sclk
    output jb_2, // powerdown2
    inout jb_1, //sdio2
    output jb_0, // csb2
    
    // Board3
    output jd_7, //powerdown1
    inout jd_6, //sdio1
    output jd_5, //csb1
    output jd_4, //reset
    output jd_3, // sclk
    output jd_2, // powerdown2
    inout jd_1, //sdio2
    output jd_0 // csb2
    );
    
    
    /////////////////////////////////////////////////////////////////
    // UART setting
    /////////////////////////////////////////////////////////////////
    parameter ClkFreq = 100000000;	// make sure this matches the clock frequency on your board
    parameter BaudRate = 57600;    // Baud rate

    /////////////////////////////////////////////////////////////////
    // Global setting
    /////////////////////////////////////////////////////////////////
    parameter BTF_MAX_BYTES = 9'h100;
    parameter BTF_MAX_BUFFER_WIDTH = 8 * BTF_MAX_BYTES;
    parameter BTF_MAX_BUFFER_COUNT_WIDTH = bits_to_represent(BTF_MAX_BYTES);


    /////////////////////////////////////////////////////////////////
    // To receive data from PC
    /////////////////////////////////////////////////////////////////
    parameter BTF_RX_BUFFER_BYTES = BTF_MAX_BYTES;
    parameter BTF_RX_BUFFER_WIDTH = BTF_MAX_BUFFER_WIDTH;
    parameter BTF_RX_BUFFER_COUNT_WIDTH = BTF_MAX_BUFFER_COUNT_WIDTH;
    parameter CMD_RX_BUFFER_BYTES = 4'hf;
    parameter CMD_RX_BUFFER_WIDTH = 8 * CMD_RX_BUFFER_BYTES;

    wire [BTF_RX_BUFFER_WIDTH:1] BTF_Buffer;
    wire [BTF_RX_BUFFER_COUNT_WIDTH-1:0] BTF_Length;
    
    wire [CMD_RX_BUFFER_WIDTH:1] CMD_Buffer;
    wire [3:0] CMD_Length;    
    wire CMD_Ready;
    
    wire esc_char_detected;
    wire [7:0] esc_char;

    wire wrong_format;
        
    
    data_receiver receiver(.RxD(Uart_RXD), .clk(CLK100MHZ), 
        .BTF_Buffer(BTF_Buffer), .BTF_Length(BTF_Length), 
        .CMD_Buffer(CMD_Buffer), .CMD_Length(CMD_Length), .CMD_Ready(CMD_Ready), 
        .esc_char_detected(esc_char_detected), .esc_char(esc_char),
         .wrong_format(wrong_format)
    );
    defparam receiver.BTF_RX_BUFFER_COUNT_WIDTH = BTF_RX_BUFFER_COUNT_WIDTH;
    defparam receiver.BTF_RX_BUFFER_BYTES = BTF_RX_BUFFER_BYTES; // can be between 1 and 2^BTF_RX_BUFFER_COUNT_WIDTH - 1
    defparam receiver.BTF_RX_BUFFER_WIDTH = BTF_RX_BUFFER_WIDTH;
    defparam receiver.ClkFreq = ClkFreq;
    defparam receiver.BaudRate = BaudRate;
    defparam receiver.CMD_RX_BUFFER_BYTES = CMD_RX_BUFFER_BYTES;
    defparam receiver.CMD_RX_BUFFER_WIDTH = CMD_RX_BUFFER_WIDTH;

    /////////////////////////////////////////////////////////////////
    // To send data to PC
    /////////////////////////////////////////////////////////////////

    parameter TX_BUFFER1_BYTES =  4'hf;
    parameter TX_BUFFER1_WIDTH = 8 * TX_BUFFER1_BYTES;
    parameter TX_BUFFER1_LENGTH_WIDTH = bits_to_represent(TX_BUFFER1_BYTES);

    parameter TX_BUFFER2_BYTES = BTF_MAX_BYTES;
    parameter TX_BUFFER2_WIDTH = BTF_MAX_BUFFER_WIDTH;
    parameter TX_BUFFER2_LENGTH_WIDTH = BTF_MAX_BUFFER_COUNT_WIDTH;


    reg [TX_BUFFER1_LENGTH_WIDTH-1:0] TX_buffer1_length;
    reg [1:TX_BUFFER1_WIDTH] TX_buffer1;
    reg TX_buffer1_ready;

    reg [TX_BUFFER2_LENGTH_WIDTH-1:0] TX_buffer2_length;
    reg [1:TX_BUFFER2_WIDTH] TX_buffer2;
    reg TX_buffer2_ready;

    
    wire TX_FIFO_ready;
    
    wire [1:32] monitoring_32bits;

    data_sender sender(
    .FSMState(),
    .clk(CLK100MHZ),
    .TxD(Uart_TXD),
    .esc_char_detected(esc_char_detected),
    .esc_char(esc_char),
    .wrong_format(wrong_format),
    .TX_buffer1_length(TX_buffer1_length),
    .TX_buffer1(TX_buffer1),
    .TX_buffer1_ready(TX_buffer1_ready),
    .TX_buffer2_length(TX_buffer2_length),
    .TX_buffer2(TX_buffer2),
    .TX_buffer2_ready(TX_buffer2_ready),
    .TX_FIFO_ready(TX_FIFO_ready),
    .bits_to_send(monitoring_32bits)
);

    defparam sender.ClkFreq = ClkFreq;
    defparam sender.BaudRate = BaudRate;
    defparam sender.TX_BUFFER1_LENGTH_WIDTH = TX_BUFFER1_LENGTH_WIDTH;
    defparam sender.TX_BUFFER1_BYTES =  TX_BUFFER1_BYTES;
    defparam sender.TX_BUFFER1_WIDTH = TX_BUFFER1_WIDTH;
    defparam sender.TX_BUFFER2_LENGTH_WIDTH = TX_BUFFER2_LENGTH_WIDTH;
    defparam sender.TX_BUFFER2_BYTES = TX_BUFFER2_BYTES;
    defparam sender.TX_BUFFER2_WIDTH = TX_BUFFER2_WIDTH;


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Command definitions
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





    /////////////////////////////////////////////////////////////////
    // Command definition for *IDN? command
    /////////////////////////////////////////////////////////////////
    parameter CMD_IDN = "*IDN?";
    parameter IDN_REPLY = "DDS_DAC v1_01"; // 13 characters
    
    /////////////////////////////////////////////////////////////////
    // Command definition for board selection
    /////////////////////////////////////////////////////////////////
    parameter CMD_Board1_Select = "Board1 Select";
    parameter CMD_Board2_Select = "Board2 Select";
    parameter CMD_Board3_Select = "Board3 Select";
    
    reg board1_select;
    reg board2_select;
    reg board3_select;
    
    initial begin
        board1_select <= 1'b0;
        board2_select <= 1'b0;
        board3_select <= 1'b0;
    end

    /////////////////////////////////////////////////////////////////
    // Command definition for DDS
    /////////////////////////////////////////////////////////////////
    parameter CMD_WRITE_DDS_REG = "WRITE DDS REG"; // 13 characters

    parameter DDS_MAX_LENGTH = 8;
    parameter DDS_WIDTH = DDS_MAX_LENGTH * 8;
    
    reg Board1_dds_data_ready_1, Board1_dds_data_ready_2;
    reg Board2_dds_data_ready_1, Board2_dds_data_ready_2;
    reg Board3_dds_data_ready_1, Board3_dds_data_ready_2;
    initial begin
        Board1_dds_data_ready_1 <= 1'b0;
        Board1_dds_data_ready_2 <= 1'b0;
        Board2_dds_data_ready_1 <= 1'b0;
        Board2_dds_data_ready_2 <= 1'b0;
        Board3_dds_data_ready_1 <= 1'b0;
        Board3_dds_data_ready_2 <= 1'b0;
    end

    reg [DDS_WIDTH+8:1] DDS_buffer; // Buffer to capture BTF_Buffer
    wire DDS1_update, DDS2_update;
    assign {DDS1_update, DDS2_update} = BTF_Buffer[DDS_WIDTH+6:DDS_WIDTH+5]; // This wire should probe BTF_Buffer directly because until BTF_Buffer will be captured, the data won't be correct
    
    wire [3:0] data_length;
    assign data_length = DDS_buffer[DDS_WIDTH+4:DDS_WIDTH+1];
    wire [DDS_WIDTH-1:0] DDS_data;
    assign DDS_data = DDS_buffer[DDS_WIDTH:1];
        
    reg [3:0] DDS_slow_clock;
    initial DDS_slow_clock <= 'd0;
    
    always @ (posedge CLK100MHZ) DDS_slow_clock <= DDS_slow_clock + 'd1;
    wire DDS_clock;
    assign DDS_clock = DDS_slow_clock[3];
        
    wire Board1_DDS_busy_1, Board1_DDS_busy_2;
    wire Board1_rcsbar_1, Board1_rcsbar_2;
    wire Board1_rsdio_1, Board1_rsdio_2;
    wire Board1_rsclk;
    assign Board1_rsclk = DDS_clock & (~Board1_rcsbar_1 | ~Board1_rcsbar_2);
    
    wire Board2_DDS_busy_1, Board2_DDS_busy_2;
    wire Board2_rcsbar_1, Board2_rcsbar_2;
    wire Board2_rsdio_1, Board2_rsdio_2;
    wire Board2_rsclk;
    assign Board2_rsclk = DDS_clock & (~Board2_rcsbar_1 | ~Board2_rcsbar_2);
    
    wire Board3_DDS_busy_1, Board3_DDS_busy_2;
    wire Board3_rcsbar_1, Board3_rcsbar_2;
    wire Board3_rsdio_1, Board3_rsdio_2;
    wire Board3_rsclk;
    assign Board3_rsclk = DDS_clock & (~Board3_rcsbar_1 | ~Board3_rcsbar_2);
    
    WriteToRegister WTR1(.DDS_clock(DDS_clock), .dataLength(data_length[3:0]), .registerData(DDS_data), .registerDataReady(Board1_dds_data_ready_1), .busy(Board1_DDS_busy_1),
                                .wr_rcsbar(Board1_rcsbar_1), /*.rsclk(rsclk00),*/ .rsdio(Board1_rsdio_1) ); //, .extendedDataReady(extendedDataReady00));   //, .countmonitor(monitor00), .registerDataReadymonitor(RDataReadymonitor00)
                                //);

    WriteToRegister WTR2(.DDS_clock(DDS_clock), .dataLength(data_length[3:0]), .registerData(DDS_data), .registerDataReady(Board1_dds_data_ready_2), .busy(Board1_DDS_busy_2),
                                .wr_rcsbar(Board1_rcsbar_2), /*.rsclk(rsclk00),*/ .rsdio(Board1_rsdio_2) ); //, .extendedDataReady(extendedDataReady00));   //, .countmonitor(monitor00), .registerDataReadymonitor(RDataReadymonitor00)
                                //);
                                
    WriteToRegister WTR3(.DDS_clock(DDS_clock), .dataLength(data_length[3:0]), .registerData(DDS_data), .registerDataReady(Board2_dds_data_ready_1), .busy(Board2_DDS_busy_1),
                                .wr_rcsbar(Board2_rcsbar_1), /*.rsclk(rsclk00),*/ .rsdio(Board2_rsdio_1) ); //, .extendedDataReady(extendedDataReady00));   //, .countmonitor(monitor00), .registerDataReadymonitor(RDataReadymonitor00)
                                //);

    WriteToRegister WTR4(.DDS_clock(DDS_clock), .dataLength(data_length[3:0]), .registerData(DDS_data), .registerDataReady(Board2_dds_data_ready_2), .busy(Board2_DDS_busy_2),
                                .wr_rcsbar(Board2_rcsbar_2), /*.rsclk(rsclk00),*/ .rsdio(Board2_rsdio_2) ); //, .extendedDataReady(extendedDataReady00));   //, .countmonitor(monitor00), .registerDataReadymonitor(RDataReadymonitor00)
                                //);
    
    WriteToRegister WTR5(.DDS_clock(DDS_clock), .dataLength(data_length[3:0]), .registerData(DDS_data), .registerDataReady(Board3_dds_data_ready_1), .busy(Board3_DDS_busy_1),
                                .wr_rcsbar(Board3_rcsbar_1), /*.rsclk(rsclk00),*/ .rsdio(Board3_rsdio_1) ); //, .extendedDataReady(extendedDataReady00));   //, .countmonitor(monitor00), .registerDataReadymonitor(RDataReadymonitor00)
                                //);
                                
    WriteToRegister WTR6(.DDS_clock(DDS_clock), .dataLength(data_length[3:0]), .registerData(DDS_data), .registerDataReady(Board3_dds_data_ready_2), .busy(Board3_DDS_busy_2),
                                .wr_rcsbar(Board3_rcsbar_2), /*.rsclk(rsclk00),*/ .rsdio(Board3_rsdio_2) ); //, .extendedDataReady(extendedDataReady00));   //, .countmonitor(monitor00), .registerDataReadymonitor(RDataReadymonitor00)
                                //);

    reg Board1_DDS1_powerdown, Board1_DDS2_powerdown, Board1_DDS_reset;
    reg Board2_DDS1_powerdown, Board2_DDS2_powerdown, Board2_DDS_reset;
    reg Board3_DDS1_powerdown, Board3_DDS2_powerdown, Board3_DDS_reset;

    initial {Board1_DDS1_powerdown, Board1_DDS2_powerdown, Board1_DDS_reset} <= 3'h0;
    initial {Board2_DDS1_powerdown, Board2_DDS2_powerdown, Board2_DDS_reset} <= 3'h0;
    initial {Board3_DDS1_powerdown, Board3_DDS2_powerdown, Board3_DDS_reset} <= 3'h0;

    assign {ja_7, ja_6, ja_5, ja_4, ja_3, ja_2, ja_1, ja_0}  = {Board1_DDS1_powerdown, Board1_rsdio_1, Board1_rcsbar_1, Board1_DDS_reset, Board1_rsclk, Board1_DDS2_powerdown, Board1_rsdio_2, Board1_rcsbar_2};
    assign {jb_7, jb_6, jb_5, jb_4, jb_3, jb_2, jb_1, jb_0}  = {Board2_DDS1_powerdown, Board2_rsdio_1, Board2_rcsbar_1, Board2_DDS_reset, Board2_rsclk, Board2_DDS2_powerdown, Board2_rsdio_2, Board2_rcsbar_2};
    assign {jd_7, jd_6, jd_5, jd_4, jd_3, jd_2, jd_1, jd_0}  = {Board3_DDS1_powerdown, Board3_rsdio_1, Board3_rcsbar_1, Board3_DDS_reset, Board3_rsclk, Board3_DDS2_powerdown, Board3_rsdio_2, Board3_rcsbar_2};


    /////////////////////////////////////////////////////////////////
    // Command definition for DNA_PORT command
    /////////////////////////////////////////////////////////////////
    parameter CMD_DNA_PORT = "DNA_PORT";
    wire [63:0] DNA_wire;
    device_DNA device_DNA_inst(
        .clk(CLK100MHZ),
        .DNA(DNA_wire) // If 4 MSBs == 4'h0, DNA_PORT reading is not finished. If 4 MSBs == 4'h1, DNA_PORT reading is done 
    );
 

    /////////////////////////////////////////////////////////////////
    // Command definition to investigate the contents in the BTF buffer
    /////////////////////////////////////////////////////////////////
    // Capturing the snapshot of BTF buffer
    parameter CMD_CAPTURE_BTF_BUFFER = "CAPTURE BTF"; // 11 characters
    reg [BTF_RX_BUFFER_WIDTH:1] BTF_capture;
    // Setting the number of bytes to read from the captured BTF buffer
    parameter CMD_SET_BTF_BUFFER_READING_COUNT = "BTF READ COUNT"; // 14 characters
    reg [BTF_RX_BUFFER_COUNT_WIDTH-1:0] BTF_read_count;
    // Read from the captured BTF buffer
    parameter CMD_READ_BTF_BUFFER = "READ BTF"; // 8 characters


    /////////////////////////////////////////////////////////////////
    // Command definition for bit patterns manipulation
    /////////////////////////////////////////////////////////////////
    // This command uses the first PATTERN_WIDTH bits as mask bits to update and update those bits with the following PATTERN_WIDTH bits
    parameter CMD_UPDATE_BIT_PATTERNS = "UPDATE BITS"; // 11 characters
    parameter PATTERN_BYTES = 4;
    parameter PATTERN_WIDTH = PATTERN_BYTES * 8; 
    reg [1:PATTERN_WIDTH] patterns;
    wire [1:PATTERN_WIDTH] pattern_masks;
    wire [1:PATTERN_WIDTH] pattern_data;
    
    assign pattern_masks = BTF_Buffer[2*PATTERN_WIDTH:PATTERN_WIDTH+1];
    assign pattern_data = BTF_Buffer[PATTERN_WIDTH:1];
    
    // This command reads the 32-bit patterns
    parameter CMD_READ_BIT_PATTERNS = "READ BITS"; // 9 characters




    /////////////////////////////////////////////////////////////////
    // Main FSM
    /////////////////////////////////////////////////////////////////
	reg [3:0] main_state;
    // State definition of FSM
    // Common state
    parameter MAIN_IDLE = 4'h0;
    parameter MAIN_DDS_WAIT_FOR_BUSY_ON = 4'h1;
    parameter MAIN_DDS_WAIT_FOR_BUSY_OFF = 4'h2;
    
    parameter MAIN_DAC_WAIT_FOR_BUSY_ON = 4'h3;
    parameter MAIN_DAC_WAIT_FOR_BUSY_OFF = 4'h4;
    parameter MAIN_DAC_LDAC_PAUSE = 4'h5;
    parameter MAIN_DAC_LDAC_OFF = 4'h6;


    parameter MAIN_UNKNOWN_CMD =4'hf;
    

    initial begin
        main_state <= MAIN_IDLE;
        patterns <= 'd0;
        TX_buffer1_ready <= 1'b0;
        TX_buffer2_ready <= 1'b0;
    end
    
    always @ (posedge CLK100MHZ)
        if (esc_char_detected == 1'b1) begin
            if (esc_char == "C") begin
                TX_buffer1_ready <= 1'b0;
                TX_buffer2_ready <= 1'b0;
                main_state <= MAIN_IDLE;
            end
        end
        else begin
            case (main_state)
                MAIN_IDLE:
                    if (CMD_Ready == 1'b1) begin

                        if ((CMD_Length == $bits(CMD_IDN)/8) && (CMD_Buffer[$bits(CMD_IDN):1] == CMD_IDN)) begin
                            TX_buffer1[1:$bits(IDN_REPLY)] <= IDN_REPLY;
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= $bits(IDN_REPLY)/8;
                            TX_buffer1_ready <= 1'b1;
                        end


                        else if ((CMD_Length == $bits(CMD_WRITE_DDS_REG)/8) && (CMD_Buffer[$bits(CMD_WRITE_DDS_REG):1] == CMD_WRITE_DDS_REG)) begin
                            if (BTF_Length != (DDS_MAX_LENGTH+1)) begin
                                TX_buffer1[1:13*8] <= {"Wrong length", BTF_Length[7:0]}; // Assuming that BTF_Length is less than 256
                                TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd13;
                                TX_buffer1_ready <= 1'b1;
                            end
                            else if ((DDS1_update != 0) || (DDS2_update != 0)) begin
                                DDS_buffer <=  BTF_Buffer[DDS_WIDTH+8:1]; // Buffer to capture BTF_Buffer
                                main_state <= MAIN_DDS_WAIT_FOR_BUSY_ON;
                                
                                if(board1_select) begin
                                    Board1_dds_data_ready_1 <= DDS1_update;
                                    Board1_dds_data_ready_2 <= DDS2_update;
                                end
                                
                                else if(board2_select) begin
                                    Board2_dds_data_ready_1 <= DDS1_update;
                                    Board2_dds_data_ready_2 <= DDS2_update;
                                end
                                
                                else if(board3_select) begin
                                    Board3_dds_data_ready_1 <= DDS1_update;
                                    Board3_dds_data_ready_2 <= DDS2_update;
                                end
                            end
                        end

                        else if ((CMD_Length == $bits(CMD_CAPTURE_BTF_BUFFER)/8) && (CMD_Buffer[$bits(CMD_CAPTURE_BTF_BUFFER):1] == CMD_CAPTURE_BTF_BUFFER)) begin
                            BTF_capture[BTF_RX_BUFFER_WIDTH:1] <= BTF_Buffer[BTF_RX_BUFFER_WIDTH:1];
                            main_state <= MAIN_IDLE;
                        end


                        else if ((CMD_Length == $bits(CMD_SET_BTF_BUFFER_READING_COUNT)/8) && (CMD_Buffer[$bits(CMD_SET_BTF_BUFFER_READING_COUNT):1] == CMD_SET_BTF_BUFFER_READING_COUNT)) begin
                            BTF_read_count[BTF_RX_BUFFER_COUNT_WIDTH-1:0] <= BTF_Buffer[BTF_RX_BUFFER_COUNT_WIDTH:1];
                            main_state <= MAIN_IDLE;
                        end

                        else if ((CMD_Length == $bits(CMD_READ_BTF_BUFFER)/8) && (CMD_Buffer[$bits(CMD_READ_BTF_BUFFER):1] == CMD_READ_BTF_BUFFER)) begin
                            TX_buffer2[1:TX_BUFFER2_WIDTH] <= BTF_capture[BTF_RX_BUFFER_WIDTH:1];
                            TX_buffer2_length[TX_BUFFER2_LENGTH_WIDTH-1:0] <= BTF_read_count[BTF_RX_BUFFER_COUNT_WIDTH-1:0];
                            TX_buffer2_ready <= 1'b1;
                            main_state <= MAIN_IDLE;
                        end

                        else if ((CMD_Length == $bits(CMD_UPDATE_BIT_PATTERNS)/8) && (CMD_Buffer[$bits(CMD_UPDATE_BIT_PATTERNS):1] == CMD_UPDATE_BIT_PATTERNS)) begin
                            patterns <= (patterns & ~pattern_masks) | (pattern_masks & pattern_data);
                        end

                        else if ((CMD_Length == $bits(CMD_READ_BIT_PATTERNS)/8) && (CMD_Buffer[$bits(CMD_READ_BIT_PATTERNS):1] == CMD_READ_BIT_PATTERNS)) begin
                            TX_buffer1[1:PATTERN_WIDTH] <= patterns;
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= PATTERN_WIDTH/8;
                            TX_buffer1_ready <= 1'b1;
                            main_state <= MAIN_IDLE;
                        end

                        else if ((CMD_Length == $bits(CMD_DNA_PORT)/8) && (CMD_Buffer[$bits(CMD_DNA_PORT):1] == CMD_DNA_PORT)) begin
                            TX_buffer1[1:64] <= DNA_wire;
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 8;
                            TX_buffer1_ready <= 1'b1;
                            main_state <= MAIN_IDLE;
                        end
                        
                        else if ((CMD_Length == $bits(CMD_Board1_Select)/8) && (CMD_Buffer[$bits(CMD_Board1_Select):1] == CMD_Board1_Select)) begin
                            board1_select <= 1'b1;
                            board2_select <= 1'b0;
                            board3_select <= 1'b0;
                            main_state <= MAIN_IDLE;
                        end    
                        
                        else if ((CMD_Length == $bits(CMD_Board2_Select)/8) && (CMD_Buffer[$bits(CMD_Board2_Select):1] == CMD_Board2_Select)) begin
                            board1_select <= 1'b0;
                            board2_select <= 1'b1;
                            board3_select <= 1'b0;
                            main_state <= MAIN_IDLE;
                        end    
                        
                        else if ((CMD_Length == $bits(CMD_Board3_Select)/8) && (CMD_Buffer[$bits(CMD_Board3_Select):1] == CMD_Board3_Select)) begin
                            board1_select <= 1'b0;
                            board2_select <= 1'b0;
                            board3_select <= 1'b1;
                            main_state <= MAIN_IDLE;
                        end    

                        else begin
                            main_state <= MAIN_UNKNOWN_CMD;
                        end
                    end
                    else begin
                        TX_buffer1_ready <= 1'b0;
                        TX_buffer2_ready <= 1'b0;
                    end
                    



                MAIN_DDS_WAIT_FOR_BUSY_ON: begin
                        if ((Board1_DDS_busy_1 | Board1_DDS_busy_2 | Board2_DDS_busy_1 | Board2_DDS_busy_2 | Board3_DDS_busy_1 |Board3_DDS_busy_2) == 1) begin
                            main_state <= MAIN_DDS_WAIT_FOR_BUSY_OFF;
                            Board1_dds_data_ready_1 <= 1'b0;
                            Board1_dds_data_ready_2 <= 1'b0;
                            
                            Board2_dds_data_ready_1 <= 1'b0;
                            Board2_dds_data_ready_2 <= 1'b0;
                            
                            Board3_dds_data_ready_1 <= 1'b0;
                            Board3_dds_data_ready_2 <= 1'b0;
                        end
                    end

                MAIN_DDS_WAIT_FOR_BUSY_OFF: begin
                        if ((Board1_DDS_busy_1 & Board1_DDS_busy_2 & Board2_DDS_busy_1 & Board2_DDS_busy_2 & Board3_DDS_busy_1 & Board3_DDS_busy_2) == 0) main_state <= MAIN_IDLE;
                    end

                MAIN_UNKNOWN_CMD:
                    begin
                        TX_buffer1[1:11*8] <= "Unknown CMD";
                        TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd11;
                        TX_buffer1_ready <= 1'b1;

                        //led1_b <= ~led1_b;
                        main_state <= MAIN_IDLE;
                    end
                    
                default:
                    main_state <= MAIN_IDLE;
            endcase
        end            
                    
    assign monitoring_32bits = patterns[1:32];
 
endmodule
