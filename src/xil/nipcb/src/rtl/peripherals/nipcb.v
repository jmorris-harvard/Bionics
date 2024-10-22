module nipcb_core (
  input wire clk,
  input wire rstn,

  // stimulation control signals
  // triggers
  input wire ni_stimulation_trigger,

  // inputs
  input wire [1:0]  ni_stimulation_channel_select,
  input wire [31:0] ni_stimulation_cycles_high,
  input wire [31:0] ni_stimulation_cycles_low,
  input wire [31:0] ni_stimulation_cycles_delay,
  input wire [31:0] ni_stimulation_cycles_stall,
  input wire [31:0] ni_stimulation_cycles_count,

  input wire [7:0] ni_stimulation_magnitude_high,
  input wire [7:0] ni_stimulation_magnitude_low,

  // flags
  output wire ni_stimulation_running,

  // recording control signals

  // io signals
  output wire       ni_csn_hp_dac,
  output wire       ni_csn_adc,
  inout  wire       ni_sdio,
  output wire       ni_sclk,
  output wire [2:0] ni_pga_gain,
  output wire [3:0] ni_sel_ch,
  output wire [3:0] ni_en_ch
);

// signals
// -- common
// ---- enforce single channel active
reg  [3:0] en_ch;
wire [1:0] en_ch_s;

// ---- selection enforcement not needed 
wire [3:0] sel_ch;

wire spi_ready;

// -- stimulation 
reg [9:0] stimulation_tdata;
reg stimulation_send;

reg stimulation_timer_trigger;
reg [31:0] stimulation_timer_din;
wire stimulation_timer_signal;
wire stimulation_timer_running;
wire [31:0] stimulation_timer_dout;

reg stimulation_pending;

reg stimulation_en;
reg [1:0] stimulation_en_ch;

reg [31:0] stimulation_cycles_counter;

reg [2:0] stimulation_step;

localparam stimulation_hp_dac_normal  = 2'b00;
localparam stimulation_hp_dac_power_down = 2'b01;
localparam stimulation_sel_ch = 4'hF;

localparam ni_stimulation_magnitude_neutral = 8'h7F;

// -- recording

// routing
// -- common
assign ni_en_ch = en_ch;
assign ni_sel_ch = sel_ch;

// ---- or stimulation and recording signals
assign en = stimulation_en;

// ---- stimulation takes precedent
assign en_ch_s = (stimulation_en) ? stimulation_en_ch
                                  : 2'b0;

// ---- stimulation takes precedent
assign sel_ch = (stimulation_en) ? stimulation_sel_ch
                                 : 4'b0;

// -- Stimulation
assign ni_stimulation_running = stimulation_en;

