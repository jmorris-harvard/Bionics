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
  // triggers
  input wire ni_recording_trigger,
  input wire ni_recording_clear,

  // inputs
  input wire [3:0]    ni_recording_channel_select,
  input wire [31:0]   ni_recording_cycles_stall,
  input wire [2:0]    ni_recording_pga_gain,

  // outputs
  output wire [31:0]  ni_recording_data,

  // flags
  output wire ni_recording_running,

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

reg stimulation_running;

localparam stimulation_hp_dac_normal  = 2'b00;
localparam stimulation_hp_dac_power_down = 2'b01;
localparam stimulation_sel_ch = 4'hF;

localparam ni_stimulation_magnitude_neutral = 8'h7F;

// -- recording
wire [13:0] recording_rdata;
reg [31:0] recording_data;
reg recording_recv;

// --- timer
reg recording_timer_trigger;
reg [31:0] recording_timer_din;
wire recording_timer_signal;
wire recording_timer_running;
wire [31:0] recording_timer_dout;

// --- about to swtch to another channel
reg recording_pending;

// --- recording in progress
reg recording_en;
reg [1:0] recording_en_ch;

wire recording_valid_ch;

reg [2:0] recording_pga_gain;

reg recording_running;

localparam recording_sel_ch = 4'h0;

// routing
// -- common
assign ni_en_ch = en_ch;
assign ni_sel_ch = sel_ch;

// ---- or stimulation and recording signals
assign en = stimulation_en | recording_en;

// ---- stimulation takes precedent
assign en_ch_s = (stimulation_en) ? stimulation_en_ch
               : (recording_en) ? recording_en_ch : 2'b0;

// ---- stimulation takes precedent
assign sel_ch = (stimulation_en) ? stimulation_sel_ch
              : (recording_en) ? recording_sel_ch : 4'b0;

// -- stimulation
assign ni_stimulation_running = stimulation_running;

