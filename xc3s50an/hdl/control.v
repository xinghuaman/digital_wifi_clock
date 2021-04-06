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

    output control_i2c_en,
    output control_i2c_rw,
    output [7:0] control_i2c_byte_read,
    output [6:0] control_i2c_addr,
    output control_i2c_in_valid,
    output [7:0] control_i2c_in_data,
    input  control_i2c_in_ready,
    input  control_i2c_out_valid,
    input  [7:0] control_i2c_out_data,

    output control_display_valid,
    output [7:0] control_display_data,
    input  control_display_ready,

    output control_buzz_en
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

    reg control_i2c_rw_reg = 1'b0;
    reg control_i2c_en_reg = 1'b0;
    reg [ 7:0] control_i2c_byte_read_reg = 8'h00;
    reg [ 6:0] control_i2c_addr_reg = 7'b0000000;
    reg control_i2c_in_valid_reg = 1'b0;
    reg [ 7:0] control_i2c_in_data_reg = 8'h00;
    reg [19:0] counter = 20'h00000;
    reg [16:0] counter_blink = 17'h00000;
    reg [ 6:0] blink_delay = 7'h00;
    reg blink = 1'b0;
    reg init = 1'b0;
    reg [ 7:0] copy_sec = 8'h00;
    reg [ 7:0] copy_min = 8'h00;
    reg [ 7:0] copy_hr = 8'h00;

    parameter [5:0] S_I2C_IDLE        = 0,
                    S_I2C_RESET       = 1,
                    S_I2C_SEND_AD_I   = 2,
                    S_I2C_WAIT_I1     = 3,
                    S_I2C_SEND_AR_I   = 4,
                    S_I2C_WAIT_I2     = 5,
                    S_I2C_INIT        = 6,
                    S_I2C_WAIT        = 7,
                    S_I2C_SEND_AD_S   = 8,
                    S_I2C_WAIT_S1     = 9,
                    S_I2C_SEND_AR_S   = 10,
                    S_I2C_WAIT_S2     = 11,
                    S_I2C_SHR         = 12,
                    S_I2C_TIMEUPDATE  = 13,
                    S_I2C_SEND_AD_TU  = 14,
                    S_I2C_WAIT_TU1    = 15,
                    S_I2C_SEND_AR_TU  = 16,
                    S_I2C_WAIT_TU2    = 17,
                    S_I2C_SEND_SEC    = 18,
                    S_I2C_WAIT_TU3    = 19,
                    S_I2C_SEND_MIN    = 20,
                    S_I2C_WAIT_TU4    = 21,
                    S_I2C_SEND_HR     = 22,
                    S_I2C_TIMEREAD    = 23,
                    S_I2C_SEND_AD_TR1 = 24,
                    S_I2C_WAIT_TR1    = 25,
                    S_I2C_SEND_AR_TR  = 26,
                    S_I2C_WAIT_TR2    = 27,
                    S_I2C_SEND_AD_TR2 = 28,
                    S_I2C_WAIT_TR3    = 29;

    reg [4:0] state_i2c = 5'd0;

    reg [7:0] min_buffer = 8'b00000000;
    reg [7:0] hr_buffer = 8'b00000000;
    reg [7:0] sec_buffer = 8'b00000000;
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

    reg [ 4:0] state_display = 5'd0;

    reg [ 7:0] hr_comp = 8'h00;
    reg [19:0] buzz_count = 20'h00000;
    reg buzz_en_reg = 1'b0;

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
        else if (state_i2c == S_I2C_TIMEUPDATE) 
            new_data <= 1'b0;
    end

    always@(posedge clk) begin
        if (reset)
            state_i2c <= S_I2C_RESET;
        else begin    
            case(state_i2c)
                S_I2C_RESET: begin
                    state_i2c <= S_I2C_TIMEREAD;
                    control_i2c_byte_read_reg <= 8'h00;
                    init <= 1'b1;
                end
                S_I2C_SEND_AD_I: begin
                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_rw_reg <= 1'b0;
                        control_i2c_en_reg <= 1'b1;
                        control_i2c_addr_reg <= CONST_ADDR_DS1307;
                        state_i2c <= S_I2C_WAIT_I1;
                    end
                end
                S_I2C_WAIT_I1: begin
                    control_i2c_en_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_SEND_AR_I;
                end
                S_I2C_SEND_AR_I: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= 8'h00;
                        state_i2c <= S_I2C_WAIT_I2;
                    end
                end
                S_I2C_WAIT_I2: begin
                    control_i2c_en_reg <= 1'b0;
                    control_i2c_in_valid_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_INIT;
                end
                S_I2C_INIT: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg[7] <= 1'b0;
                        control_i2c_in_data_reg[6:0] <= copy_sec[6:0];
                        state_i2c <= S_I2C_WAIT;
                    end
                end
                S_I2C_WAIT: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b1)
                        state_i2c <= S_I2C_SEND_AD_S;
                end
                S_I2C_SEND_AD_S: begin
                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_rw_reg <= 1'b0;
                        control_i2c_en_reg <= 1'b1;
                        control_i2c_addr_reg <= CONST_ADDR_DS1307;
                        state_i2c <= S_I2C_WAIT_S1;
                    end
                end
                S_I2C_WAIT_S1: begin
                    control_i2c_en_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_SEND_AR_S;
                end
                S_I2C_SEND_AR_S: begin
                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= 8'h02;
                        state_i2c <= S_I2C_WAIT_S2;
                    end
                end
                S_I2C_WAIT_S2: begin
                    control_i2c_in_valid_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_SHR;
                end
                S_I2C_SHR: begin
                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg[7:6] <= 2'b00;
                        control_i2c_in_data_reg[5:0] <= copy_hr[5:0];
                        init <= 1'b0;
                        state_i2c <= S_I2C_IDLE;
                    end
                end
                S_I2C_IDLE: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;
                    control_i2c_addr_reg <= 7'b0000000;

                    if (new_data == 1'b1)
                        state_i2c <= S_I2C_TIMEUPDATE;

                    if (counter == 20'hFFFFF)
                        state_i2c <= S_I2C_TIMEREAD;

                    if (init == 1'b1)
                        state_i2c <= S_I2C_SEND_AD_I;
                end
                S_I2C_TIMEUPDATE: begin
                    state_i2c <= S_I2C_SEND_AD_TU;
                end
                S_I2C_SEND_AD_TU: begin
                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_rw_reg <= 1'b0;
                        control_i2c_en_reg <= 1'b1;
                        control_i2c_addr_reg <= CONST_ADDR_DS1307;
                        state_i2c <= S_I2C_WAIT_TU1;
                    end
                end
                S_I2C_WAIT_TU1: begin
                    control_i2c_en_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_SEND_AR_TU;
                end
                S_I2C_SEND_AR_TU: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= 8'h00;
                        state_i2c <= S_I2C_WAIT_TU2;
                    end
                end
                S_I2C_WAIT_TU2: begin
                    control_i2c_en_reg <= 1'b0;
                    control_i2c_in_valid_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_SEND_SEC;
                end
                S_I2C_SEND_SEC: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= sec;
                        state_i2c <= S_I2C_WAIT_TU3;
                    end
                end
                S_I2C_WAIT_TU3: begin
                    control_i2c_en_reg <= 1'b0;
                    control_i2c_in_valid_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_SEND_MIN;
                end
                S_I2C_SEND_MIN: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= min;
                        state_i2c <= S_I2C_WAIT_TU4;
                    end
                end
                S_I2C_WAIT_TU4: begin
                    control_i2c_en_reg <= 1'b0;
                    control_i2c_in_valid_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_SEND_HR;
                end
                S_I2C_SEND_HR: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= hr;
                        state_i2c <= S_I2C_IDLE;
                    end
                end
                S_I2C_TIMEREAD: begin
                    state_i2c <= S_I2C_SEND_AD_TR1;
                    control_i2c_byte_read_reg <= 8'h3;
                end
                S_I2C_SEND_AD_TR1: begin
                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_rw_reg <= 1'b0;
                        control_i2c_en_reg <= 1'b1;
                        control_i2c_addr_reg <= CONST_ADDR_DS1307;
                        state_i2c <= S_I2C_WAIT_TR1;
                    end
                end
                S_I2C_WAIT_TR1: begin
                    control_i2c_en_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b0)
                        state_i2c <= S_I2C_SEND_AR_TR;
                end
                S_I2C_SEND_AR_TR: begin
                    control_i2c_in_valid_reg <= 1'b0;
                    control_i2c_in_data_reg <= 8'h00;

                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_in_valid_reg <= 1'b1;
                        control_i2c_in_data_reg <= 8'h00;
                        state_i2c <= S_I2C_WAIT_TR2;
                    end
                end
                S_I2C_WAIT_TR2: begin
                    control_i2c_en_reg <= 1'b0;
                    control_i2c_in_valid_reg <= 1'b0;

                    if (control_i2c_in_ready == 1'b1)
                        state_i2c <= S_I2C_SEND_AD_TR2;
                end
                S_I2C_SEND_AD_TR2: begin
                    if (control_i2c_in_ready == 1'b1) begin
                        control_i2c_rw_reg <= 1'b1;
                        control_i2c_en_reg <= 1'b1;
                        control_i2c_addr_reg <= CONST_ADDR_DS1307;
                        state_i2c <= S_I2C_WAIT_TR3;
                    end
                end
                S_I2C_WAIT_TR3: begin
                    control_i2c_en_reg <= 1'b0;

                    if (count_out_data == 2'b11) begin
                        state_i2c <= S_I2C_IDLE;
                        control_i2c_rw_reg <= 1'b0;
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

        if (count_out_data == 2'b01) begin 
            if (init)
                copy_min <= control_i2c_out_data;
            else
                min_buffer <= control_i2c_out_data;
        end else if (count_out_data == 2'b10 && control_i2c_out_valid) begin
            if (init)
                copy_hr <= control_i2c_out_data;
            else
                hr_buffer <= control_i2c_out_data;
        end else if (count_out_data == 2'b00 && control_i2c_out_valid) begin
            if (init)
                copy_sec <= control_i2c_out_data;
        end
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

                    if (control_i2c_out_valid && count_out_data == 2'b10) begin
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
        counter_blink <= counter_blink + 1'b1;

        if (reset) 
            blink_delay <= 7'h00;    
        else if (counter_blink == 17'h1FFFF) 
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
        unit_min[7:4] <= 4'h0;
        dec_min[3:0] <= min_buffer[7:4];
        dec_min[7:4] <= 4'h0;

        unit_hr[3:0] <= hr_buffer[3:0];
        unit_hr[7:4] <= 4'h0;
        dec_hr[3:0] <= hr_buffer[7:4];
        dec_hr[7:4] <= 4'h0;
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

    always@(posedge clk) begin
        if (hr_comp != hr_buffer) begin
            buzz_en_reg <= 1'b1;
            hr_comp <= hr_buffer;
        end else if (buzz_count == 20'hFFFFF) begin
            buzz_en_reg <= 1'b0;
        end

        if (buzz_en_reg)
            buzz_count <= buzz_count + 1'b1;
    end

    assign control_ready = ready_reg;
    assign control_answer_valid = control_answer_valid_reg;
    assign control_answer_data = control_answer_data_reg;
    assign control_i2c_rw = control_i2c_rw_reg;
    assign control_i2c_en = control_i2c_en_reg;
    assign control_i2c_addr = control_i2c_addr_reg;
    assign control_i2c_in_valid = control_i2c_in_valid_reg;
    assign control_i2c_in_data = control_i2c_in_data_reg;
    assign control_display_valid = control_display_valid_reg;
    assign control_display_data = control_display_data_reg;
    assign control_i2c_byte_read = control_i2c_byte_read_reg;
    assign control_buzz_en = buzz_en_reg;

endmodule
