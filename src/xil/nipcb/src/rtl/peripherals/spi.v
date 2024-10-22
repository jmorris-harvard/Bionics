module spi_core #(
    parameter O_BW = 32'h8,
    parameter I_BW = 32'h8,
    parameter N_SLAVES = 1
) (
    input wire clk,
    input wire rstn,
    
    // SPI Control Ports
    output wire [N_SLAVES - 1:0] csn,
    output wire sclk,
    inout wire sdio,
    
    // Master Control Ports
    input wire [O_BW-1:0] odata,
    output wire [I_BW-1:0] idata,

    input wire [N_SLAVES - 1:0] send,
    input wire [N_SLAVES - 1:0] recv,

    output wire ready
);

// Signals
reg [N_SLAVES - 1:0] csn_reg;
reg sdo;

reg [O_BW-1:0] odata_reg;
reg [I_BW-1:0] idata_reg;

reg enable_clk_reg;

wire send_trig;
wire recv_trig;

reg ready_reg;
reg write_reg;

reg [7:0] cntr;

// Logic
assign sclk = ( enable_clk_reg ) ? clk : 1'b0;
assign csn = csn_reg;
assign sdio = ( write_reg ) ? sdo : 1'bz;

assign idata = idata_reg;

assign send_trig = |send;
assign recv_trig = |recv;

assign ready = ready_reg;

// State Machines
reg [1:0] s0;
assign state = s0;
localparam s0_00 = 2'b00;
localparam s0_01 = 2'b01;
localparam s0_10 = 2'b10;
localparam s0_11 = 2'b11;
always @(posedge clk) begin
    if ( ~rstn ) begin
        csn_reg = {(N_SLAVES){1'b1}};
        enable_clk_reg <= 0;
        odata_reg <= 0;
        idata_reg <= 0;
        ready_reg <= 0;
        write_reg <= 0;
        sdo <= 0;
        s0 <= s0_00;
    end else begin
        case ( s0 )
        // Idle state
        s0_00: begin
            // Hold all chip selects high
            csn_reg <= {(N_SLAVES){1'b1}};
            // Clock gate
            enable_clk_reg <= 0;
            // Ready to send or recv
            ready_reg <= 1;
            // Not writing
            write_reg <= 0;
            // Got signal to send
            if ( send_trig ) begin
                // Set chip select to target correct device
                csn_reg <= ~send;
                // Set data to send
                odata_reg <= odata;
                // Start clock
                enable_clk_reg <= 1;
                ready_reg <= 0;
                write_reg <= 1;
                // Num bytes to send out
                cntr <= O_BW;
                s0 <= s0_01;
            // Got signal to receive
            end else if ( recv_trig ) begin
                csn_reg <= ~recv;
                idata_reg <= 0;
                enable_clk_reg <= 1;
                ready_reg <= 0;
                write_reg <= 0;
                cntr <= I_BW;
                s0 <= s0_10;
            end
        end
        
        // Sending state
        s0_01: begin
            if ( cntr == 8'h0 ) begin
                s0 <= s0_11;
            end else begin
                // Set SDO to MSB, shift, and countdown
                sdo <= odata_reg[O_BW - 1];
                odata_reg <= odata_reg << 1;
                cntr <= cntr - 8'h1;
            end
        end
        
        // Receiving state
        s0_10: begin
            if ( cntr == 8'h0 ) begin
                s0 <= s0_11;
            end else begin
                // Write item into LSB, shift, and countdown
                idata_reg <= {idata_reg[I_BW-2:0], sdio};
                cntr <= cntr - 8'h1;
            end
        end
        
        // Delay state at end
        s0_11: begin
            s0 <= s0_00;
        end
        
        // Safety case
        default: begin
            s0 <= s0_00;
        end
        endcase
    end
end

endmodule
