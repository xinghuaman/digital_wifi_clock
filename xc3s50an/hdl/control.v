`timescale 1ns / 1ps

/*
Engineer:       sboldenko
Create Date:    18:59:58 03/28/2021 
Design Name:    digital_clock
Module Name:    control 
Project Name:   digital_wifi_clock
Target Devices: spartan-3 xc3s50an-4tqg144
Tool versions:  ise 14.7
*/

module control
(
    input  clk,
    input  reset,

    input  packet,
    input  control_valid,
    input  [7:0] control_data,
    output control_ready,
    output control_answer_valid,
    output [7:0] control_answer_data,
    input  control_answer_ready,

    output control_i2c_wr_addr,
    output control_i2c_rd_addr,
    output [7:0] control_i2c_byte_read,
    output [6:0] control_i2c_addr,
    output control_i2c_in_valid,
    output [7:0] control_i2c_in_data,
    input  control_i2c_in_ready,
    input  control_i2c_out_valid,
    input  [7:0] control_i2c_out_data
);
    reg ready_reg = 1'b0;
    reg control_valid_z = 1'b0;
    reg [7:0] hr = 8'h00;
    reg [7:0] min = 8'h00;
    reg [7:0] sec = 8'h00;
    reg control_answer_valid_reg = 1'b0;
    reg [7:0] control_answer_data_reg = 8'h00;

    parameter [3:0] S_UART_IDLE          = 0,
                    S_UART_RESET         = 1,
                    S_UART_CHECK_START   = 2,
                    S_UART_CLEAR         = 3,
                    S_UART_DATA_HR       = 4,
                    S_UART_DATA_MIN      = 5,
                    S_UART_DATA_SEC      = 6,
                    S_UART_ANSWER_OK     = 7,
                    S_UART_ANSWER_REPEAT = 8;
                            
    reg [3:0] state_time_update = 4'd0;

    parameter [6:0] CONST_ADDR_DS1307 = 7'b1101000;
    parameter [7:0] CONST_BYTE_READ = 8'h03;

    reg new_data = 1'b0;

    reg control_i2c_wr_addr_reg = 1'b0;
    reg control_i2c_rd_addr_reg = 1'b0;
    reg [6:0] control_i2c_addr_reg = 7'b0000000;
    reg control_i2c_in_valid_reg = 1'b0;
    reg [7:0] control_i2c_in_data_reg = 8'h00;

    parameter [3:0] S_I2C_IDLE    = 0,
                    S_I2C_RESET   = 1,
                    S_I2C_WR_ADDR = 2,
                    S_I2C_WR_SEC  = 3,
                    S_I2C_WR_MIN  = 4,
                    S_I2C_WR_HR   = 5,
                    S_I2C_SEND_1  = 6,
                    S_I2C_SEND_2  = 7,
                    S_I2C_RD_ADDR = 8;

    reg [3:0] state_i2c = 4'd0;

    reg [16:0] counter = 17'h00000;

    always@(posedge clk) begin
        if (reset)
            state_time_update <= S_UART_RESET;
        else begin    
            case(state_time_update)
                S_UART_RESET: begin
                    state_time_update <= S_UART_IDLE;
                end
                S_UART_IDLE: begin
                    ready_reg <= 1'b0;
                    control_answer_valid_reg <= 1'b0;
                    control_answer_data_reg <= 8'h00;

                    if (packet) begin
                        ready_reg <= 1'b1;
                        state_time_update <= S_UART_CHECK_START;
                    end    
                end
                S_UART_CHECK_START: begin
                    ready_reg <= 1'b0; 

                    if (control_valid) begin
                        ready_reg <= 1'b1;

                        if (control_data == 8'hAA)
                            state_time_update <= S_UART_DATA_HR;
                        else 
                            state_time_update <= S_UART_CLEAR;  
                    end          
                end
                S_UART_DATA_HR: begin
                    if (control_valid) begin
                        hr <= control_data;
                        state_time_update <= S_UART_DATA_MIN;
                    end    
                end
                S_UART_DATA_MIN: begin
                    min <= control_data;
                    state_time_update <= S_UART_DATA_SEC;
                end
                S_UART_DATA_SEC: begin
                    sec <= control_data;
                    state_time_update <= S_UART_ANSWER_OK;
                end
                S_UART_CLEAR: begin
                    control_valid_z <= control_valid;

                    if (control_valid_z == 1'b1 && control_valid == 1'b0)
                        state_time_update <= S_UART_ANSWER_REPEAT;
                end
                S_UART_ANSWER_OK: begin
                    if (control_answer_ready) begin
                        control_answer_valid_reg <= 1'b1;
                        control_answer_data_reg <= 8'hAA;
                        state_time_update <= S_UART_IDLE;
                    end
                end                
                S_UART_ANSWER_REPEAT: begin
                    if (control_answer_ready) begin
                        control_answer_valid_reg <= 1'b1;
                        control_answer_data_reg <= 8'hBB;
                        state_time_update <= S_UART_IDLE;
                    end
                end
            endcase
        end    
    end

    always@(posedge clk) begin
        if (reset)
            new_data <= 1'b0; 
        else if (state_time_update == S_UART_ANSWER_OK)
            new_data <= 1'b1;
        else if (state_i2c == S_I2C_WR_ADDR) 
            new_data <= 1'b0;
    end

    always@(posedge clk) begin
        if (reset)
            state_i2c <= S_I2C_RESET;
        else begin    
            case(state_i2c)
                S_I2C_RESET: begin
                    state_i2c <= S_I2C_IDLE;
                end
                S_I2C_IDLE: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;
                    control_i2c_rd_addr_reg <= 1'b0;
                    control_i2c_addr_reg <= 7'b0000000;

                    if (new_data)
                        state_i2c <= S_I2C_WR_ADDR;

                    if (counter == 17'h1FFFF)
                        state_i2c <= S_I2C_RD_ADDR;
                end
                S_I2C_WR_ADDR: begin
                    if (control_i2c_in_ready) begin
                        control_i2c_wr_addr_reg <= 1'b1;
                        control_i2c_addr_reg <= CONST_ADDR_DS1307;
                        state_i2c <= S_I2C_WR_SEC;
                    end
                end
                S_I2C_RD_ADDR: begin
                    if (control_i2c_in_ready) begin
                        control_i2c_rd_addr_reg <= 1'b1;
                        control_i2c_addr_reg <= CONST_ADDR_DS1307;
                        state_i2c <= S_I2C_IDLE;
                    end
                end
                S_I2C_WR_SEC: begin
                    control_i2c_wr_addr_reg <= 1'b0;
                    control_i2c_addr_reg <= 7'b0000000;

                    if (control_i2c_in_ready) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= sec;
                        state_i2c <= S_I2C_SEND_1;
                    end
                end
                S_I2C_SEND_1: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_WR_MIN;
                end
                S_I2C_WR_MIN: begin
                    if (control_i2c_in_ready) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= min;
                        state_i2c <= S_I2C_SEND_2;
                    end                    
                end
                S_I2C_SEND_2: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_WR_HR;
                end
                S_I2C_WR_HR: begin
                    if (control_i2c_in_ready) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= hr;
                        state_i2c <= S_I2C_IDLE;
                    end                    
                end
            endcase
        end    
    end

    always@(posedge clk) begin
        counter <= counter + 1'b1;
    end

    assign control_i2c_byte_read = CONST_BYTE_READ;
    assign control_ready = ready_reg;
    assign control_answer_valid = control_answer_valid_reg;
    assign control_answer_data = control_answer_data_reg;
    assign control_i2c_wr_addr = control_i2c_wr_addr_reg;
    assign control_i2c_rd_addr = control_i2c_rd_addr_reg;
    assign control_i2c_addr = control_i2c_addr_reg;
    assign control_i2c_in_valid = control_i2c_in_valid_reg;
    assign control_i2c_in_data = control_i2c_in_data_reg;

endmodule
