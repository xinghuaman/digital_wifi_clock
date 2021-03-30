`timescale 1 ns / 100 ps

module digital_clock
(
    input  aclk,
    output led,
    output tm1637_clk,
    output tm1637_do,
    input  esp_01_uart_rx,
    output esp_01_uart_tx,
    inout  i2c_scl,
    inout  i2c_sda
);
    
    wire clk;
    wire clk_div;
    wire clk_div_x2;
    wire clk_i2c;
    wire clk_i2c_x2;
    wire reset;

    wire s_axis_valid_uart;
    wire [7:0] s_axis_data_uart;
    wire s_axis_ready_uart;
    wire m_axis_valid_uart;
    wire [7:0] m_axis_data_uart;

    reg  packet = 1'b0;
    reg  [2:0] data_packet_counter = 3'b000;

    wire uart_fifo_rd_en;
    wire uart_fifo_valid;
    wire uart_fifo_full;
    wire uart_fifo_empty;
    wire [7:0] uart_fifo_dout;

    reg  control_valid = 1'b0;
    reg  [7:0] control_data = 8'h00;

    wire i2c_wr_address;
    wire i2c_rd_address;
    wire [7:0] i2c_byte_read;
    wire [6:0] i2c_data_address;
    wire i2c_in_valid;
    wire [7:0] i2c_in_data;
    wire i2c_in_ready;
    wire i2c_out_valid;
    wire [7:0] i2c_out_data;

    reg  tm1637_data_valid = 1'b0;
    reg  [7:0] tm1637_data = 8'h00;
    wire tm1637_data_ready;
    
    reg  [9:0] level_pwm = 10'b0;
    reg  [15:0] counter = 16'h0000;
    reg  check_polarity = 1'b0;    
    
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
        .clk_i2c_x2(clk_i2c_x2)
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
            data_packet_counter <= 3'b000;
        else if (m_axis_valid_uart)
            data_packet_counter <= data_packet_counter + 1'b1;
        else if (data_packet_counter[2] == 1'b1)
            data_packet_counter <= 3'b000;  

        if (data_packet_counter[2] == 1'b1)
            packet <= 1'b1;
        else 
            packet <= 1'b0;       
    end

    uart_fifo uart_fifo_inst
    (
        .clk(clk),
        .rst(reset),
        .din(m_axis_data_uart),
        .wr_en(m_axis_valid_uart),
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
        .control_i2c_wr_addr(i2c_wr_address),
        .control_i2c_rd_addr(i2c_rd_address),
        .control_i2c_byte_read(i2c_byte_read),
        .control_i2c_addr(i2c_data_address),
        .control_i2c_in_valid(i2c_in_valid),
        .control_i2c_in_data(i2c_in_data),
        .control_i2c_in_ready(i2c_in_ready),
        .control_i2c_out_valid(i2c_out_valid),
        .control_i2c_out_data(i2c_out_data)
    );

    i2c_core i2c_core_inst
    (
        .clk_sys(clk),
        .clk_i2c(clk_i2c),
        .clk_i2c_x2(clk_i2c_x2),
        .reset(reset),
        .wr_address(i2c_wr_address),
        .rd_address(i2c_rd_address),
        .byte_read(i2c_byte_read),
        .data_address(i2c_data_address),
        .in_valid(i2c_in_valid),
        .in_data(i2c_in_data),
        .in_ready(i2c_in_ready),
        .out_valid(i2c_out_valid),
        .out_data(i2c_out_data),
        .scl(i2c_scl),
        .sda(i2c_sda)   
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
    
    always@(posedge aclk) begin
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
        .clk(aclk),
        .reset(reset),
        .level_pwm(level_pwm),
        .out_pwm(led)
    );

endmodule
