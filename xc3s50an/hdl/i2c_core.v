`timescale 1ns / 1ps

/*
Engineer:       sboldenko
Create Date:    21:39:38 03/14/2021 
Design Name:    digital_clock
Module Name:    i2c_core 
Project Name:   digital_wifi_clock
Target Devices: spartan-3 xc3s50an-4tqg144
Tool versions:  ise 14.7
*/

module i2c_core
(
    input  clk_sys,
    input  clk_i2c,
    input  clk_i2c_x2,
    input  reset,
    input  wr_address,
    input  rd_address,
    input  [7:0] byte_read,
    input  [6:0] data_address,
    input  in_valid,
    input  [7:0] in_data,
    output in_ready,
    output out_valid,
    output [7:0] out_data,
    output sda,
    inout  scl  
);

    reg  t_buffer_en = 1'b0;
    reg  t_buffer_in = 1'b1;
    wire t_buffer_out;
    
    reg  clk_i2c_reg;
    reg  clk_i2c_x2_reg;
    reg  clk_i2c_pulse = 1'b0;
    reg  clk_i2c_x2_pulse = 1'b0;
    reg  [6:0] address = 7'h00;
    reg  rw_status = 1'b0; 
    reg  [7:0] data = 8'h00;
    reg  ready = 1'b1;
    reg  scl_reg = 1'b1;

    reg  [3:0] counter_bit = 4'h0;
    reg  [7:0] counter_byte = 8'h00;
    
    parameter [4:0] S_RESET             = 1, 
                    S_IDLE              = 0,
                    S_WAIT_PULSE        = 2,
                    S_SEND_START        = 3,
                    S_SEND_ADDR_BIT6    = 4,
                    S_SEND_ADDR_BIT5    = 5,
                    S_SEND_ADDR_BIT4    = 6,
                    S_SEND_ADDR_BIT3    = 7,
                    S_SEND_ADDR_BIT2    = 8,
                    S_SEND_ADDR_BIT1    = 9,
                    S_SEND_ADDR_BIT0    = 10,
                    S_SEND_RW           = 11,
                    S_SEND_ADDR_ACK     = 12,
                    S_SEND_STOP         = 13,
                    S_READ              = 14,
                    S_READ_ACK          = 15,
                    S_READ_NACK         = 16;

    reg [4:0] state = 5'b0;
    
    always@(posedge clk_sys) begin
        clk_i2c_reg <= clk_i2c;
        clk_i2c_x2_reg <= clk_i2c_x2;
        
        if (clk_i2c == 1'b1 && clk_i2c_reg == 1'b0) begin
            clk_i2c_pulse <= 1'b1;
        end else begin 
            clk_i2c_pulse <= 1'b0;
        end
        
        if (clk_i2c_x2 == 1'b0 && clk_i2c_x2_reg == 1'b1) begin
            clk_i2c_x2_pulse <= 1'b1;
        end else begin 
            clk_i2c_x2_pulse <= 1'b0;
        end
    end
    
    always@(posedge clk_sys) begin
        if (wr_address || rd_address) begin
            address <= data_address;
        end
        
        if (wr_address) begin
            rw_status <= 1'b0;
        end else if (rd_address) begin  
            rw_status <= 1'b1;
        end
        
        if (in_valid == 1'b1) begin
            data <= in_data;
        end
    end
    
    always@(posedge clk_sys) begin
        if (reset) begin
            state <= S_RESET;
        end else begin
            case(state)
                S_RESET: begin
                    state <= S_IDLE;
                end
                S_IDLE: begin
                    ready <= 1'b1;
                    t_buffer_in <= 1'b1;

                    if (clk_i2c_x2_pulse)
                        t_buffer_en <= 1'b1;

                    if (rd_address)
                        state <= S_WAIT_PULSE;
                end 
                S_WAIT_PULSE: begin
                    ready <= 1'b0;

                    if (clk_i2c_pulse)
                        state <= S_SEND_START;
                end
                S_SEND_START: begin
                    t_buffer_en <= 1'b0;
                    t_buffer_in <= 1'b0;

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_ADDR_BIT6;
                end
                S_SEND_ADDR_BIT6: begin
                    t_buffer_in <= address[6];

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_ADDR_BIT5;
                end
                S_SEND_ADDR_BIT5: begin
                    t_buffer_in <= address[5];

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_ADDR_BIT4;
                end
                S_SEND_ADDR_BIT4: begin
                    t_buffer_in <= address[4];

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_ADDR_BIT3;
                end
                S_SEND_ADDR_BIT3: begin
                    t_buffer_in <= address[3];

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_ADDR_BIT2;
                end
                S_SEND_ADDR_BIT2: begin
                    t_buffer_in <= address[2];

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_ADDR_BIT1;
                end
                S_SEND_ADDR_BIT1: begin
                    t_buffer_in <= address[1];

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_ADDR_BIT0;
                end
                S_SEND_ADDR_BIT0: begin
                    t_buffer_in <= address[0];

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_RW;
                end
                S_SEND_RW: begin
                    t_buffer_in <= rw_status;

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_ADDR_ACK;
                end
                S_SEND_ADDR_ACK: begin
                    t_buffer_en <= 1'b1;

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)begin
                        //if (t_buffer_out == 1'b0)
                            state <= S_READ;
                        //else 
                            //state <= S_SEND_STOP;
                    end
                end
                S_SEND_STOP: begin
                    t_buffer_en <= 1'b0;
                    t_buffer_in <= 1'b0;

                    if (clk_i2c == 1'b1 && clk_i2c_x2_pulse == 1'b1)begin
                        state <= S_IDLE;
                    end
                end
                S_READ: begin
                    t_buffer_en <= 1'b1;

                    if (clk_i2c_reg == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        counter_bit <= counter_bit + 1'b1;

                    if (counter_bit == 4'h8 && counter_byte != byte_read - 1'b1) begin
                        counter_bit <= 4'h0;
                        state <= S_READ_ACK;
                        counter_byte <= counter_byte + 1'b1;
                    end else if (counter_bit == 4'h8 && counter_byte == byte_read - 1'b1) begin
                        counter_bit <= 4'h0;
                        state <= S_READ_NACK;
                        counter_byte <= 8'h00;
                    end
                end
                S_READ_ACK:begin
                    t_buffer_en <= 1'b0;
                    t_buffer_in <= 1'b0;

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_READ;
                end
                S_READ_NACK:begin
                    t_buffer_en <= 1'b0;
                    t_buffer_in <= 1'b1;

                    if (clk_i2c == 1'b0 && clk_i2c_x2_pulse == 1'b1)
                        state <= S_SEND_STOP;
                end
            endcase
        end
    end

    IOBUF 
    #(
        .DRIVE(12),               // Specify the output drive strength
        .IBUF_DELAY_VALUE("0"),   // Specify the amount of added input delay for the buffer, "0"-"16" (Spartan-3A only)
        .IFD_DELAY_VALUE("AUTO"), // Specify the amount of added delay for input register, "AUTO", "0"-"8" (Spartan-3A only)
        .IOSTANDARD("DEFAULT"),   // Specify the I/O standard
        .SLEW("SLOW")             // Specify the output slew rate
    ) 
    IOBUF_SDA_INST 
    (
        .O(t_buffer_out), // Buffer output
        .IO(sda),         // Buffer inout port (connect directly to top-level port)
        .I(t_buffer_in),  // Buffer input
        .T(t_buffer_en)   // 3-state enable input, high=input, low=output
    );
    
    always@(posedge clk_sys) begin
        if (reset) begin
            scl_reg <= 1'b1;
        end else if (state != S_IDLE && state != S_WAIT_PULSE) begin
            scl_reg <= clk_i2c_reg;
        end else begin
            scl_reg <= 1'b1;
        end
    end
    
    IOBUF 
    #(
        .DRIVE(12),               // Specify the output drive strength
        .IBUF_DELAY_VALUE("0"),   // Specify the amount of added input delay for the buffer, "0"-"16" (Spartan-3A only)
        .IFD_DELAY_VALUE("AUTO"), // Specify the amount of added delay for input register, "AUTO", "0"-"8" (Spartan-3A only)
        .IOSTANDARD("DEFAULT"),   // Specify the I/O standard
        .SLEW("SLOW")             // Specify the output slew rate
    ) 
    IOBUF_SCL_INST 
    (
        .O(buffer_out),   // Buffer output
        .IO(scl),         // Buffer inout port (connect directly to top-level port)
        .I(scl_reg),      // Buffer input
        .T(1'b1)          // 3-state enable input, high=input, low=output
    );

    assign in_ready = ready;

endmodule
