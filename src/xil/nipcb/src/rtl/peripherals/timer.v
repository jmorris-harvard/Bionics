module timer_core #(
  parameter WIDTH = 32
) (
  input wire                clk,
  input wire                rstn,

  input wire                trigger,
  input wire [WIDTH - 1:0]  din,

  output wire               running,
  output wire               signal,
  output wire [WIDTH - 1:0] dout
);

reg [WIDTH - 1:0] data;
assign dout = data;

reg sig;
assign signal = sig;

reg state;
assign running = state;
always @(posedge clk) begin
  if ( ~rstn ) begin
    data <= 0;
    state <= 0;
    sig <= 0;
  end else begin
    // Counting state
    if ( state ) begin
      // Count down by one each cycle
      sig <= 0;
      data <= data - 1;
      // End countdown
      if ( trigger ) begin
        state <= 0;
      end else begin end
      // When data == 0 send signal and start over
      if ( ~|data ) begin
        data <= din;
        sig <= 1;
      end
    // Not counting
    end else begin
      // Keep data at 0
      sig <= 0;
      data <= 0;
      // Start countdown
      if ( trigger ) begin
        state <= 1;
        data <= din;
      end else begin end
    end
  end
end

endmodule
