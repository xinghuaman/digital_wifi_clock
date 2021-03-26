`timescale 1ns / 1ps

/*
Engineer:       sboldenko
Create Date:    21:50:24 03/15/2021 
Design Name:    digital_clock
Module Name:    pwm 
Project Name:   digital_wifi_clock
Target Devices: spartan-3 xc3s50an-4tqg144
Tool versions:  ise 14.7
*/

module pwm
(
    input  clk,
    input  reset,
    input  [9:0] level_pwm,
    output out_pwm
);

    reg [9:0] counter = 10'h000;
    reg value = 1'b0; 
    
    always@(posedge clk) begin
        if (reset) 
            counter <= 10'h000;
        else begin
            counter <= counter + 1'b1;
            
            if (counter == level_pwm)
                value <= 1'b0;
            else if (counter == 10'h000)
                value <= 1'b1;
        end 
    end
    
    assign out_pwm = ~value;
    
endmodule
