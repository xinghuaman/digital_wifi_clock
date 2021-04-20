`timescale 1 ns / 100 ps

/*
Engineer:       sboldenko
Design Name:    digital_clock
Module Name:    digital_clock
Project Name:   digital_wifi_clock
Target Devices: spartan-3 xc3s50an-4tqg144
Tool versions:  ise 14.7
*/

module digital_clock
(
    input  aclk,
    output led,
    output tm1637_clk,
    output tm1637_do,
    input  esp_01_uart_rx,
    output esp_01_uart_tx,
    inout  i2c_scl,
    inout  i2c_sda,
    output buzz
);
    
    wire clk;
    wire clk_div;
    wire clk_div_x2;
    wire clk_i2c;
    wire clk_i2c_x2;
    wire clk_pwm;
    wire reset;

    wire s_axis_valid_uart;
    wire [7:0] s_axis_data_uart;
    wire s_axis_ready_uart;
    wire m_axis_valid_uart;
    wire [7:0] m_axis_data_uart;

    reg  find_start = 1'b0;
    reg  packet = 1'b0;
    reg  [2:0] data_packet_counter = 3'b000;

    wire uart_fifo_wr_en;
    wire uart_fifo_rd_en;
    wire uart_fifo_valid;
    wire uart_fifo_full;
    wire uart_fifo_empty;
    wire [7:0] uart_fifo_dout;

    reg  control_valid = 1'b0;
    reg  [7:0] control_data = 8'h00;

    wire i2c_rw;
    wire i2c_en;
    wire [7:0] i2c_byte_read;
    wire [6:0] i2c_address;
    wire i2c_in_valid;
    wire [7:0] i2c_in_data;
    wire i2c_in_ready;
    wire i2c_out_valid;
    wire [7:0] i2c_out_data;

    wire tm1637_data_valid;
    wire [7:0] tm1637_data;
    wire tm1637_data_ready;
    
    reg  [9:0] level_pwm = 10'b0;
    reg  [15:0] counter = 16'h0000;
    reg  check_polarity = 1'b0;
    reg  [9:0] level_buzz = 10'h0FF;
    wire buzz_en;
    wire out_pwm;

    BUFG BUFG_inst 
    (
        .O(clk),     // Clock buffer output
        .I(aclk)     // Clock buffer input
    );

    divider_clock divider_clock_inst
    (
        .clk_in(clk),
        .clk_out(clk_div),
        .clk_out_x2(clk_div_x2),
        .clk_i2c(clk_i2c),
        .clk_i2c_x2(clk_i2c_x2),
        .clk_pwm(clk_pwm)
    );
    
    reset_module reset_module_inst
    (
        .clk(clk),
        .reset(reset)
    );

    uart_core uart_core_inst
    (
        .aclk(clk),
        .areset(reset),
        .s_axis_valid(s_axis_valid_uart),
        .s_axis_data(s_axis_data_uart),
        .s_axis_ready(s_axis_ready_uart),
        .m_axis_valid(m_axis_valid_uart),
        .m_axis_data(m_axis_data_uart),
        .tx(esp_01_uart_tx),
        .rx(esp_01_uart_rx)
    );

    always@(posedge clk) begin
        if (reset)
            find_start <= 1'b0;
        else if (m_axis_data_uart == 8'hED)
            find_start <= 1'b1;
        else if (data_packet_counter[2] == 1'b1)
            find_start <= 1'b0;     
    end

    always@(posedge clk) begin
        if (reset)
            data_packet_counter <= 3'b000;
        else if (find_start && m_axis_valid_uart)
            data_packet_counter <= data_packet_counter + 1'b1;
        else if (data_packet_counter[2] == 1'b1)
            data_packet_counter <= 3'b000;  

        if (data_packet_counter[2] == 1'b1)
            packet <= 1'b1;
        else 
            packet <= 1'b0;       
    end

    assign uart_fifo_wr_en = find_start && m_axis_valid_uart;

    uart_fifo uart_fifo_inst
    (
        .clk(clk),
        .rst(reset),
        .din(m_axis_data_uart),
        .wr_en(uart_fifo_wr_en),
        .rd_en(uart_fifo_rd_en),
        .dout(uart_fifo_dout),
        .full(uart_fifo_full),
        .empty(uart_fifo_empty),
        .valid(uart_fifo_valid)
    );

    always@(posedge clk) begin
        control_valid <= uart_fifo_valid;
        control_data <= uart_fifo_dout;
    end

    control control_inst
    (
        .clk(clk),
        .reset(reset),
        .packet(packet),
        .control_valid(control_valid),
        .control_data(control_data),
        .control_ready(uart_fifo_rd_en),
        .control_answer_valid(s_axis_valid_uart),
        .control_answer_data(s_axis_data_uart),
        .control_answer_ready(s_axis_ready_uart),
        .control_i2c_rw(i2c_rw),
        .control_i2c_en(i2c_en),
        .control_i2c_byte_read(i2c_byte_read),
        .control_i2c_addr(i2c_address),
        .control_i2c_in_valid(i2c_in_valid),
        .control_i2c_in_data(i2c_in_data),
        .control_i2c_in_ready(i2c_in_ready),
        .control_i2c_out_valid(i2c_out_valid),
        .control_i2c_out_data(i2c_out_data),
        .control_display_valid(tm1637_data_valid),
        .control_display_data(tm1637_data),
        .control_display_ready(tm1637_data_ready),
        .control_buzz_en(buzz_en)
    );

    i2c_core i2c_core_inst
    (
        .clk_sys(clk),
        .reset(reset),
        .clk_interface(clk_i2c),
        .clk_interface_x2(clk_i2c_x2),
        .in_en(i2c_en),
        .in_rw(i2c_rw),
        .in_number_byte(i2c_byte_read),
        .in_address(i2c_address),
        .in_valid(i2c_in_valid),
        .in_data(i2c_in_data),
        .out_ready(i2c_in_ready),
        .out_valid(i2c_out_valid),
        .out_data(i2c_out_data),
        .sda(i2c_sda),
        .scl(i2c_scl) 
    );

    tm1637_control_core tm1637_control_core_inst
    (
        .clk(clk),
        .interface_clk(clk_div),
        .interface_clk_x2(clk_div_x2),
        .reset(reset),
        .data_valid(tm1637_data_valid),
        .data(tm1637_data),
        .ready_data(tm1637_data_ready),
        .clk_out(tm1637_clk),
        .data_out(tm1637_do)
    );
    
    always@(posedge clk) begin
        counter <= counter + 1'b1;
        
        if (level_pwm == 10'hFFF && counter == 16'h0000) begin
            check_polarity <= ~check_polarity;
        end
        
        if (counter == 16'hFFFF && check_polarity == 1'b0) begin
            level_pwm <= level_pwm + 1'b1;
        end else if (counter == 16'hFFFF && check_polarity == 1'b1) begin
            level_pwm <= level_pwm - 1'b1;
        end
    end
    
    pwm pwm_led_inst
    (
        .clk(clk),
        .reset(reset),
        .level_pwm(level_pwm),
        .out_pwm(led)
    );

    pwm pwm_buzz_inst
    (
        .clk(clk_pwm),
        .reset(reset),
        .level_pwm(level_buzz),
        .out_pwm(out_pwm)
    );

    assign buzz = buzz_en ? out_pwm : 1'b0;

endmodule