// Instances
// -- Common
spi_core #(
  .O_BW (16),
  .I_BW (14),
  .N_SLAVES (2)
) spi_core_stimulation_recording (
  .clk (clk),
  .rstn (rstn),

  .csn ({ni_csn_adc, ni_csn_hp_dac}),
  .sclk (ni_sclk),
  .sdio (ni_sdio),
  
  .odata ({1'b0, stimulation_tdata, 5'b0}),
  .idata (),
  .send ({1'b0, stimulation_send}),
  .recv ({1'b0, 1'b0}),
  
  .ready (spi_ready)
);

// -- Stimulation
timer_core #(
  .WIDTH (32)
) timer_core_stimulation (
  .clk (clk),
  .rstn (rstn),

  .trigger (stimulation_timer_trigger),
  .din (stimulation_timer_din),
  .signal (stimulation_timer_signal),
  .running (stimulation_timer_running),
  
  .dout (stimulation_timer_dout)
);

// State machines
// -- Common
integer i;
always @(posedge clk) begin
  if ( ~rstn ) begin
    en_ch <= 4'b0;
  end else begin
    en_ch <= 4'b0;
    if ( en ) begin
      en_ch[en_ch_s] <= 1'b1;
    end
  end
end

// -- stimulation
reg [1:0] s0;
localparam s0_00 = 3'b000; 
localparam s0_01 = 3'b001; 
localparam s0_10 = 3'b010; 
localparam s0_11 = 3'b011;
always @(posedge clk) begin
  if (~rstn) begin
    stimulation_send <= 1'b0;
    stimulation_en <= 1'b0;
    stimulation_timer_trigger <= 1'b0;
    stimulation_step <= 3'b0;
    stimulation_cycles_counter <= 32'b1;
    
    stimulation_pending <= 1'b0;

    stimulation_en_ch <= 2'b00;

    s0 <= s0_00;
  end else begin
    case (s0)
      // reset
      s0_00: begin
        stimulation_en <= 1'b0;
        stimulation_timer_trigger <= 1'b0;
        stimulation_step <= 3'b0;

        // stop -- timer if running
        if ( stimulation_timer_running ) begin
          stimulation_timer_trigger <= 1'b1;
        end

        // send -- neutral
        if ( spi_ready ) begin
          stimulation_tdata <= {stimulation_hp_dac_normal, ni_stimulation_magnitude_neutral};
          stimulation_send <= 1'b1;
          s0 <= s0_01;
        end
      end

      // idle
      s0_01: begin
        stimulation_en <= 1'b0;
        stimulation_timer_trigger <= 1'b0;
        stimulation_send <= 1'b0;
        stimulation_step <= 3'b0;

        if ( ni_stimulation_trigger ) begin
          // hold trigger
          stimulation_pending <= 1'b1;
        end

        if ( stimulation_pending & spi_ready ) begin
          // select -- channel
          stimulation_en_ch <= ni_stimulation_channel_select;

          // send -- high
          stimulation_tdata <= {stimulation_hp_dac_normal, ni_stimulation_magnitude_high};
          stimulation_send <= 1'b1;

          // release trigger
          stimulation_pending <= 1'b0;

          // start step
          stimulation_step <= 3'b001;

          // set counter
          stimulation_cycles_counter <= ni_stimulation_cycles_count;

          s0 <= s0_10;
        end
      end

      // stimulation high --> low --> delay --> stall
      s0_10: begin
        stimulation_send <= 1'b0;
        stimulation_timer_trigger <= 1'b0;

        if ( ~stimulation_timer_running // time is not on
           & spi_ready // spi is still sending
           & ~stimulation_send // spi is still sending
           & ~stimulation_pending // process step is done
           & ~stimulation_timer_trigger // timer has already been enabled
           ) begin
          // start timer
          stimulation_timer_trigger <= 1'b1;
          if ( stimulation_step == 3'b001 ) begin
            // -- high
            stimulation_timer_din <= ni_stimulation_cycles_high;
          end else if ( stimulation_step == 3'b010 ) begin
            // -- low
            stimulation_timer_din <= ni_stimulation_cycles_low;
          end else if ( stimulation_step == 3'b100 ) begin
            // -- low
            stimulation_timer_din <= ni_stimulation_cycles_delay;
          end else if ( stimulation_step == 3'b000 ) begin
            // -- stall
            stimulation_timer_din <= ni_stimulation_cycles_stall;
          end

          // enable channel
          stimulation_en <= 1'b1;
        end

        // wait on signal
        if ( stimulation_timer_signal ) begin
          // hold trigger
          stimulation_pending <= 1'b1;

          // stop timer
          stimulation_timer_trigger <= 1'b1;

          // disable channel
          stimulation_en <= 1'b0;
        end

        // move to next step
        if ( stimulation_pending & spi_ready ) begin
          // send
          stimulation_tdata[9:8] <= stimulation_hp_dac_normal;
          if ( stimulation_step == 3'b001 ) begin
            // -- high --> low
            stimulation_tdata[7:0] <= ni_stimulation_magnitude_low;
            stimulation_step <= 3'b010;
          end else if ( stimulation_step == 3'b010 ) begin
            // -- low --> delay
            stimulation_tdata[7:0] <= ni_stimulation_magnitude_neutral;
            stimulation_step <= 3'b100;
          end else if ( stimulation_step == 3'b100 ) begin
            // -- delay --> high or stall

            // decrement counter
            stimulation_cycles_counter <= stimulation_cycles_counter - 32'b1;

            if ( ~|stimulation_cycles_counter ) begin
              // ---- delay --> stall
              stimulation_tdata[7:0] <= ni_stimulation_magnitude_neutral;
              stimulation_cycles_counter <= ni_stimulation_cycles_count;

              stimulation_step <= 3'b000;
            end else begin
              // ---- delay --> high
              stimulation_tdata[7:0] <= ni_stimulation_magnitude_high;

              stimulation_step <= 3'b001;
            end
          end else if ( stimulation_step == 3'b000 ) begin
            // -- stall --> high
            stimulation_tdata[7:0] <= ni_stimulation_magnitude_high;
            stimulation_step <= 3'b001;
          end
          stimulation_send <= 1'b1;

          // release trigger
          stimulation_pending <= 1'b0;

          s0 <= s0_10;
        end

        if ( ni_stimulation_trigger ) begin
          // end stimulation
          s0 <= s0_00;
        end
      end

      default: begin
        s0 <= s0_00;
      end
    endcase
  end
end

endmodule
