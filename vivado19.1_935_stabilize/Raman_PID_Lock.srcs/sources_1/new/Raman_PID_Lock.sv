`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Seoul National University
// Engineer: Modified by Jiyong Yu (Original work by SWYoo)
// 
// Create Date: 2020/10/06
// Design Name: Raman pulse laser PID locking system
// Module Name: main
// Project Name: 
// Target Devices: Arty S7 FPGA + DDS + ADC
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
    
    input ck_io_28,// ADC
    output ck_io_26, ck_io_27, ck_io_29, // ADC0

    // DDS
    output jb_7, //powerdown1
    inout jb_6, //sdio1
    output jb_5, //csb1
    output jb_4, //reset
    output jb_3, // sclk
    output jb_2, // powerdown2
    inout jb_1, //sdio2
    output jb_0, // csb2
    
    output [5:2] led,
    output led0_r,
    output led0_g,
    output led0_b,
    output led1_r,
    output led1_g,
    output led1_b,
    output d5, d4, d3, d2, d1, d0, // For debugging purpose   
    
    output reg ck_io_32 // debugging pin
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
    
    //parameter TX_BUFFER2_BYTES = BTF_MAX_BYTES;
    //parameter TX_BUFFER2_WIDTH = BTF_MAX_BUFFER_WIDTH;
    //parameter TX_BUFFER2_LENGTH_WIDTH = BTF_MAX_BUFFER_COUNT_WIDTH;
    parameter TX_BUFFER2_BYTES = 9'h12C;//////////300byte
    parameter TX_BUFFER2_WIDTH = 8*TX_BUFFER2_BYTES;
    parameter TX_BUFFER2_LENGTH_WIDTH = bits_to_represent(TX_BUFFER2_BYTES);

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
    
    /////////////////////////////////////////////////////////////////
    // Capture waveform data
    /////////////////////////////////////////////////////////////////
    // Settings related to capture waveform data
    reg waveform_capture_start_trigger;
/*
    wire [WAVEFORM_WIDTH-1:0] waveform_data;
    capture_waveform_data cwd(
        .CLK100MHZ(CLK100MHZ),
        .waveform(waveform_data),
        .armed(cwd_armed),
        .triggered(cwd_triggered),
        .arm_signal(waveform_capture_start_trigger),
        .trigger_mask(trigger_mask),
        .trigger_pattern(trigger_pattern),
        .points_to_capture_after_trigger(points_to_capture_after_trigger),
        .TX_FIFO_ready(TX_FIFO_ready),
        .TX_BUFFER(TX_waveform_buffer),
        .TX_waveform_buffer_ready(TX_waveform_buffer_ready),
        .esc_char_detected(esc_char_detected),
        .esc_char(esc_char)
    );
    defparam cwd.TX_WAVEFORM_BUFFER_BYTES =  TX_WAVEFORM_BUFFER_BYTES;
    defparam cwd.TX_WAVEFORM_BUFFER_WIDTH = TX_WAVEFORM_BUFFER_WIDTH;
    defparam cwd.WAVEFORM_WIDTH = WAVEFORM_WIDTH;
    defparam cwd.WAVEFORM_MAX_DEPTH = WAVEFORM_MAX_DEPTH;
    defparam cwd.WAVEFORM_COUNTER_WIDTH = WAVEFORM_COUNTER_WIDTH;
*/
    
    /////////////////////////////////////////////////////////////////
    // LED0 & LED1 intensity adjustment
    /////////////////////////////////////////////////////////////////

    reg [7:0] LED_intensity;
    wire red0, green0, blue0, red1, green1, blue1;
    initial begin
        LED_intensity <= 'd127;
    end
   
    led_intensity_adjust led_intensity_modulator(.led0_r(led0_r), .led0_g(led0_g), .led0_b(led0_b), .led1_r(led1_r),
        .led1_g(led1_g), .led1_b(led1_b), .red0(red0), .green0(green0), .blue0(blue0), .red1(red1), .green1(green1), .blue1(blue1),
        .intensity(LED_intensity), .CLK100MHZ(CLK100MHZ) );
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Command definitions
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////
    // Command definition for *IDN? command
    /////////////////////////////////////////////////////////////////
    parameter CMD_IDN = "*IDN?";
    parameter IDN_REPLY = "Raman PID v1.0"; // 13 characters
    parameter CMD_TEST = {8'h10, "TEST", 8'h10};

    /////////////////////////////////////////////////////////////////
    // DDS implementation
    /////////////////////////////////////////////////////////////////
    parameter CMD_DDS_START = "DDS START";
    parameter CMD_DDS_STOP = "DDS STOP";
    parameter CMD_DDS_WRITE = "WRITE DDS REG";
    
    parameter DDS_MAX_LENGTH = 8;
    parameter DDS_WIDTH = DDS_MAX_LENGTH * 8;
    
    reg dds_data_ready_1, dds_data_ready_2;
 
    initial begin
        dds_data_ready_1 <= 1'b0;
        dds_data_ready_2 <= 1'b0;
    end

    reg [DDS_WIDTH + 8:1] DDS_buffer; // Buffer to capture BTF_Buffer
    reg [DDS_WIDTH + 8:1] user_DDS_buffer; // user buffer
    reg [FTW_WIDTH:1] Current_FTW_tracking; // save current frquency tuning word for PID (tracking photo diode signal of pulse laser)
    reg [FTW_WIDTH:1] Current_FTW_AOM; // Real feedback to AOM
    parameter N = 6'd35; // Magnification factor for AOM feedback (105 / 3) 
    
    wire DDS1_update, DDS2_update;
    assign {DDS1_update, DDS2_update} = BTF_Buffer[DDS_WIDTH+6:DDS_WIDTH+5]; 
    
    wire [3:0] data_length;
    assign data_length = DDS_buffer[DDS_WIDTH + 4:DDS_WIDTH + 1];
    wire [DDS_WIDTH - 1:0] DDS_data;
    assign DDS_data = DDS_buffer[DDS_WIDTH:1];
        
    reg [3:0] DDS_slow_clock;
    initial DDS_slow_clock <= 'd0;
    
    always @ (posedge CLK100MHZ) DDS_slow_clock <= DDS_slow_clock + 'd1;
    wire DDS_clock;
    assign DDS_clock = DDS_slow_clock[3];
        
    wire DDS_busy_1, DDS_busy_2;
    wire rcsbar_1, rcsbar_2;
    wire rsdio_1, rsdio_2;
    wire rsclk;
    assign rsclk = DDS_clock & (~rcsbar_1 | ~rcsbar_2);
    
    WriteToRegister WTR1(.DDS_clock(DDS_clock), .dataLength(data_length[3:0]), .registerData(DDS_data), .registerDataReady(dds_data_ready_1), .busy(DDS_busy_1),
                                .wr_rcsbar(rcsbar_1), /*.rsclk(rsclk00),*/ .rsdio(rsdio_1) ); //, .extendedDataReady(extendedDataReady00));   //, .countmonitor(monitor00), .registerDataReadymonitor(RDataReadymonitor00)
                                //);

    WriteToRegister WTR2(.DDS_clock(DDS_clock), .dataLength(data_length[3:0]), .registerData(DDS_data), .registerDataReady(dds_data_ready_2), .busy(DDS_busy_2),
                                .wr_rcsbar(rcsbar_2), /*.rsclk(rsclk00),*/ .rsdio(rsdio_2) ); //, .extendedDataReady(extendedDataReady00));   //, .countmonitor(monitor00), .registerDataReadymonitor(RDataReadymonitor00)
                                //);
   

    reg DDS1_powerdown, DDS2_powerdown, DDS_reset;
   
    initial {DDS1_powerdown, DDS2_powerdown, DDS_reset} <= 3'h0;
  
    assign {jb_7, jb_6, jb_5, jb_4, jb_3, jb_2, jb_1, jb_0}  = {DDS1_powerdown, rsdio_1, rcsbar_1, DDS_reset, rsclk, DDS2_powerdown, rsdio_2, rcsbar_2};
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ADC implementation
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    parameter CMD_ADC_START = "ADC START";
    parameter CMD_ADC_STOP = "ADC STOP";    
    parameter CMD_ADC_RANGE = "ADC RANGE";
    parameter ADC_DATA_WIDTH = 16;             //16bit짜리 명령어
   
    reg [ADC_DATA_WIDTH:1] ADC_buffer; // adc 버퍼를 16비트 짜리 레지스터 할당
    reg [3:0] ADC_clk_cnt; // clock count,
    reg ADC_start;
    reg ADC_clock;//slow clock for adc
   
     
    wire [ADC_DATA_WIDTH:1] ADC_data; // ADC 모듈의 인풋값임. 총 16비트.
    wire [17:0] ADC_output;
    wire ADC_busy, ADC_sclk, ADC_cs_bar, ADC_sdi, ADC_sdo;
    
    assign ADC_data = ADC_buffer[ADC_DATA_WIDTH:1]; // 버퍼의 가장 오른쪽 24개의 레지스터 부분은 dac 데이터로 할당
       
    ADC8698 adc(.clock(ADC_clock),.start_trigger(ADC_start),.data(ADC_data),.sdo(ADC_sdo),
    .sclk(ADC_sclk),.cs_bar(ADC_cs_bar),.sdi(ADC_sdi),.busy(ADC_busy),.result(ADC_output));//function adc    
     
    assign {ck_io_29, ck_io_28, ck_io_27, ck_io_26 } = {ADC_sdi, ADC_sdo, ADC_cs_bar, ADC_sclk};   //fpga port에 보내는 핀 연결
       
       
    // Making 10MHz CLK for ADC
    initial begin
        ADC_clk_cnt <= 'd0;
        ADC_clock <= 'd0;
        ADC_start <=1'b0;
    end
   
    always @ (posedge CLK100MHZ) begin // clock 10MHz
        if(ADC_clk_cnt=='d5) begin
            ADC_clk_cnt<='d0;
            ADC_clock<= ~ADC_clock;
        end
        else
            ADC_clk_cnt<=ADC_clk_cnt+'d1; // sclk_ADC 에  clock 을 넣어주지 않고 이렇게 카운팅만 해주면서 1클락을 소비하니 그 클락은 0 인 것. 이런식으로 9개 클럭 꺼서 100MHz를 1/10 해줌
    end
    
     //////////////////////////////////////////
    /////// Buffer for FIFO   /////////////////        
    /////////////////////////////////////////
    parameter CMD_LOAD_LARGE = "LOAD LARGE";
    parameter FIFO_length_send = 100;
    parameter ADC_length_send = 24;
   
    reg [FIFO_length_send*ADC_length_send-1:0] FIFO_buffer;
    reg [5:0] test_large;
    reg [ADC_length_send*FIFO_length_send-1:0] load_large_data_buffer; // Read large ADC data (For fitting)
    reg [7:0] sample_cnt;
    reg [7:0] manual_sample;
    reg sample_clk;
   
    wire [7:0] sample_target;
    initial begin
        FIFO_buffer<='b0;
        test_large<=6'b0;
        sample_clk<=1'b0;
    end
   
    assign sample_target = manual_sample - sample_cnt;
   
    //////////////////////////////////////////////////
    //sampling data
    ///////////////////////////////////////////////////
    always @ (posedge CLK100MHZ) begin // clock 10MHz
        if(sample_target==0) begin
            sample_cnt<='d0;
            sample_clk<= ~sample_clk;
        end
        else
            sample_cnt <= sample_cnt+'d1;
    end
    
    ////////////////////////////////////////////
    /////// Frequency Boundary
    ///////////////////////////////////////////
    parameter CMD_ADJUST_SET_BOUND = "ADJUST BOUNDARY";
    parameter BOUND_DATA_WIDTH = 2 * FTW_WIDTH; // 96 bit (12 byte)
    
    reg [FTW_WIDTH - 1:0] loBound;
    reg [FTW_WIDTH - 1:0] upBound;
   
    initial begin
        loBound <= 48'hC49BA5E354; // 3MHz
        upBound <= 48'h6666665BF580; // 400MHz
    end
    
    
    //////////////////////////////////////
    ///// COMP controller implementation
    ///////////////////////////////////////
 
    parameter CMD_COMP_START="COMP START";
    parameter CMD_COMP_STOP="COMP STOP";
    parameter CMD_COMP_RESET_ACT="COMP RESET ACT";
    parameter CMD_COMP_RESET_DATA="COMP RESET DATA";
    parameter CMD_ADJUST_K0="COMPENSATOR K0";  // PID parameter setting
    parameter CMD_ADJUST_K1="COMPENSATOR K1";
    parameter CMD_ADJUST_K2="COMPENSATOR K2";
    parameter CMD_ADJUST_SET_POINT="COMP SETPOINT"; // Set point setting

    reg [23:0] K0;
    reg [23:0] K1;
    reg [23:0] K2;
    reg [17:0] setPoint; // ADC output bit uses 18bit
    reg COMP_start;
    reg COMP_reset_act;
    reg COMP_reset_data;
    reg COMP_busy;
    reg [17:0] sdo_buf; // Save buffer for ADC output
   
    reg [FTW_WIDTH:1] COMP_output; 
    // Buffers for PID control (Error value save)
    reg [17:0] difference;
    reg [17:0] difference_buf;
    reg [17:0] difference_buf_2;
    
    reg Err_sign; // Error sign

    // Implemeted but not used in Jiyong's version
    COMP_Control comp(.clock(ADC_clock),.start_trigger(COMP_start),.reset_act(COMP_reset_act),.reset_data(COMP_reset_data),.K0(K0),.K1(K1),.K2(K2),.setPoint(setPoint),.data_ADC(sdo_buf),.busy(COMP_busy),.COMP_output(COMP_output));    
   
    initial begin                          
        setPoint <= 18'b100000000000000000; // Nearly 0mV setpoint 
        K0 <= 24'h0;     
        K1 <= 24'h0;      
        K2 <= 24'h0;
        COMP_start <= 1'b0;
        COMP_reset_act <= 1'b0;
        COMP_reset_data <= 1'b0;    
        COMP_busy <= 1'b0;  
        difference <= 18'b0;
        difference_buf <= 18'b0;
        difference_buf_2 <= 18'b0;
        Err_sign <= 1'b0;
    end
           
     
    /////////////////////////////////////////////////////////////////
    // Command definition for LED0 & LED1 intensity adjustment
    /////////////////////////////////////////////////////////////////
    parameter CMD_ADJUST_INTENSITY = "ADJ INTENSITY"; // 13 characters
    parameter CMD_READ_INTENSITY = "READ INTENSITY"; // 14 characters
    
    
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
    // additional application(dds constant shoot, 60hz, digital filtering)
    /////////////////////////////////////////////////////////////////
    parameter CMD_CONST_SHOOT="CONST SHOOT";
    parameter CMD_USER_SAMPLING="USER SAMPLING";
    parameter CMD_TERMINATE_CONDITION="TERM COND";
    reg const_shoot;
    reg CLK_USER;
    reg CLK_USER_rising_flag;
    reg CLK_USER_rising_buffer;
    reg [16:0] CLK_USER_cnt;
    reg user_sampling;
    reg large_buffer_flag;
    
    initial begin
        const_shoot<=0;
        user_sampling<=0;
        CLK_USER_cnt<=0;
        large_buffer_flag<=0;
        CLK_USER_rising_flag<=0;
    end
       
    always @ (posedge CLK100MHZ) begin 
           if(CLK_USER_cnt=='d2500) begin // 20kHz user clock (used for ADC data sampling)
               CLK_USER_cnt<='d0;
               CLK_USER<= ~CLK_USER;
           end
           else
               CLK_USER_cnt <= CLK_USER_cnt+'d1; 
       end
       
    always @ (posedge CLK100MHZ) begin    
        CLK_USER_rising_buffer <= CLK_USER;
        if(!large_buffer_flag) begin
            if(CLK_USER > CLK_USER_rising_buffer) begin
                CLK_USER_rising_flag <= 1;
            end
        end
        else
           CLK_USER_rising_flag<=0;
    end
    
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
    parameter CMD_UPDATE = "UPDATE";
    parameter CMD_LOAD = "LOAD";
    reg DDS_on;
    
    // For various combinations of freq_AOM1 and freq_AOM2, AOM feedback direction may be upside down to tracking frequency feedback
    parameter CMD_NORMAL_FEEDBACK = "NORMAL";
    parameter CMD_REVERSE_FEEDBACK = "REVERSE";
    reg reverse_feedback; 
    
    // Beam geometry selection: Sinble Pass or Double Pass?
    parameter CMD_SINGLE_PASS = "SINGLE PASS";
    parameter CMD_DOUBLE_PASS = "DOUBLE PASS";
    reg is_single_pass;
    
    //////// Connection state between FPGA and HOST computer
    reg [2:0] con_state;
   
    parameter CON_WAIT = 3'h0;
    parameter CON_UPDATE = 3'h1;
    parameter CON_LOAD = 3'h2;
    parameter CON_UNKNOWN = 3'h3;
    parameter CON_LOAD_LARGE= 3'h4;
    
    reg update_request; // Send update sign to operation FSM  
    reg update_check;   // Checking whether the command needs updating parameters
    
    reg load_start, load_large_start;
    reg load_finish, load_large_finish;
   
    reg [48 + 48 + 18 - 1:0] load_data_buffer; // data_buffer : PD tracking FTW + AOM FTW + ADC data
        
    initial begin
        con_state <= CON_WAIT;
        update_request <= 1'b0;
        load_start <= 1'b0;
        load_finish <= 1'b0;
        load_large_start<= 1'b0;
        load_large_finish <= 1'b0;
        update_check <= 1'b0;
        TX_buffer1_ready <= 1'b0;
        TX_buffer2_ready <= 1'b0;
        
        load_data_buffer <= 0;
        load_large_data_buffer <= 0;
        user_DDS_buffer <= 0;
        reverse_feedback <= 1'b0;
        is_single_pass <= 1'b0;
    end
   
    always @ (posedge CLK100MHZ)              
        if (esc_char_detected == 1'b1) begin
            if (esc_char == "C") begin
                TX_buffer1_ready <= 1'b0;
                TX_buffer2_ready <= 1'b0;
                con_state <= CON_WAIT;
            end
        end
        
        else begin
            case (con_state)
                CON_WAIT:
                    if (CMD_Ready == 1'b1) begin
                        // COMMAND "*IDN?"
                        if ((CMD_Length == $bits(CMD_IDN)/8) && (CMD_Buffer[$bits(CMD_IDN):1] == CMD_IDN)) begin
                            TX_buffer1[1:$bits(IDN_REPLY)] <= IDN_REPLY;
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= $bits(IDN_REPLY)/8;
                            TX_buffer1_ready <= 1'b1;
                        end
                        
                        else if ((CMD_Length == $bits(CMD_DNA_PORT)/8) && (CMD_Buffer[$bits(CMD_DNA_PORT):1] == CMD_DNA_PORT)) begin
                            TX_buffer1[1:64] <= DNA_wire;
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 8;
                            TX_buffer1_ready <= 1'b1;
                        end
                        
                        // COMMAND "TEST"    
                        else if ((CMD_Length == $bits(CMD_TEST)/8) && (CMD_Buffer[$bits(CMD_TEST):1] == CMD_TEST)) begin
                            TX_buffer1[1:10*8] <= "Test rec'd";
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd10;
                            TX_buffer1_ready <= 1'b1;
                        end
                        
                        // COMMAND "ADJUST INTENSITY"
                        else if ((CMD_Length == $bits(CMD_ADJUST_INTENSITY)/8) && (CMD_Buffer[$bits(CMD_ADJUST_INTENSITY):1] == CMD_ADJUST_INTENSITY)) begin
                            LED_intensity[7:0] <= BTF_Buffer[8:1];
                        end
                              
                        // COMMAND "CAPTURE BTF"
                        else if ((CMD_Length == $bits(CMD_CAPTURE_BTF_BUFFER)/8) && (CMD_Buffer[$bits(CMD_CAPTURE_BTF_BUFFER):1] == CMD_CAPTURE_BTF_BUFFER)) begin
                            BTF_capture[BTF_RX_BUFFER_WIDTH:1] <= BTF_Buffer[BTF_RX_BUFFER_WIDTH:1];
                        end
                       
                        //  COMMAND "BTF READ COUNT"
                        else if ((CMD_Length == $bits(CMD_SET_BTF_BUFFER_READING_COUNT)/8) && (CMD_Buffer[$bits(CMD_SET_BTF_BUFFER_READING_COUNT):1] == CMD_SET_BTF_BUFFER_READING_COUNT)) begin
                            BTF_read_count[BTF_RX_BUFFER_COUNT_WIDTH-1:0] <= BTF_Buffer[BTF_RX_BUFFER_COUNT_WIDTH:1];
                        end
                        
                        
                        // COMMAND "UPDATE BITS"
                        else if ((CMD_Length == $bits(CMD_UPDATE_BIT_PATTERNS)/8) && (CMD_Buffer[$bits(CMD_UPDATE_BIT_PATTERNS):1] == CMD_UPDATE_BIT_PATTERNS)) begin
                            patterns <= (patterns & ~pattern_masks) | (pattern_masks & pattern_data);
                        end
                       
                        // COMMAND "READ BITS"
                        else if ((CMD_Length == $bits(CMD_READ_BIT_PATTERNS)/8) && (CMD_Buffer[$bits(CMD_READ_BIT_PATTERNS):1] == CMD_READ_BIT_PATTERNS)) begin
                            TX_buffer1[1:PATTERN_WIDTH] <= patterns;
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= PATTERN_WIDTH/8;
                            TX_buffer1_ready <= 1'b1;
                        end
                       
                        // COMMAND "UPDATE"
                        else if((CMD_Length == $bits(CMD_UPDATE)/8) && (CMD_Buffer[$bits(CMD_UPDATE):1] == CMD_UPDATE)) begin
                            con_state <= CON_UPDATE;
                        end
                        
                        // COMMAND "LOAD"
                        else if((CMD_Length == $bits(CMD_LOAD)/8) && (CMD_Buffer[$bits(CMD_LOAD):1] == CMD_LOAD)) begin
                            con_state <= CON_LOAD;
                            load_start <= 1'b1;
                        end    
                        
                        // COMMAND "LOAD LARGE"
                        else if((CMD_Length == $bits(CMD_LOAD_LARGE)/8) && (CMD_Buffer[$bits(CMD_LOAD_LARGE):1] == CMD_LOAD_LARGE)) begin
                            con_state <= CON_LOAD_LARGE;
                            load_large_start <= 1'b1;
                        end
                      
                        else begin
                            con_state <= CON_UNKNOWN;
                        end
                    end
                    
                    else begin
                        TX_buffer1_ready <= 1'b0;
                        TX_buffer2_ready <= 1'b0;
                    end                    

            CON_UPDATE: begin 
                if ((CMD_Length == $bits(CMD_UPDATE)/8) && (CMD_Buffer[$bits(CMD_UPDATE):1] == CMD_UPDATE)) begin //when command come intermidiate
                    con_state <= CON_UPDATE;
                end
                
                else if (update_request == 0) begin
                    update_request <= 1'b1;
                end
                
                else if(update_start == 1) begin
                    update_request <= 1'b0;
                    con_state <= CON_WAIT;
                    
                    // COMMAND "WRITE DDS REG"
                    if ((CMD_Length == $bits(CMD_DDS_WRITE)/8) && (CMD_Buffer[$bits(CMD_DDS_WRITE):1] == CMD_DDS_WRITE)) begin
                        if (BTF_Length != (DDS_MAX_LENGTH+1)) begin
                            TX_buffer1[1:13*8] <= {"Wrong length", BTF_Length[7:0]}; // Assuming that BTF_Length is less than 256
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd13;
                            TX_buffer1_ready <= 1'b1;
                        end
                        
                        else if((DDS1_update != 0) || (DDS2_update != 0)) begin
                            user_DDS_buffer[DDS_WIDTH+8:1] <= BTF_Buffer[DDS_WIDTH+8:1];
                        end
                    end    
                   
                    // COMMAND "DDS START"
                    else if ((CMD_Length == $bits(CMD_DDS_START)/8) && (CMD_Buffer[$bits(CMD_DDS_START):1] == CMD_DDS_START)) begin
                        DDS_on <= 1'b1;
                    end
    
                    // COMMAND "DDS STOP"
                    else if ((CMD_Length == $bits(CMD_DDS_STOP)/8) && (CMD_Buffer[$bits(CMD_DDS_STOP):1] == CMD_DDS_STOP)) begin
                        DDS_on <= 1'b0;
                    end
                    
                    // COMMAND "ADC START"
                    else if((CMD_Length == $bits(CMD_ADC_START)/8) && (CMD_Buffer[$bits(CMD_ADC_START):1] == CMD_ADC_START)) begin
                        if (BTF_Length != (ADC_DATA_WIDTH/8)) begin
                            TX_buffer1[1:13*8] <= {"Wrong length", BTF_Length[7:0]}; // Assuming that BTF_Length is less than 256
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd13;
                            TX_buffer1_ready <= 1'b1;
                        end
                        else begin
                            ADC_buffer[16:1] <= BTF_Buffer[ADC_DATA_WIDTH:1];
                            ADC_on <= 1'b1;
                            ADC_read_flag <= 1'b1;
                        end
                    end
                    
                    // COMMAND "ADC STOP"
                    else if((CMD_Length == $bits(CMD_ADC_STOP)/8) && (CMD_Buffer[$bits(CMD_ADC_STOP):1] == CMD_ADC_STOP)) begin
                        ADC_on <= 1'b0;
                        ADC_read_flag <= 1'b0;
                    end
                    
                    // COMMAND "ADC RANGE"              
                    else if((CMD_Length == $bits(CMD_ADC_RANGE)/8) && (CMD_Buffer[$bits(CMD_ADC_RANGE):1] == CMD_ADC_RANGE)) begin
                        if (BTF_Length != (ADC_DATA_WIDTH/8)) begin
                            TX_buffer1[1:13*8] <= {"Wrong length", BTF_Length[7:0]}; // Assuming that BTF_Length is less than 256
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd13;
                            TX_buffer1_ready <= 1'b1;
                        end    
                        else begin
                            ADC_buffer[16:1] <= BTF_Buffer[ADC_DATA_WIDTH:1];
                            ADC_on <= 1'b1;
                        end
                    end  
                    
                    // COMMAND "COMP START"
                    else if((CMD_Length == $bits(CMD_COMP_START)/8) && (CMD_Buffer[$bits(CMD_COMP_START):1] == CMD_COMP_START)) begin
                        COMP_on <= 1'b1;
                        COMP_reset_act <= 1'b0;
                        COMP_reset_data <= 1'b0;
                    end              

                    // COMMAND "COMP STOP"
                    else if((CMD_Length == $bits(CMD_COMP_STOP)/8) && (CMD_Buffer[$bits(CMD_COMP_STOP):1] == CMD_COMP_STOP)) begin
                        COMP_on <= 1'b0;
                    end
                    
                    // COMMAND "COMP RESET ACT"
                    else if((CMD_Length == $bits(CMD_COMP_RESET_ACT)/8) && (CMD_Buffer[$bits(CMD_COMP_RESET_ACT):1] == CMD_COMP_RESET_ACT)) begin
                        COMP_reset_act <= 1'b1;
                    end
                    
                    // COMMAND " COMP RESET DATA"
                    else if((CMD_Length == $bits(CMD_COMP_RESET_DATA)/8) && (CMD_Buffer[$bits(CMD_COMP_RESET_DATA):1] == CMD_COMP_RESET_DATA)) begin
                        COMP_reset_data <= 1'b1;
                    end
                   
                    // COMMAND "GAIN K0"
                    else if((CMD_Length == $bits(CMD_ADJUST_K0)/8) && (CMD_Buffer[$bits(CMD_ADJUST_K0):1] == CMD_ADJUST_K0)) begin//gain값 수정
                        K0[23:0] <= BTF_Buffer[24:1];
                    end
                   
                    // COMMAND "GAIN K1"
                    else if((CMD_Length == $bits(CMD_ADJUST_K1)/8) && (CMD_Buffer[$bits(CMD_ADJUST_K1):1] == CMD_ADJUST_K1)) begin
                        K1[23:0] <= BTF_Buffer[24:1];
                    end  
                    
                    // COMMAND "GAIN K2"
                    else if((CMD_Length == $bits(CMD_ADJUST_K2)/8) && (CMD_Buffer[$bits(CMD_ADJUST_K2):1] == CMD_ADJUST_K2)) begin
                        K2[23:0] <= BTF_Buffer[24:1];
                    end  
                                 
                    // COMMAND "SET POINT"
                    else if((CMD_Length == $bits(CMD_ADJUST_SET_POINT)/8) && (CMD_Buffer[$bits(CMD_ADJUST_SET_POINT):1] == CMD_ADJUST_SET_POINT)) begin
                        setPoint[17:0] <= BTF_Buffer[18:1];
                    end
                   
                    // COMMAND "SET BOUND"
                    else if((CMD_Length == $bits(CMD_ADJUST_SET_BOUND)/8) && (CMD_Buffer[$bits(CMD_ADJUST_SET_BOUND):1] == CMD_ADJUST_SET_BOUND)) begin
                        if (BTF_Length != (BOUND_DATA_WIDTH/8)) begin
                            TX_buffer1[1:13*8] <= {"Wrong length", BTF_Length[7:0]}; // Assuming that BTF_Length is less than 256
                            TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd13;
                            TX_buffer1_ready <= 1'b1;
                        end    
                        
                        else begin
                            upBound[FTW_WIDTH - 1:0] <= BTF_Buffer[16:1]; //boundary for DDS frequency
                            loBound[FTW_WIDTH - 1:0] <= BTF_Buffer[32:17];
                        end          
                    end
                    
                    else if((CMD_Length == $bits(CMD_CONST_SHOOT)/8) && (CMD_Buffer[$bits(CMD_CONST_SHOOT):1] == CMD_CONST_SHOOT)) begin
                        const_shoot <= 1'b1;
                    end 
                    
                    else if((CMD_Length == $bits(CMD_USER_SAMPLING)/8) && (CMD_Buffer[$bits(CMD_USER_SAMPLING):1] == CMD_USER_SAMPLING)) begin
                        user_sampling <= 1'b1;
                    end
                    
                    else if((CMD_Length == $bits(CMD_TERMINATE_CONDITION)/8) && (CMD_Buffer[$bits(CMD_TERMINATE_CONDITION):1] == CMD_TERMINATE_CONDITION)) begin
                        user_sampling <= 1'b0;
                        const_shoot <= 1'b0;
                    end
                    
                    else if((CMD_Length == $bits(CMD_NORMAL_FEEDBACK)/8) && (CMD_Buffer[$bits(CMD_NORMAL_FEEDBACK):1] == CMD_NORMAL_FEEDBACK)) begin
                        reverse_feedback <= 1'b0;
                    end
                    
                    else if((CMD_Length == $bits(CMD_REVERSE_FEEDBACK)/8) && (CMD_Buffer[$bits(CMD_REVERSE_FEEDBACK):1] == CMD_REVERSE_FEEDBACK)) begin
                        reverse_feedback <= 1'b1;
                    end
                    
                    else if((CMD_Length == $bits(CMD_SINGLE_PASS)/8) && (CMD_Buffer[$bits(CMD_SINGLE_PASS):1] == CMD_SINGLE_PASS)) begin
                        is_single_pass <= 1'b1;
                    end
                    
                    else if((CMD_Length == $bits(CMD_DOUBLE_PASS)/8) && (CMD_Buffer[$bits(CMD_DOUBLE_PASS):1] == CMD_DOUBLE_PASS)) begin
                        is_single_pass <= 1'b0;
                    end
                end
            end
            
            CON_LOAD: begin
                if(load_finish == 1) begin
                    load_start <= 1'b0;
                    con_state <= CON_WAIT;
                   
                    TX_buffer1[1:18] <= load_data_buffer[17:0]; // ADC data
                    TX_buffer1[19:24] <= 'b0; // zero padding
                    TX_buffer1[25:72] <= load_data_buffer[65:18]; // PD tracking FTW
                    TX_buffer1[73:120] <= load_data_buffer[113:66]; // AOM FTW
                    TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd15;
                    TX_buffer1_ready <= 1'b1;                    
                end
            end
           
            CON_LOAD_LARGE: begin////////////////need to locking with CON_LOAD by load_start
                if(load_large_finish == 1) begin
                    load_large_start <= 1'b0;
                    con_state <= CON_WAIT;
              
                    TX_buffer2[1:TX_BUFFER2_WIDTH] <= load_large_data_buffer[FIFO_length_send*ADC_length_send-1:0];
                    TX_buffer2_length[TX_BUFFER2_LENGTH_WIDTH-1:0] <= 'd300;
                    TX_buffer2_ready <= 1'b1;                    
                end
            end
            
            CON_UNKNOWN: begin
                TX_buffer1[1:11*8] <= "Unknown CMD";
                TX_buffer1_length[TX_BUFFER1_LENGTH_WIDTH-1:0] <= 'd11;
                TX_buffer1_ready <= 1'b1;                                  
                //led1_b <= ~led1_b;
                con_state <= CON_WAIT;
            end
            
            default:
                con_state <= CON_WAIT;
        endcase
    end

//////// Operation state of ADC/DDS system
    reg [3:0] op_state;
   
    parameter OP_WAIT = 4'h0;
    parameter OP_DDS = 4'h1;
    parameter OP_DDS_WAIT = 4'h2;
    parameter OP_ADC = 4'h3;
    parameter OP_ADC_WAIT = 4'h4;
    parameter OP_COMP = 4'h5;
    parameter OP_COMP_WAIT = 4'h6;
    
    // DDS updtae needed for compensation
    parameter OP_COMP_UPDATE_1 = 4'h7;
    parameter OP_COMP_UPDATE_WAIT_1 = 4'h8;
    
    // AOM feedback state
    parameter OP_AOM_Feedback = 4'h9;;
    parameter OP_AOM_Feedback_wait = 4'ha;
    parameter OP_COMP_UPDATE_2 = 4'hb;
    parameter OP_COMP_UPDATE_WAIT_2 = 4'hc;
    
    // FTW width
    parameter FTW_WIDTH = 6'd48; // Frequency tuning word for DDS uses 48 bit
    
    reg update_start;
    reg DDS_on;
    reg DDS_ready_flag;
    reg ADC_on;
    reg ADC_read_flag;
    reg COMP_on;
    
    initial begin
        op_state <= OP_WAIT;
        update_start <= 1'b0;
        DDS_on <= 1'b0;
        DDS_ready_flag <= 1'b0;
        ADC_on <= 1'b0;
        ADC_read_flag <= 1'b0;
        COMP_on <= 1'b0;
        ck_io_32 <= 1'b0;
    end

always @ (posedge CLK100MHZ)        
        case (op_state)
            OP_WAIT: begin
                if(update_request == 1) begin
                    update_start <= 1'b1;
                end
                
                else if(load_start == 1) begin
                    load_data_buffer[17:0] <= sdo_buf[17:0]; // ADC data
                    load_data_buffer[65:18] <= Current_FTW_tracking[FTW_WIDTH : 1]; // PD tracking FTW
                    load_data_buffer[113:66] <= Current_FTW_AOM[FTW_WIDTH : 1]; // AOM FTW
                    load_finish <= 1'b1;
                end

                else if(load_large_start == 1)begin //sent large data to PC
                    load_large_data_buffer[ADC_length_send*FIFO_length_send-1:0] <= FIFO_buffer[ADC_length_send*FIFO_length_send-1:0];
                    load_large_finish <= 1'b1;
                end
                
                else begin
                    update_start <= 1'b0;
                    load_finish <= 1'b0;
                    load_large_finish <= 1'b0;
                    
                    if (ADC_on == 1) begin
                        op_state <= OP_ADC;
                    end
                   
                    else if (COMP_on == 1) begin
                        //op_state <= OP_COMP;
                        op_state <= OP_DDS;
                    end
                    
                    else if(DDS_on == 1) begin
                        op_state <= OP_DDS;
                    end
                end
            end
            
            // Maybe..ADC state would not be used for Raman laser PID locking
            OP_ADC: begin
                if(ADC_start == 0) begin//ADC_start consume 1clock, I think
                    ADC_start <= 1'b1;
                end
                else if (ADC_busy == 1) begin
                    op_state <= OP_ADC_WAIT;
                end
            end
           
            OP_ADC_WAIT: begin
                if (ADC_busy == 1) begin
                    ADC_start <= 1'b0;
                end
                
                else begin                    
                    if(ADC_read_flag == 1) begin
                        sdo_buf[17:0] <= ADC_output[17:0]; //we store the ADC data to buf
                        
                        if(user_sampling==1) begin // user defined sampling (slow sampling)
                            if(CLK_USER_rising_flag) begin
                                FIFO_buffer[ADC_length_send-1:0] <= {ADC_output[17:0],6'b0};
                                FIFO_buffer[ADC_length_send*FIFO_length_send-1:ADC_length_send] <= FIFO_buffer[ADC_length_send*FIFO_length_send-ADC_length_send-1:0];//////
                                large_buffer_flag<=1;
                            end
                            else large_buffer_flag<=0;
                        end
                        
                        else begin
                            FIFO_buffer[ADC_length_send-1:0] <= {ADC_output[17:0],6'b0};
                            FIFO_buffer[ADC_length_send*FIFO_length_send-1:ADC_length_send] <= FIFO_buffer[ADC_length_send*FIFO_length_send-ADC_length_send-1:0];
                            large_buffer_flag<=0;
                        end
                    end
                    
                    else begin
                        sdo_buf[17:0] <= 18'd0;
                    end    
                    
                    if (COMP_on == 1) begin                   //go to next state
                        op_state <= OP_COMP;
                    end
                    
                    else if (DDS_on == 1) begin
                        op_state <= OP_DDS;
                    end
                    
                    else begin
                        op_state <= OP_WAIT;
                    end    
                end
            end
            
            OP_COMP: begin
                // difference value save
                if(sdo_buf > setPoint) difference <= (sdo_buf - setPoint);
                else difference <= (setPoint - sdo_buf);
                difference_buf <= difference;
                difference_buf_2 <= difference_buf;
                
                if(COMP_start == 0) begin
                    COMP_start <= 1'b1;
                end
                
                else begin
                    op_state <= OP_COMP_WAIT;
                end
            end
           
            OP_COMP_WAIT: begin
                if(COMP_busy == 1) begin
                    COMP_start <= 1'b0;
                end    
                    
                else begin          
                    if (DDS_on == 1) begin
                        op_state <= OP_DDS;
                    end
                    
                    else begin
                        op_state <= OP_WAIT;
                    end
                end
            end
            
            OP_DDS: begin
                if(DDS_ready_flag == 0) begin
                    DDS_ready_flag <= 1'b1;
                    
                    if (COMP_on == 1) begin
                        if(!const_shoot) begin               
                            // PID control for DDS port1 (tracking Photo diode signal of pulse laser)
                            if(sdo_buf > setPoint) begin
                                Err_sign <= 1'b0;
                                DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_tracking[FTW_WIDTH : 1] + (K0 * difference) - (K1 * difference_buf) + (K2 * difference_buf_2);
                            end
                            
                            else begin
                                Err_sign <= 1'b1;
                                DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_tracking[FTW_WIDTH : 1] - (K0 * difference) + (K1 * difference_buf) - (K2 * difference_buf_2);
                            end
                            
                            DDS_buffer[DDS_WIDTH : FTW_WIDTH + 1] <= 16'h61AB;
                            DDS_buffer[DDS_WIDTH + 4 : DDS_WIDTH + 1] <= 4'b1000;
                        end
                        
                        else begin
                            DDS_buffer[DDS_WIDTH + 8:1] <= user_DDS_buffer[DDS_WIDTH + 8:1];
                        end   
                    end
                    
                    else begin
                        DDS_buffer[DDS_WIDTH + 8:1] <= user_DDS_buffer[DDS_WIDTH + 8:1];
                    end
                end
                
                else if((DDS_busy_1 == 0) && (DDS_busy_2 == 0)) begin
                    if(COMP_on) begin // compesation case
                        // update tracking frequency first
                        dds_data_ready_1 <= 1'b1;
                        dds_data_ready_2 <= 1'b0;
                        
                        // save current FTW(DDS buffer 8byte!) word for photodiode tracking frequency
                        Current_FTW_tracking <= DDS_buffer[FTW_WIDTH:1];
                    end
                    
                    else begin // normal dds write case
                        if((DDS_buffer[DDS_WIDTH + 4 : DDS_WIDTH + 1] == 4'b1000) && (DDS_buffer[DDS_WIDTH + 6] == 1'b1)) Current_FTW_tracking <= DDS_buffer[FTW_WIDTH:1]; // save current FTW(DDS buffer 8byte!) word for photodiode tracking frequency
                        if((DDS_buffer[DDS_WIDTH + 4 : DDS_WIDTH + 1] == 4'b1000) && (DDS_buffer[DDS_WIDTH + 5] == 1'b1)) Current_FTW_AOM <= DDS_buffer[FTW_WIDTH:1]; // save current FTW(DDS buffer 8byte!) word for AOM frequency

                        dds_data_ready_1 <= DDS1_update;
                        dds_data_ready_2 <= DDS2_update;
                    end
                end
            
                else begin
                    DDS_ready_flag <= 1'b0;
                    op_state <= OP_DDS_WAIT;
                end
            end
    
            OP_DDS_WAIT: begin
                if((DDS_busy_1 | DDS_busy_2) == 1) begin
                    dds_data_ready_1 <= 1'b0;
                    dds_data_ready_2 <= 1'b0;
                end
            
                else begin
                    if(COMP_on == 1) op_state <= OP_COMP_UPDATE_1; // Mirroed register update needed for final update
                    else op_state <= OP_WAIT;
                end
            end  
            
            OP_COMP_UPDATE_1: begin
                if(DDS_ready_flag == 0) begin
                    DDS_ready_flag <= 1'b1;
                    DDS_buffer[DDS_WIDTH:1] <= 64'h0005010000000000; // update mirroed register
                    DDS_buffer[DDS_WIDTH + 4 :DDS_WIDTH + 1] <= 4'b0011; // 3byte
                end
                
                else if((DDS_busy_1 == 0) && (DDS_busy_2 == 0)) begin
                    dds_data_ready_1 <= 1'b1;
                    dds_data_ready_2 <= 1'b0;
                end
                
                else begin
                    DDS_ready_flag <= 1'b0;
                    op_state <= OP_COMP_UPDATE_WAIT_1;
                end
            end
            
            OP_COMP_UPDATE_WAIT_1: begin
                if((DDS_busy_1 | DDS_busy_2) == 1) begin
                    dds_data_ready_1 <= 1'b0;
                    dds_data_ready_2 <= 1'b0;
                end
            
                else begin
                    op_state <= OP_AOM_Feedback;
                end
            end
            
            // real feedback to AOM (N = 35)
            OP_AOM_Feedback: begin
                if(DDS_ready_flag == 0) begin
                    DDS_ready_flag <= 1'b1;
                    
                    // Single pass AOM
                    // Determination of feedback direction needed (normal or reverse?)
                    if(is_single_pass == 1'b1) begin
                        if(Err_sign == 1'b0) begin
                            if(!reverse_feedback) DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_AOM[FTW_WIDTH : 1] + (N * K0 * difference) - (N * K1 * difference_buf) + (N * K2 * difference_buf_2);
                            else DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_AOM[FTW_WIDTH : 1] - (N * K0 * difference) + (N * K1 * difference_buf) - (N * K2 * difference_buf_2);
                        end
                        
                        else begin
                            if(!reverse_feedback) DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_AOM[FTW_WIDTH : 1] - (N * K0 * difference) + (N * K1 * difference_buf) - (N * K2 * difference_buf_2);
                            else DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_AOM[FTW_WIDTH : 1] + (N * K0 * difference) - (N * K1 * difference_buf) + (N * K2 * difference_buf_2);
                        end
                    end
                    
                    // Divide by 2 for double pass AOM (use bit shift operator!!)
                    // Determination of feedback direction needed (normal or reverse?)
                    else begin
                        if(Err_sign == 1'b0) begin
                            if(!reverse_feedback) DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_AOM[FTW_WIDTH : 1] + ((N * K0 * difference)>>1) - ((N * K1 * difference_buf)>>1) + ((N * K2 * difference_buf_2)>>1);
                            else DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_AOM[FTW_WIDTH : 1] - ((N * K0 * difference)>>1) + ((N * K1 * difference_buf)>>1) - ((N * K2 * difference_buf_2)>>1);
                        end
                        
                        else begin
                            if(!reverse_feedback) DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_AOM[FTW_WIDTH : 1] - ((N * K0 * difference)>>1) + ((N * K1 * difference_buf)>>1) - ((N * K2 * difference_buf_2)>>1);
                            else DDS_buffer[FTW_WIDTH : 1] <= Current_FTW_AOM[FTW_WIDTH : 1] + ((N * K0 * difference)>>1) - ((N * K1 * difference_buf)>>1) + ((N * K2 * difference_buf_2)>>1);
                        end
                    end
                    
                    DDS_buffer[DDS_WIDTH : FTW_WIDTH + 1] <= 16'h61AB;
                    DDS_buffer[DDS_WIDTH + 4 : DDS_WIDTH + 1] <= 4'b1000;
                end
                
                else if((DDS_busy_1 == 0) && (DDS_busy_2 == 0)) begin
                    // save current aom frequency 
                    Current_FTW_AOM <= DDS_buffer[FTW_WIDTH : 1]; 
                    
                    // update AOM frequency
                    dds_data_ready_1 <= 1'b0;
                    dds_data_ready_2 <= 1'b1;
                end
                
                else begin
                    DDS_ready_flag <= 1'b0;
                    op_state <= OP_AOM_Feedback_wait;
                end
            end
            
            OP_AOM_Feedback_wait: begin            
                if((DDS_busy_1 | DDS_busy_2) == 1) begin
                    dds_data_ready_1 <= 1'b0;
                    dds_data_ready_2 <= 1'b0;
                end
            
                else begin
                    op_state <= OP_COMP_UPDATE_2;
                end
            end
            
            OP_COMP_UPDATE_2: begin
                if(DDS_ready_flag == 0) begin
                    DDS_ready_flag <= 1'b1;
                    DDS_buffer[DDS_WIDTH:1] <= 64'h0005010000000000; // update mirroed register
                    DDS_buffer[DDS_WIDTH + 4 :DDS_WIDTH + 1] <= 4'b0011; // 3byte
                end
                
                else if((DDS_busy_1 == 0) && (DDS_busy_2 == 0)) begin
                    dds_data_ready_1 <= 1'b0;
                    dds_data_ready_2 <= 1'b1;
                    ck_io_32 <= 1'b1;
                end
                
                else begin
                    DDS_ready_flag <= 1'b0;
                    op_state <= OP_COMP_UPDATE_WAIT_2;
                end
            end
            
            OP_COMP_UPDATE_WAIT_2: begin
                if((DDS_busy_1 | DDS_busy_2) == 1) begin
                    dds_data_ready_1 <= 1'b0;
                    dds_data_ready_2 <= 1'b0;
                end
            
                else begin
                    op_state <= OP_WAIT;
                end
            end    
        endcase 
        
        reg wait_flag;
        initial wait_flag <= 1'b0;
        always @ (posedge CLK100MHZ) begin
            if(op_state == 0) wait_flag <= 1'b1;
            else wait_flag <= 1'b0;
        end
    
        assign {d0, d1, d2, d3, d4, d5} = 6'h00;
        //assign {led, red1, green1, blue1, red0, green0, blue0} = patterns[1:10];
        assign {red1,green1,blue1} = op_state;
        assign {red0,green0,blue0} = con_state;
       
        assign led[2] = ADC_on;
        assign led[3] = COMP_on;
        assign led[4] = DDS_on;
        assign led[5] = wait_flag;
        
endmodule
