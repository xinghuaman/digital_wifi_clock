module i2c_core
(
    input  clk_sys,
    input  reset,
    input  clk_interface,
    input  clk_interface_x2,
    input  in_en,
    input  in_rw,
    input  [7:0] in_number_byte,
    input  [6:0] in_address,
    input  in_valid,
    input  [7:0] in_data,
    output out_ready,
    output out_valid,
    output [7:0] out_data,
    inout  sda,
    inout  scl
);

    reg  clk_interface_z;
    reg  clk_interface_x2_z;
    reg  clk_interface_pulse;
    reg  clk_interface_x2_pulse;
    reg  [7:0] buffer = 8'h00;
    reg  [7:0] counter = 8'h00;
    reg  [7:0] word_in = 8'h00;
    reg  valid_out_reg = 1'b0;
    reg  [7:0] data_out_reg = 8'h00;
    reg  ready_reg;
    reg  wait_data;
    reg  ready_to_send;
    reg  sda_control = 1'b0;
    reg  sda_reg;
    wire out_sda;
    reg  scl_reg;

    parameter [4:0] S_IDLE       = 0,
                    S_RESET      = 1,
                    S_WAIT_PULSE = 2,
                    S_START      = 3,
                    S_SEND_BIT7  = 4,
                    S_SEND_BIT6  = 5,
                    S_SEND_BIT5  = 6,
                    S_SEND_BIT4  = 7,
                    S_SEND_BIT3  = 8,
                    S_SEND_BIT2  = 9,
                    S_SEND_BIT1  = 10,
                    S_SEND_BIT0  = 11,
                    S_ACK        = 12,
                    S_STOP       = 13,
                    S_WAIT       = 14,
                    S_READ       = 15,
                    S_READ_BIT7  = 16,
                    S_READ_BIT6  = 17,
                    S_READ_BIT5  = 18,
                    S_READ_BIT4  = 19,
                    S_READ_BIT3  = 20,
                    S_READ_BIT2  = 21,
                    S_READ_BIT1  = 22,
                    S_READ_BIT0  = 23,
                    S_ACK_READ   = 24,
                    S_WAIT_READ  = 25,
                    S_WAIT_READ2 = 26,
                    S_WAIT_READ3 = 27;

    reg  [4:0] state = 4'h0;

    always@(posedge clk_sys) begin
        clk_interface_z <= clk_interface;
        clk_interface_x2_z <= clk_interface_x2;
        wait_data <= ready_reg;

        if (clk_interface_z && ~clk_interface)
            clk_interface_pulse <= 1'b1;
        else
            clk_interface_pulse <= 1'b0;

        if (clk_interface_x2_z && ~clk_interface_x2)
            clk_interface_x2_pulse <= 1'b1;
        else
            clk_interface_x2_pulse <= 1'b0;
    end

    always@(posedge clk_sys) begin
        if (in_en) begin
            buffer[7:1] <= in_address;
            buffer[0] <= in_rw;
        end else if (in_valid)
            buffer <= in_data;
    end

    always@(posedge clk_sys) begin
        if (reset) begin
            state <= S_RESET;
            sda_reg <= 1'b1;
            scl_reg <= 1'b1;
        end else begin
            case(state)
                S_RESET: begin
                    state <= S_IDLE;
                end
                S_IDLE: begin
                    sda_reg <= 1'b1;
                    scl_reg <= 1'b1;
                    ready_reg <= 1'b1;
                    ready_to_send <= 1'b0;
                    counter <= 8'h00;
                    sda_control <= 1'b0;

                    if (in_en) begin
                        state <= S_WAIT_PULSE;
                        ready_reg <= 1'b0;
                    end
                end
                S_WAIT_PULSE: begin
                    if (clk_interface_x2_pulse)
                        state <= S_START;
                end
                S_START: begin
                    sda_reg <= 1'b0;

                    if (clk_interface_pulse) begin
                        scl_reg <= clk_interface;
                        state <= S_SEND_BIT7;
                    end
                end
                S_SEND_BIT7: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse)
                        sda_reg <= buffer[7];

                    if (clk_interface_pulse)
                        state <= S_SEND_BIT6;
                end
                S_SEND_BIT6: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse)
                        sda_reg <= buffer[6];

                    if (clk_interface_pulse)
                        state <= S_SEND_BIT5;
                end
                S_SEND_BIT5: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse)
                        sda_reg <= buffer[5];

                    if (clk_interface_pulse)
                        state <= S_SEND_BIT4;
                end
                S_SEND_BIT4: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse)
                        sda_reg <= buffer[4];

                    if (clk_interface_pulse)
                        state <= S_SEND_BIT3;
                end
                S_SEND_BIT3: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse)
                        sda_reg <= buffer[3];

                    if (clk_interface_pulse)
                        state <= S_SEND_BIT2;
                end
                S_SEND_BIT2: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse)
                        sda_reg <= buffer[2];

                    if (clk_interface_pulse)
                        state <= S_SEND_BIT1;
                end
                S_SEND_BIT1: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse)
                        sda_reg <= buffer[1];

                    if (clk_interface_pulse)
                        state <= S_SEND_BIT0;
                end
                S_SEND_BIT0: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse)
                        sda_reg <= buffer[0];

                    if (clk_interface_pulse)
                        state <= S_ACK;
                end
                S_ACK: begin
                    scl_reg <= clk_interface;
                    sda_reg <= 1'b0;

                    if (clk_interface_x2_pulse && clk_interface)
                        ready_reg <= 1'b1;
                    else 
                        ready_reg <= 1'b0;

                    if (in_valid && wait_data)
                        ready_to_send <= 1'b1;

                    if (clk_interface_pulse && ~in_rw) begin
                        if (ready_to_send)
                            state <= S_WAIT;
                        else
                            state <= S_STOP;
                    end else if (clk_interface_pulse && in_rw) 
                        //state <= S_READ;
                        state <= S_WAIT_READ;
                end
                S_STOP: begin
                    valid_out_reg <= 1'b0;
                    data_out_reg <= 8'h00;
                    sda_control <= 1'b0;

                    if (clk_interface_z) begin
                        scl_reg <= 1'b1;

                        if (clk_interface_x2_pulse)
                            sda_reg <= 1'b1;
                    end

                    if (clk_interface_pulse)
                        state <= S_IDLE;
                end
                S_WAIT: begin
                    ready_to_send <= 1'b0;
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b1;

                    if (clk_interface_pulse)
                        state <= S_SEND_BIT7;
                end
                S_READ: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    sda_control <= 1'b1;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT7;
                end
                S_READ_BIT7: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse && clk_interface)
                        word_in[7] <= out_sda;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT6;
                end
                S_READ_BIT6: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse && clk_interface)
                        word_in[6] <= out_sda;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT5;
                end
                S_READ_BIT5: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse && clk_interface)
                        word_in[5] <= out_sda;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT4;
                end
                S_READ_BIT4: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse && clk_interface)
                        word_in[4] <= out_sda;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT3;
                end
                S_READ_BIT3: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse && clk_interface)
                        word_in[3] <= out_sda;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT2;
                end
                S_READ_BIT2: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse && clk_interface)
                        word_in[2] <= out_sda;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT1;
                end
                S_READ_BIT1: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse && clk_interface)
                        word_in[1] <= out_sda;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT0;
                end
                S_READ_BIT0: begin
                    scl_reg <= clk_interface;

                    if (clk_interface_x2_pulse && clk_interface)
                        word_in[0] <= out_sda;

                    if (clk_interface_pulse)
                        state <= S_ACK_READ;
                end
                S_ACK_READ: begin
                    scl_reg <= clk_interface;
                    sda_control <= 1'b0;

                    if (clk_interface_x2_pulse && ~clk_interface) 
                        counter <= counter + 1'b1;

                    if (counter != in_number_byte) begin
                        sda_reg <= 1'b0;

                        if (clk_interface_pulse)
                            state <= S_WAIT_READ;

                    end else begin
                        sda_reg <= 1'b1;

                        if (clk_interface_pulse)
                            state <= S_STOP;
                    end

                    if (clk_interface_pulse) begin
                        valid_out_reg <= 1'b1;
                        data_out_reg <= word_in;
                    end
                end
                S_WAIT_READ: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    sda_control <= 1'b1;
                    valid_out_reg <= 1'b0;
                    data_out_reg <= 8'h00;

                    if (clk_interface_pulse)
                        state <= S_WAIT_READ2;
                end
                S_WAIT_READ2: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    sda_control <= 1'b1;
                    valid_out_reg <= 1'b0;
                    data_out_reg <= 8'h00;

                    if (clk_interface_pulse)
                        state <= S_WAIT_READ3;
                end
                S_WAIT_READ3: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    sda_control <= 1'b1;
                    valid_out_reg <= 1'b0;
                    data_out_reg <= 8'h00;

                    if (clk_interface_pulse)
                        state <= S_READ_BIT7;
                end
            endcase
        end
    end

    IOBUF 
    #(
        .DRIVE(12),               // Specify the output drive strength
        .IBUF_DELAY_VALUE("0"),   // Specify the amount of added input delay for the buffer,
                                  //  "0"-"16" (Spartan-3A only)
        .IFD_DELAY_VALUE("AUTO"), // Specify the amount of added delay for input register,
                                  //  "AUTO", "0"-"8" (Spartan-3A only)
        .IOSTANDARD("DEFAULT"),   // Specify the I/O standard
        .SLEW("SLOW")             // Specify the output slew rate
    ) 
    IOBUF_sda_inst 
    (
        .O(out_sda),     // Buffer output
        .IO(sda),        // Buffer inout port (connect directly to top-level port)
        .I(sda_reg),     // Buffer input
        .T(sda_control)  // 3-state enable input, high=input, low=output
    );

    IOBUF 
    #(
        .DRIVE(12),               // Specify the output drive strength
        .IBUF_DELAY_VALUE("0"),   // Specify the amount of added input delay for the buffer,
                                  //  "0"-"16" (Spartan-3A only)
        .IFD_DELAY_VALUE("AUTO"), // Specify the amount of added delay for input register,
                                  //  "AUTO", "0"-"8" (Spartan-3A only)
        .IOSTANDARD("DEFAULT"),   // Specify the I/O standard
        .SLEW("SLOW")             // Specify the output slew rate
    ) 
    IOBUF_scl_inst 
    (
        .O(),            // Buffer output
        .IO(scl),        // Buffer inout port (connect directly to top-level port)
        .I(scl_reg),     // Buffer input
        .T(1'b0)         // 3-state enable input, high=input, low=output
    );

    assign out_valid = valid_out_reg;
    assign out_data = data_out_reg;
    assign out_ready = ready_reg;

endmodule