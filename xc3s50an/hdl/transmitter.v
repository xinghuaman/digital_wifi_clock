module transmitter
(
    input  clk_sys,
    input  clk_in,
    input  clk_in_x2,
    input  reset,
    input  valid,
    input  [7:0] data,
    output ready,
    output clk_out,
    output data_out
);
    
    reg clk_in_z = 1'b1;
    reg clk_in_front_pulse= 1'b0;
    
    reg clk_in_x2_z = 1'b1;
    reg clk_in_x2_front_pulse= 1'b0;
    
    reg ready_reg = 1'b0;
    reg [7:0] buffer = 8'h00;
    
    reg clk_out_reg = 1'b1;
    reg data_out_reg = 1'b1;

    parameter [3:0] S_IDLE       = 0,
                    S_RESET      = 1,
                    S_WAIT_PULSE = 2,
                    S_SEND_START = 3,
                    S_SEND_BIT0  = 4,
                    S_SEND_BIT1  = 5,
                    S_SEND_BIT2  = 6,
                    S_SEND_BIT3  = 7,
                    S_SEND_BIT4  = 8,
                    S_SEND_BIT5  = 9,
                    S_SEND_BIT6  = 10,
                    S_SEND_BIT7  = 11,
                    S_SEND_ACK   = 12,
                    S_SEND_STOP  = 13;
                         
    reg [3:0] state = 4'b0000;
    
    always@(posedge clk_sys) begin
        clk_in_z <= clk_in;
        
        if (clk_in_z == 1'b0 && clk_in == 1'b1) begin
            clk_in_front_pulse <= 1'b1;
        end else begin
            clk_in_front_pulse <= 1'b0;
        end
    end
    
    always@(posedge clk_sys) begin
        clk_in_x2_z <= clk_in_x2;
        
        if (clk_in_x2_z == 1'b1 && clk_in_x2 == 1'b0) begin
            clk_in_x2_front_pulse <= 1'b1;
        end else begin
            clk_in_x2_front_pulse <= 1'b0;
        end
    end
    
    always@(posedge clk_sys) begin
        if (valid == 1'b1) begin
            buffer <= data;
        end
    end
    
    always@(posedge clk_sys) begin
        if (reset == 1'b1) begin
            state <= S_RESET;
        end else begin
            case(state)
                S_RESET: begin
                    ready_reg <= 1'b0;
                    
                    if (reset == 1'b0) begin
                        state <= S_IDLE;        
                    end 
                end
                S_IDLE: begin
                    ready_reg <= 1'b1;
                    data_out_reg <= 1'b1;
                    
                    if (valid == 1'b1) begin
                        state <= S_WAIT_PULSE;
                    end
                end
                S_WAIT_PULSE: begin
                    ready_reg <= 1'b0;
                    
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_START;
                        data_out_reg <= 1'b0;
                    end
                end             
                S_SEND_START: begin
                    
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[0];
                    end
                    
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_BIT0;
                    end 
                end
                S_SEND_BIT0: begin
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[1];
                    end
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_BIT1;
                    end 
                end         
                S_SEND_BIT1: begin
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[2];
                    end             
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_BIT2;
                    end 
                end 
                S_SEND_BIT2: begin
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[3];
                    end             
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_BIT3;
                    end 
                end 
                S_SEND_BIT3: begin
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[4];
                    end             
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_BIT4;
                    end 
                end 
                S_SEND_BIT4: begin
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[5];
                    end             
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_BIT5;
                    end 
                end 
                S_SEND_BIT5: begin
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[6];
                    end             
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_BIT6;
                    end 
                end
                S_SEND_BIT6: begin
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[7];
                    end             
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_BIT7;
                    end 
                end     
                S_SEND_BIT7: begin
                    if (clk_in == 1'b0 && clk_in_x2_front_pulse == 1'b1) begin
                        data_out_reg <= buffer[7];
                    end             
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_ACK;
                    end 
                end     
                S_SEND_ACK: begin
                    data_out_reg <= 1'b0;
                    
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_SEND_STOP;
                    end 
                end     
                S_SEND_STOP: begin
                    data_out_reg <= 1'b0;               
                
                    if (clk_in_front_pulse == 1'b1) begin
                        state <= S_IDLE;
                    end 
                end             
                default: state <= S_IDLE;
            endcase
        end
    end
    
    always@(posedge clk_sys) begin
        if (state != S_IDLE && state != S_WAIT_PULSE) begin
            clk_out_reg <= clk_in;
        end else begin  
            clk_out_reg <= 1'b1;
        end
    end
    
    assign ready = ready_reg;
    assign data_out = data_out_reg;
    assign clk_out = clk_out_reg;
    
endmodule
