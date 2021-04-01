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
    input  [7:0] control_i2c_out_data,

    output control_display_valid,
    output [7:0] control_display_data,
    input  control_display_ready
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
    reg [ 6:0] control_i2c_addr_reg = 7'b0000000;
    reg control_i2c_in_valid_reg = 1'b0;
    reg [ 7:0] control_i2c_in_data_reg = 8'h00;
    reg [16:0] counter = 17'h00000;
    reg [ 6:0] blink_delay = 7'h00;
    reg blink = 1'b0;

    parameter [3:0] S_I2C_IDLE    = 0,
                    S_I2C_RESET   = 1,
                    S_I2C_WR_ADDR = 2,
                    S_I2C_WR_SEC  = 3,
                    S_I2C_WR_MIN  = 4,
                    S_I2C_WR_HR   = 5,
                    S_I2C_SEND_1  = 6,
                    S_I2C_SEND_2  = 7,
                    S_I2C_SEND_3  = 8,
                    S_I2C_RD_ADDR = 9;

    reg [3:0] state_i2c = 4'd0;

    reg [7:0] min_buffer = 8'b00111001;
    reg [7:0] hr_buffer = 8'b00100110;
    reg [1:0] count_out_data = 2'b00;
    reg [7:0] dec_min = 8'h00;
    reg [7:0] unit_min = 8'h00;
    reg [7:0] dec_hr = 8'h00;
    reg [7:0] unit_hr = 8'h00;
    reg [7:0] number = 8'h00;
    reg [7:0] digit = 8'h00;

    reg control_display_valid_reg = 1'b0;
    reg [7:0] control_display_data_reg = 8'h00;

    parameter [4:0] S_DISPLAY_IDLE       = 0,
                    S_DISPLAY_RESET      = 1,
                    S_DISPLAY_SEND_ADDR1 = 2,
                    S_DISPLAY_SEND_DATA1 = 3,
                    S_DISPLAY_SEND_ADDR2 = 4,
                    S_DISPLAY_SEND_DATA2 = 5,
                    S_DISPLAY_SEND_ADDR3 = 6,
                    S_DISPLAY_SEND_DATA3 = 7,
                    S_DISPLAY_SEND_ADDR4 = 8,
                    S_DISPLAY_SEND_DATA4 = 9,
                    S_DISPLAY_CONVERT1   = 10,
                    S_DISPLAY_CONVERT2   = 11,
                    S_DISPLAY_CONVERT3   = 12,
                    S_DISPLAY_CONVERT4   = 13,
                    S_DISPLAY_WAIT1      = 14,
                    S_DISPLAY_WAIT2      = 15,
                    S_DISPLAY_WAIT3      = 16;

    reg [4:0] state_display = 5'd0;

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
                        //hr <= control_data;
                        hr_buffer <= control_data;
                        state_time_update <= S_UART_DATA_MIN;
                    end    
                end
                S_UART_DATA_MIN: begin
                    //min <= control_data;
                    min_buffer <= control_data;
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
                        state_i2c <= S_I2C_SEND_1;
                    end
                end
                S_I2C_SEND_1: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_WR_SEC;
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
                        state_i2c <= S_I2C_SEND_2;
                    end
                end
                S_I2C_SEND_2: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_WR_MIN;
                end
                S_I2C_WR_MIN: begin
                    if (control_i2c_in_ready) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= min;
                        state_i2c <= S_I2C_SEND_3;
                    end                    
                end
                S_I2C_SEND_3: begin
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
        if (control_i2c_out_valid) begin
            count_out_data <= count_out_data + 1'b1;
        end else if (count_out_data == 2'b11) begin
            count_out_data <= 2'b00;
        end else if (reset) begin
            count_out_data <= 2'b00;
        end
/*
        if (count_out_data == 2'b01) 
            min_buffer <= control_i2c_out_data;
        else if (count_out_data == 2'b10)
            hr_buffer <= control_i2c_out_data;*/
    end

    always@(posedge clk) begin
        if (reset)
            state_display <= S_DISPLAY_RESET;
        else begin
            case(state_display)
                S_DISPLAY_RESET: begin
                    state_display <= S_DISPLAY_IDLE;
                end
                S_DISPLAY_IDLE: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;

                    //if (control_i2c_out_valid && count_out_data == 2'b10) begin
                    if (counter == 17'h1FFFF) begin
                        state_display <= S_DISPLAY_SEND_ADDR1;
                        control_display_data_reg <= 8'hC0;
                        control_display_valid_reg <= 1'b1;
                    end
                end
                S_DISPLAY_SEND_ADDR1: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;
                    state_display <= S_DISPLAY_CONVERT1;
                end
                S_DISPLAY_CONVERT1: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;
                    number <= dec_hr;
                    state_display <= S_DISPLAY_SEND_DATA1;
                end
                S_DISPLAY_SEND_DATA1: begin
                    if (control_display_ready) begin
                        control_display_data_reg <= digit;
                        control_display_valid_reg <= 1'b1;
                        state_display <= S_DISPLAY_WAIT1;
                    end
                end
                S_DISPLAY_WAIT1: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;
                    state_display <= S_DISPLAY_SEND_ADDR2;
                end
                S_DISPLAY_SEND_ADDR2: begin
                    if (control_display_ready) begin
                        control_display_data_reg <= 8'hC1;
                        control_display_valid_reg <= 1'b1;
                        state_display <= S_DISPLAY_CONVERT2;
                    end
                end
                S_DISPLAY_CONVERT2: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;
                    number <= unit_hr;
                    state_display <= S_DISPLAY_SEND_DATA2;
                end
                S_DISPLAY_SEND_DATA2: begin
                    if (control_display_ready) begin
                        control_display_data_reg[6:0] <= digit[6:0];
//                        control_display_data_reg[7] <= 1'b1;
                        control_display_data_reg[7] <= blink;
                        control_display_valid_reg <= 1'b1;
                        state_display <= S_DISPLAY_WAIT2;
                    end
                end
                S_DISPLAY_WAIT2: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;
                    state_display <= S_DISPLAY_SEND_ADDR3;
                end
                S_DISPLAY_SEND_ADDR3: begin
                    if (control_display_ready) begin
                        control_display_data_reg <= 8'hC2;
                        control_display_valid_reg <= 1'b1;
                        state_display <= S_DISPLAY_CONVERT3;
                    end
                end
                S_DISPLAY_CONVERT3: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;
                    number <= dec_min;
                    state_display <= S_DISPLAY_SEND_DATA3;
                end
                S_DISPLAY_SEND_DATA3: begin
                    if (control_display_ready) begin
                        control_display_data_reg <= digit;
                        control_display_valid_reg <= 1'b1;
                        state_display <= S_DISPLAY_WAIT3;
                    end
                end
                S_DISPLAY_WAIT3: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;
                    state_display <= S_DISPLAY_SEND_ADDR4;
                end
                S_DISPLAY_SEND_ADDR4: begin
                    if (control_display_ready) begin
                        control_display_data_reg <= 8'hC3;
                        control_display_valid_reg <= 1'b1;
                        state_display <= S_DISPLAY_CONVERT4;
                    end
                end
                S_DISPLAY_CONVERT4: begin
                    control_display_data_reg <= 8'h00;
                    control_display_valid_reg <= 1'b0;
                    number <= unit_min;
                    state_display <= S_DISPLAY_SEND_DATA4;
                end
                S_DISPLAY_SEND_DATA4: begin
                    if (control_display_ready) begin
                        control_display_data_reg <= digit;
                        control_display_valid_reg <= 1'b1;
                        state_display <= S_DISPLAY_IDLE;
                    end
                end
            endcase
        end    
    end

    always@(posedge clk) begin
        if (reset) 
            blink_delay <= 7'h00;    
        else if (counter == 17'h1FFFF) 
            blink_delay <= blink_delay + 1'b1;
        else if (blink_delay == 7'h7F)
            blink_delay <= 7'h00;

        if (blink_delay == 7'h7F) begin
            blink <= ~blink;
        end
    end

    always@(posedge clk) begin
        counter <= counter + 1'b1;
        unit_min[3:0] <= min_buffer[3:0];
        dec_min[2:0] <= min_buffer[6:4];
        unit_hr[3:0] <= hr_buffer[3:0];
        dec_hr[1:0] <= hr_buffer[5:4];
    end

    always@(posedge clk) begin
        case(number)
            0: digit <= 8'b00111111;
            1: digit <= 8'b00000110;
            2: digit <= 8'b01011011;
            3: digit <= 8'b01001111;
            4: digit <= 8'b01100110;
            5: digit <= 8'b01101101;
            6: digit <= 8'b01111101;
            7: digit <= 8'b00000111;
            8: digit <= 8'b01111111;
            9: digit <= 8'b01101111;
        endcase
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
    assign control_display_valid = control_display_valid_reg;
    assign control_display_data = control_display_data_reg;

endmodule
