`timescale 1 ns / 100 ps

module divider_clock 
(
    input  clk_in,
    output clk_out,
    output clk_out_x2,
    output clk_i2c,
    output clk_i2c_x2
);
    
    reg [7:0] freq_counter = 8'h00;
    reg freq = 1'b0;  
    reg [6:0] freq_x2_counter = 7'h00;
    reg freq_x2 = 1'b0; 
    
    reg [8:0] i2c_freq_counter = 9'h000;
    reg i2c_freq = 1'b0;
    reg [7:0] i2c_freq_x2_counter = 8'h00;
    reg i2c_freq_x2 = 1'b0;
    
    always@(posedge clk_in) begin
        freq_counter <= freq_counter + 1'b1;
        
        if (freq_counter == 8'h7f) begin
            freq <= 1'b0;   
        end else if (freq_counter == 8'hff) begin
            freq <= 1'b1;
        end
    end
    
    always@(posedge clk_in) begin
        freq_x2_counter <= freq_x2_counter + 1'b1;
        
        if (freq_x2_counter == 7'h3f) begin
            freq_x2 <= 1'b0;    
        end else if (freq_x2_counter == 7'h7f) begin
            freq_x2 <= 1'b1;
        end
    end
    
    always@(posedge clk_in) begin
        i2c_freq_counter <= i2c_freq_counter + 1'b1;
        
        if (i2c_freq_counter == 9'h095) begin
            i2c_freq <= 1'b0;
        end else if (i2c_freq_counter == 9'h12b) begin
            i2c_freq <= 1'b1;
            i2c_freq_counter <= 9'h000;
        end 
    end
    
    always@(posedge clk_in) begin
        i2c_freq_x2_counter <= i2c_freq_x2_counter + 1'b1;
        
        if (i2c_freq_x2_counter == 8'h4A) begin
            i2c_freq_x2 <= 1'b0;
        end else if (i2c_freq_x2_counter == 8'h95) begin
            i2c_freq_x2 <= 1'b1;
            i2c_freq_x2_counter <= 9'h000;
        end 
    end
    
    assign clk_out = freq;
    assign clk_out_x2 = freq_x2; 
    assign clk_i2c = i2c_freq;
    assign clk_i2c_x2 = i2c_freq_x2;
    
endmodule
