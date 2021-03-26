`timescale 1 ns / 100 ps

module digital_clock
(
    input  aclk,
    output led,
    output tm1637_clk,
    output tm1637_do,
    input  esp_01_uart_rx,
    output esp_01_uart_tx
);
    
    wire clk_div;
    wire clk_div_x2;
    wire clk_i2c;
    wire clk_i2c_x2;
    wire reset;
    reg  tm1637_data_valid = 1'b0;
    reg  [7:0] tm1637_data = 8'h00;
    wire tm1637_data_ready;
    
    reg  s_axis_valid;
    reg  [7:0] s_axis_data;
    wire s_axis_ready;
    wire m_axis_valid;
    wire [7:0] m_axis_data;
    
    reg  [9:0] level_pwm = 10'b0;
    reg  [15:0] counter = 16'h0000;
    reg  check_polarity = 1'b0;
    
    divider_clock divider_clock_inst
    (
        .clk_in(aclk),
        .clk_out(clk_div),
        .clk_out_x2(clk_div_x2),
        .clk_i2c(clk_i2c),
        .clk_i2c_x2(clk_i2c_x2)
    );
    
    reset_module reset_module_inst
    (
        .clk(aclk),
        .reset(reset)
    );
    
    tm1637_control_core tm1637_control_core_inst
    (
        .clk(aclk),
        .interface_clk(clk_div),
        .interface_clk_x2(clk_div_x2),
        .reset(reset),
        .data_valid(tm1637_data_valid),
        .data(tm1637_data),
        .ready_data(tm1637_data_ready),
        .clk_out(tm1637_clk),
        .data_out(tm1637_do)
    );
    
    uart_core uart_core_inst
    (
        .aclk(aclk),
        .areset(reset),
        .s_axis_valid(s_axis_valid),
        .s_axis_data(s_axis_data),
        .s_axis_ready(s_axis_ready),
        .m_axis_valid(m_axis_valid),
        .m_axis_data(m_axis_data),
        .tx(esp_01_uart_tx),
        .rx(esp_01_uart_rx)
    );
    
    always@(posedge aclk) begin
        if (tm1637_data_ready == 1'b1) begin
            tm1637_data <= m_axis_data;
            tm1637_data_valid <= m_axis_valid;
        end else begin
            tm1637_data <= 8'h00;
            tm1637_data_valid <= 1'b0;
        end
    end
    
    always@(posedge aclk) begin
        if (s_axis_ready == 1'b1 && m_axis_valid == 1'b1) begin
            s_axis_valid <= 1'b1;
            s_axis_data <= 8'hAA;
        end else begin 
            s_axis_valid <= 1'b0;
            s_axis_data <= 8'h00;
        end
    end
    
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