// -- recording
assign ni_recording_running = recording_running;
assign ni_pga_gain = recording_pga_gain;
assign recording_valid_ch = ni_recording_channel_select[recording_en_ch];

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
  .idata (recording_rdata),
  .send ({1'b0, stimulation_send}),
  .recv ({recording_recv, 1'b0}),
  
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

// -- recording
timer_core #(
  .WIDTH (32)
) timer_core_recording (
  .clk (clk),
  .rstn (rstn),

  .trigger (recording_timer_trigger),
  .din (recording_timer_din),
  .signal (recording_timer_signal),
  .running (recording_timer_running),
  
  .dout (recording_timer_dout)
);

// state machines
// -- common
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
localparam s0_00 = 2'b00; 
localparam s0_01 = 2'b01; 
localparam s0_10 = 2'b10; 
localparam s0_11 = 2'b11;
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

          // start step
          stimulation_step <= 3'b000;

          s0 <= s0_10;
        end
      end

      // stimulation high --> low --> delay --> stall
      s0_10: begin
        stimulation_send <= 1'b0;
        stimulation_timer_trigger <= 1'b0;

        if ( ~stimulation_timer_running // timer is not on
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
            // enable channel
            stimulation_en <= 1'b1;
            // show stim running
            stimulation_running <= 1'b1;
          end else if ( stimulation_step == 3'b010 ) begin
            // -- low
            stimulation_timer_din <= ni_stimulation_cycles_low;
            // enable channel
            stimulation_en <= 1'b1;
            // show stim running
            stimulation_running <= 1'b1;
          end else if ( stimulation_step == 3'b100 ) begin
            // -- low
            stimulation_timer_din <= ni_stimulation_cycles_delay;
            // enable channel
            stimulation_en <= 1'b1;
            // show stim running
            stimulation_running <= 1'b1;
          end else if ( stimulation_step == 3'b000 ) begin
            // -- stall
            stimulation_timer_din <= ni_stimulation_cycles_stall;
            // -- stall does not enable stimulation
            stimulation_en <= 1'b0;
            // show stim not running
            stimulation_running <= 1'b0;
          end
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

// -- recording
reg [7:0] s1;
localparam s1_00 = 2'b00;
localparam s1_01 = 2'b01;
localparam s1_10 = 2'b10;
localparam s1_11 = 2'b11;
always @(posedge clk) begin
  if ( ~rstn ) begin
    recording_pending <= 1'b0;
    recording_recv <= 1'b0;
    recording_en <= 1'b0;
    recording_wr_fifo <= 1'b0;
    recording_timer_trigger <= 1'b0;
    recording_en_ch <= 2'b00;
    recording_switch_pending <= 1'b0;

    s1 <= s1_00;
  end else begin
    case (s1)

    s1_01: begin
      // reset
      recording_en <= 1'b0;
      recording_wr_fifo <= 1'b0;
      recording_en_ch <= 2'b00;
      recording_pending <= 1'b0;
      recording_timer_trigger <= 1'b0;
      recording_recv <= 1'b0;
      recording_switch_pending <= 1'b0;
      
      if ( recording_timer_running ) begin
        recording_timer_trigger <= 1'b1;
      end

      s1 <= s1_01;
    end

    s1_01: begin
      // idle
      recording_en <= 1'b0;
      recording_wr_fifo <= 1'b0;
      recording_en_ch <= 2'b00;
      recording_pending <= 1'b0;
      recording_timer_trigger <= 1'b0;
      recording_recv <= 1'b0;
      recording_switch_pending <= 1'b0;

      // start recording on trigger
      if ( ni_recording_trigger ) begin
        // next state
        s1 <= s1_10;
      end
    end

    s1_10: begin
      // queue
      recording_en <= 1'b0;
      recording_wr_fifo <= 1'b0;
      recording_pending <= 1'b0;
      recording_timer_trigger <= 1'b0;
      recording_switch_pending <= 1'b0;
      recording_recv <= 1'b0;

      if ( recording_timer_running
         & ~recording_timer_trigger ) begin
        // stop timer if still running
        recording_timer_trigger <= 1'b1;
      end

      if ( ~stimulation_running ) begin
        // set recording state
        recording_en_ch <= 2'b00;
        recording_switch_pending <= 1'b1;
        
        // next state
        s1 <= s1_11;
      end
    end

    s1_11: begin
      // recording
      recording_timer_trigger <= 1'b0;
      recording_wr_fifo <= 1'b0;
      recording_recv <= 1'b0;
      
      // stall to settle input / allow signal propagation
      if ( ~recording_timer_running // timer not running
         & recording_valid_ch // should initiate a recording on this channel
         & ~recording_pending // have not gotten a timer signal yet
         & ~recording_switch_pending // have not collected data
         & ~recording_timer_trigger // have not enable timer
         ) begin
        // start timer
        recording_timer_tigger <= 1'b1;
        recording_timer_din <= ni_recording_cycles_stall;
        // open channel
        recording_en <= 1'b1;
      end

      // wait on signal
      if ( recording_timer_signal ) begin
        // hold trigger
        recording_pending <= 1'b1;
        // stop timer
        recording_timer_trigger <= 1'b1;
      end

      // record
      if ( recording_pending <= 1'b1 // time to record
         & spi_ready // spi idle can recv
         & ~recording_recv // did not send to recv yet
         & ~stimulation_pending // stimulation is not running
         & ~stimulation_send // stimulation is not running
         & s0 != s0_00 // stimulation is not resetting
         ) begin
        // record in progress
        recording_pending <= 1'b0;
        // initiate a switch when done gathering data
        recording_switch_pending <= 1'b1;
        // start record
        recording_recv <= 1'b1;
      end

      // next channel
      if ( recording_switch_pending // time to switch
         & spi_ready // spi done receiving
         & ~recording_recv // spi not about to receive
         ) begin
        // log data
        recording_data[8 * (recording_en_ch) +: 8] <= recording_rdata[7:0];
        // send data on last channel
        if ( recording_en_ch == 2'b11 ) begin
          // write to fifo
          recording_wr_fifo <= 1'b1;
        end
        // move to next channel
        recording_en_ch <= recording_en_ch + 2'b01;
        // end switch process
        recording_switch_pending <= 1'b0;
      end

      // skip channel when not used in cycle
      if ( ~recording_valid_ch ) begin
        // log data as 0
        recording_data[8 * (recording_en_ch) +: 8] <= 8'h00;
        // move to next channel
        recording_en_ch <= recording_en_ch + 2'b01;
      end


      // pause recording when stimulation starts
      if ( stimulation_pending // stim cycle is about to start
         | s0 == s0_00 // stim resetting
         | stimulation_running // stim cycle in progress
         ) begin
        // return to queue stage
        s1 <= s1_10;
      end

      // end recording on trigger
      if ( ni_recording_trigger ) begin
        // reset and return to idle
        s1 <= s1_00;
      end
    end

    endcase
  end
end

endmodule
