`timescale 1 ns / 100 ps

module tm1637_control_core
(
    input  clk,
    input  interface_clk,
    input  interface_clk_x2,
    input  reset,
    input  data_valid,
    input  [7:0] data,
    output reg ready_data,
    output clk_out,
    output data_out
);
    
    reg  valid_to_send = 1'b0;
    reg  [7:0] data_to_send = 8'h00;
    wire ready;
    reg  ready_to_send;
    reg  [7:0] buffer = 8'h00;
    reg  packet = 1'b0;
    
    parameter [3:0] S_RESET        = 0, 
                    S_INIT         = 1,
                    S_WAIT_CONF    = 2,
                    S_CONF         = 3,
                    S_SEND_CONF    = 4,
                    S_WAIT_ADDRESS = 5,
                    S_ADDRESS      = 6,
                    S_SEND_ADDRESS = 7,
                    S_WAIT_DATA    = 8,
                    S_DATA         = 9,
                    S_SEND_DATA    = 10,
                    S_WAIT_END     = 11;
                         
    reg [3:0] state = 2'b0;
    
    always@(posedge clk) begin
        ready_to_send <= ready;
        
        if (data_valid == 1'b1) begin
            buffer <= data;
        end
    end
    
    always@(posedge clk) begin  
        if (reset) begin
            state <= S_RESET;
        end else begin
            case(state)
                S_RESET: begin
                    state <= S_INIT;    
                    ready_data <= 1'b0;
                    packet <= 1'b0;
                end 
                S_INIT: begin
                    if (ready_to_send == 1'b1) begin
                        valid_to_send <= 1'b1;
                        data_to_send <= 8'b10001111;
                        ready_data <= 1'b0;
                        state <= S_WAIT_CONF;
                    end
                end 
                S_WAIT_CONF: begin
                    valid_to_send <= 1'b0;
                    data_to_send <= 8'h00;
                    ready_data <= 1'b1;  
                    
                    if (ready_to_send == 1'b1 && data_valid == 1'b1) begin
                        state <= S_CONF;
                        ready_data <= 1'b0;
                    end
                end 
                S_CONF: begin
                    if (ready_to_send == 1'b1) begin
                        valid_to_send <= 1'b1;
                        data_to_send <= 8'b01000100;
                        state <= S_SEND_CONF;
                    end
                end
                S_SEND_CONF: begin
                    valid_to_send <= 1'b0;
                    data_to_send <= 8'h00;
                    
                    if (ready_to_send == 1'b0) begin
                        state <= S_WAIT_ADDRESS;
                    end
                end
                S_WAIT_ADDRESS: begin
                    if (ready_to_send == 1'b1) begin
                        state <= S_ADDRESS;
                        packet <= 1'b1;
                    end
                end
                S_ADDRESS: begin
                    valid_to_send <= 1'b1;
                    data_to_send <= buffer;
                    state <= S_SEND_ADDRESS;
                end
                S_SEND_ADDRESS: begin
                    valid_to_send <= 1'b0;
                    data_to_send <= 8'h00;
                    
                    if (ready_to_send == 1'b0) begin
                        state <= S_WAIT_DATA;
                    end
                end
                S_WAIT_DATA: begin
                    if (ready_to_send == 1'b1) begin
                        ready_data <= 1'b1;
                    end
                    
                    if (data_valid == 1'b1) begin
                        ready_data <= 1'b0;
                        state <= S_DATA;
                    end
                end 
                S_DATA: begin
                    valid_to_send <= 1'b1;
                    data_to_send <= buffer;
                    state <= S_SEND_DATA;
                end 
                S_SEND_DATA: begin
                    valid_to_send <= 1'b0;
                    data_to_send <= 8'h00;
                    
                    if (ready_to_send == 1'b0) begin
                        state <= S_WAIT_END;
                        packet <= 1'b0;
                    end
                end
                S_WAIT_END: begin
                    if (ready_to_send == 1'b1) begin
                        state <= S_WAIT_CONF;
                    end
                end
            endcase
        end
    end
    
    transmitter transmitter_inst
    (
        .clk_sys(clk),
        .clk_in(interface_clk),
        .clk_in_x2(interface_clk_x2),
        .reset(reset),
        .packet(packet),
        .valid(valid_to_send),
        .data(data_to_send),
        .ready(ready),
        .clk_out(clk_out),
        .data_out(data_out)
    );
    
endmodule
    