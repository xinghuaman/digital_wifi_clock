`timescale 1 ns / 100 ps

module reset_module
(
    input  clk,
    output reset
);
    parameter [1:0] S_START = 0,
                    S_RESET = 1,
                    S_IDLE  = 2;
                            
    reg [1:0] current_state = 2'd0;
    
    reg [7:0] counter = 8'd0;
    reg reset_flag = 1'b0;
    
    always@(posedge clk) begin
        case (current_state)
            S_START: begin
                counter <= counter + 1'b1;
                
                if (counter == 8'hFF)
                    current_state <= S_RESET;
            end 
            S_RESET: begin
                counter <= counter + 1'b1;
                reset_flag <= 1'b1;
                
                if (counter == 8'h0F)
                begin
                    current_state <= S_IDLE;
                end 
            end 
            S_IDLE: begin
                reset_flag <= 1'b0;
                counter <= 8'd0;
            end 
            default: current_state <= S_IDLE;   
        endcase
    end
    
    assign reset = reset_flag; 
    
endmodule
