`timescale 1ns / 1ps

module servo_pwm_tb;

localparam int CLK_PERIOD_NS = 10;
localparam logic [5:0] CTRL_ADDR         = 6'h00;
localparam logic [5:0] UI_TICKS_ADDR     = 6'h08;
localparam logic [5:0] SOF_UI_TICKS_ADDR = 6'h0c;
localparam logic [5:0] CH0_UI_TICKS_ADDR = 6'h20;
localparam logic [5:0] CH1_UI_TICKS_ADDR = 6'h24;
localparam logic [5:0] CH2_UI_TICKS_ADDR = 6'h28;
localparam logic [5:0] CH3_UI_TICKS_ADDR = 6'h2c;

logic clk;
logic resetn;

logic [5:0]  s00_axi_awaddr;
logic [2:0]  s00_axi_awprot;
logic        s00_axi_awvalid;
wire         s00_axi_awready;
logic [31:0] s00_axi_wdata;
logic [3:0]  s00_axi_wstrb;
logic        s00_axi_wvalid;
wire         s00_axi_wready;
wire [1:0]   s00_axi_bresp;
wire         s00_axi_bvalid;
logic        s00_axi_bready;
logic [5:0]  s00_axi_araddr;
logic [2:0]  s00_axi_arprot;
logic        s00_axi_arvalid;
wire         s00_axi_arready;
wire [31:0]  s00_axi_rdata;
wire [1:0]   s00_axi_rresp;
wire         s00_axi_rvalid;
logic        s00_axi_rready;

wire [3:0] ch_pwm_pin;

int total_checks;
int failed_checks;

servo_pwm dut (
    .ch_pwm_pin      (ch_pwm_pin),
    .s00_axi_aclk    (clk),
    .s00_axi_aresetn (resetn),
    .s00_axi_awaddr  (s00_axi_awaddr),
    .s00_axi_awprot  (s00_axi_awprot),
    .s00_axi_awvalid (s00_axi_awvalid),
    .s00_axi_awready (s00_axi_awready),
    .s00_axi_wdata   (s00_axi_wdata),
    .s00_axi_wstrb   (s00_axi_wstrb),
    .s00_axi_wvalid  (s00_axi_wvalid),
    .s00_axi_wready  (s00_axi_wready),
    .s00_axi_bresp   (s00_axi_bresp),
    .s00_axi_bvalid  (s00_axi_bvalid),
    .s00_axi_bready  (s00_axi_bready),
    .s00_axi_araddr  (s00_axi_araddr),
    .s00_axi_arprot  (s00_axi_arprot),
    .s00_axi_arvalid (s00_axi_arvalid),
    .s00_axi_arready (s00_axi_arready),
    .s00_axi_rdata   (s00_axi_rdata),
    .s00_axi_rresp   (s00_axi_rresp),
    .s00_axi_rvalid  (s00_axi_rvalid),
    .s00_axi_rready  (s00_axi_rready)
);

always #(CLK_PERIOD_NS/2) clk = ~clk;

task automatic sample_cycle;
begin
    @(posedge clk);
    #1;
end
endtask

task automatic expect_eq32(
    input string label,
    input logic [31:0] actual,
    input logic [31:0] expected
);
begin
    total_checks++;
    if (actual !== expected) begin
        failed_checks++;
        $error("%s mismatch: actual=0x%08x expected=0x%08x", label, actual, expected);
    end
end
endtask

task automatic expect_eq_int(
    input string label,
    input int actual,
    input int expected
);
begin
    total_checks++;
    if (actual != expected) begin
        failed_checks++;
        $error("%s mismatch: actual=%0d expected=%0d", label, actual, expected);
    end
end
endtask

task automatic expect_true(
    input string label,
    input bit condition
);
begin
    total_checks++;
    if (!condition) begin
        failed_checks++;
        $error("%s failed", label);
    end
end
endtask

task automatic apply_reset;
begin
    resetn = 1'b0;
    s00_axi_awaddr  = '0;
    s00_axi_awprot  = '0;
    s00_axi_awvalid = 1'b0;
    s00_axi_wdata   = '0;
    s00_axi_wstrb   = '0;
    s00_axi_wvalid  = 1'b0;
    s00_axi_bready  = 1'b1;
    s00_axi_araddr  = '0;
    s00_axi_arprot  = '0;
    s00_axi_arvalid = 1'b0;
    s00_axi_rready  = 1'b1;

    repeat (6) @(posedge clk);
    #1;
    resetn = 1'b1;
    repeat (6) @(posedge clk);
    #1;
end
endtask

task automatic axi_write(
    input logic [5:0] addr,
    input logic [31:0] data,
    input logic [3:0] strb = 4'hf
);
    int timeout;
    bit ready_seen;
begin
    @(negedge clk);
    s00_axi_awaddr  = addr;
    s00_axi_awvalid = 1'b1;
    s00_axi_wdata   = data;
    s00_axi_wstrb   = strb;
    s00_axi_wvalid  = 1'b1;

    timeout = 0;
    ready_seen = 1'b0;
    while (!ready_seen) begin
        sample_cycle();
        ready_seen = s00_axi_awready && s00_axi_wready;
        timeout++;
        if (timeout > 50) begin
            $fatal(1, "AXI write handshake timeout at address 0x%0h", addr);
        end
    end

    // READY is registered in the DUT, so VALID must remain asserted through the
    // following rising edge for the transfer to complete.
    sample_cycle();

    @(negedge clk);
    s00_axi_awvalid = 1'b0;
    s00_axi_wvalid  = 1'b0;
    s00_axi_wstrb   = '0;

    timeout = 0;
    while (!s00_axi_bvalid) begin
        sample_cycle();
        timeout++;
        if (timeout > 50) begin
            $fatal(1, "AXI write response timeout at address 0x%0h", addr);
        end
    end
    expect_eq32($sformatf("BRESP for write 0x%0h", addr), {30'd0, s00_axi_bresp}, 32'd0);
end
endtask

task automatic axi_read(
    input logic [5:0] addr,
    output logic [31:0] data
);
    int timeout;
    bit ready_seen;
begin
    @(negedge clk);
    s00_axi_araddr  = addr;
    s00_axi_arvalid = 1'b1;

    timeout = 0;
    ready_seen = 1'b0;
    while (!ready_seen) begin
        sample_cycle();
        ready_seen = s00_axi_arready;
        timeout++;
        if (timeout > 50) begin
            $fatal(1, "AXI read address timeout at address 0x%0h", addr);
        end
    end

    sample_cycle();

    @(negedge clk);
    s00_axi_arvalid = 1'b0;

    timeout = 0;
    while (!s00_axi_rvalid) begin
        sample_cycle();
        timeout++;
        if (timeout > 50) begin
            $fatal(1, "AXI read data timeout at address 0x%0h", addr);
        end
    end

    data = s00_axi_rdata;
    expect_eq32($sformatf("RRESP for read 0x%0h", addr), {30'd0, s00_axi_rresp}, 32'd0);
end
endtask

task automatic read_expect(
    input logic [5:0] addr,
    input logic [31:0] expected,
    input string label
);
    logic [31:0] data;
begin
    axi_read(addr, data);
    expect_eq32(label, data, expected);
end
endtask

task automatic wait_for_sof;
begin
    do begin
        sample_cycle();
    end while (!dut.pulse_sof);
end
endtask

task automatic wait_for_ui_pulses(input int count);
    int seen;
begin
    seen = 0;
    while (seen < count) begin
        sample_cycle();
        if (dut.pulse_ui) begin
            seen++;
        end
    end
end
endtask

task automatic expect_no_sof_for_ui_pulses(
    input int count,
    input string label
);
    int seen;
    bit sof_seen;
begin
    seen = 0;
    sof_seen = 1'b0;
    while (seen < count) begin
        sample_cycle();
        if (dut.pulse_sof) begin
            sof_seen = 1'b1;
        end
        if (dut.pulse_ui) begin
            seen++;
        end
    end
    expect_true(label, !sof_seen);
end
endtask

task automatic capture_next_frame_counts(
    input int ch_idx,
    output int ui_pulses,
    output int high_ui_pulses
);
begin
    wait_for_sof();
    capture_frame_from_current_sof(ch_idx, ui_pulses, high_ui_pulses);
end
endtask

task automatic capture_frame_from_current_sof(
    input int ch_idx,
    output int ui_pulses,
    output int high_ui_pulses
);
begin
    ui_pulses      = dut.pulse_ui ? 1 : 0;
    high_ui_pulses = (dut.pulse_ui && (ch_pwm_pin[ch_idx] === 1'b1)) ? 1 : 0;

    while (1) begin
        sample_cycle();
        if (dut.pulse_sof) begin
            break;
        end
        if (dut.pulse_ui) begin
            ui_pulses++;
            if (ch_pwm_pin[ch_idx] === 1'b1) begin
                high_ui_pulses++;
            end
        end
    end
end
endtask

task automatic test_reset_defaults;
begin
    $display("TESTCASE: reset_defaults");
    read_expect(CTRL_ADDR,         32'h0000_0000, "CTRL reset value");
    read_expect(UI_TICKS_ADDR,     32'h0000_0000, "UI ticks reset value");
    read_expect(SOF_UI_TICKS_ADDR, 32'h0000_0000, "SOF UI ticks reset value");
    read_expect(CH0_UI_TICKS_ADDR, 32'h0000_0000, "CH0 reset value");
    read_expect(CH1_UI_TICKS_ADDR, 32'h0000_0000, "CH1 reset value");
    read_expect(CH2_UI_TICKS_ADDR, 32'h0000_0000, "CH2 reset value");
    read_expect(CH3_UI_TICKS_ADDR, 32'h0000_0000, "CH3 reset value");
    expect_true("All outputs tri-stated after reset", ch_pwm_pin === 4'bzzzz);
end
endtask

task automatic test_register_readback_and_wstrb;
begin
    $display("TESTCASE: register_readback_and_wstrb");

    axi_write(CTRL_ADDR,         32'h0000_00a0);
    axi_write(UI_TICKS_ADDR,     32'h1234_56aa, 4'b0001);
    axi_write(SOF_UI_TICKS_ADDR, 32'h1234_5678, 4'b0011);
    axi_write(CH0_UI_TICKS_ADDR, 32'hffff_f234);
    axi_write(CH1_UI_TICKS_ADDR, 32'h0000_0321);

    read_expect(CTRL_ADDR,         32'h0000_00a0, "CTRL readback with IO bits");
    read_expect(UI_TICKS_ADDR,     32'h0000_00aa, "UI ticks low-byte write");
    read_expect(SOF_UI_TICKS_ADDR, 32'h0000_5678, "SOF ticks low-halfword write");
    read_expect(CH0_UI_TICKS_ADDR, 32'h0000_0234, "CH0 width masked to 12 bits");
    read_expect(CH1_UI_TICKS_ADDR, 32'h0000_0321, "CH1 width readback");
end
endtask

task automatic test_single_channel_pwm;
    int ui_pulses;
    int high_ui_pulses;
begin
    $display("TESTCASE: single_channel_pwm");

    axi_write(UI_TICKS_ADDR,     32'd1);
    axi_write(SOF_UI_TICKS_ADDR, 32'd5);
    axi_write(CH0_UI_TICKS_ADDR, 32'd2);
    axi_write(CH1_UI_TICKS_ADDR, 32'd0);
    axi_write(CTRL_ADDR,         32'h0000_0001);

    capture_next_frame_counts(0, ui_pulses, high_ui_pulses);

    expect_eq_int("CH0 frame UI pulses", ui_pulses, 5);
    expect_eq_int("CH0 high UI pulses", high_ui_pulses, 2);
    expect_true("CH0 output is actively driven high or low in frame", ch_pwm_pin[0] !== 1'bz);
    expect_true("CH1 remains tri-stated while disabled", ch_pwm_pin[1] === 1'bz);

    wait_for_sof();
    read_expect(CTRL_ADDR, 32'h0001_0001, "CTRL active bit reflects enabled channel");
end
endtask

task automatic test_shadow_update_on_next_frame;
    int frame_ui_pulses;
    int high_ui_pulses;
begin
    $display("TESTCASE: shadow_update_on_next_frame");

    axi_write(UI_TICKS_ADDR,     32'd1);
    axi_write(SOF_UI_TICKS_ADDR, 32'd5);
    axi_write(CH0_UI_TICKS_ADDR, 32'd1);
    axi_write(CTRL_ADDR,         32'h0000_0001);

    capture_next_frame_counts(0, frame_ui_pulses, high_ui_pulses);
    expect_eq_int("Baseline frame UI pulses", frame_ui_pulses, 5);
    expect_eq_int("Baseline high UI pulses", high_ui_pulses, 1);

    wait_for_sof();
    fork
        begin
            wait_for_ui_pulses(1);
            axi_write(CH0_UI_TICKS_ADDR, 32'd4);
        end
        begin
            capture_frame_from_current_sof(0, frame_ui_pulses, high_ui_pulses);
        end
    join

    expect_eq_int("Updated value does not change current frame width", high_ui_pulses, 1);

    capture_next_frame_counts(0, frame_ui_pulses, high_ui_pulses);
    expect_eq_int("Updated value takes effect on next frame", high_ui_pulses, 4);
end
endtask

task automatic test_mid_frame_disable;
    int frame_ui_pulses;
    int high_ui_pulses;
begin
    $display("TESTCASE: mid_frame_disable");

    axi_write(UI_TICKS_ADDR,     32'd1);
    axi_write(SOF_UI_TICKS_ADDR, 32'd5);
    axi_write(CH0_UI_TICKS_ADDR, 32'd4);
    axi_write(CTRL_ADDR,         32'h0000_0001);

    wait_for_sof();
    fork
        begin
            wait_for_ui_pulses(1);
            axi_write(CTRL_ADDR, 32'h0000_0000);
        end
        begin
            capture_frame_from_current_sof(0, frame_ui_pulses, high_ui_pulses);
        end
    join

    expect_eq_int("Current frame completes after disable request", high_ui_pulses, 4);
    read_expect(CTRL_ADDR, 32'h0000_0000, "CTRL active bit clears after disable at frame boundary");
    expect_no_sof_for_ui_pulses(6, "No new frame starts after channel is disabled");
    expect_true("Disabled channel remains actively driven low when io_enb=0", ch_pwm_pin[0] === 1'b0);
end
endtask

task automatic test_mid_frame_enable;
    int frame_ui_pulses;
    int high_ui_pulses;
begin
    $display("TESTCASE: mid_frame_enable");

    axi_write(UI_TICKS_ADDR,     32'd1);
    axi_write(SOF_UI_TICKS_ADDR, 32'd5);
    axi_write(CH0_UI_TICKS_ADDR, 32'd3);
    axi_write(CTRL_ADDR,         32'h0000_0000);

    expect_no_sof_for_ui_pulses(3, "No frame starts while all channels are disabled");
    wait_for_ui_pulses(1);
    axi_write(CTRL_ADDR, 32'h0000_0001);

    capture_next_frame_counts(0, frame_ui_pulses, high_ui_pulses);
    expect_eq_int("Enabled channel starts on first frame after enable", high_ui_pulses, 3);
    expect_true("Enabled channel is driven when io_enb=0", ch_pwm_pin[0] !== 1'bz);

    wait_for_sof();
    read_expect(CTRL_ADDR, 32'h0001_0001, "CTRL active bit sets after enable");
end
endtask

task automatic test_io_enb_behavior;
    int frame_ui_pulses;
    int high_ui_pulses;
begin
    $display("TESTCASE: io_enb_behavior");

    axi_write(UI_TICKS_ADDR,     32'd1);
    axi_write(SOF_UI_TICKS_ADDR, 32'd5);
    axi_write(CH0_UI_TICKS_ADDR, 32'd3);
    axi_write(CTRL_ADDR,         32'h0000_0010);

    wait_for_sof();
    read_expect(CTRL_ADDR, 32'h0000_0010, "CTRL readback with io_enb set and channel disabled");
    wait_for_ui_pulses(1);
    expect_true("io_enb=1 tri-states disabled channel after frame boundary", ch_pwm_pin[0] === 1'bz);

    axi_write(CTRL_ADDR, 32'h0000_0011);

    capture_next_frame_counts(0, frame_ui_pulses, high_ui_pulses);
    expect_eq_int("Frame UI pulses unchanged with io_enb set", frame_ui_pulses, 5);
    expect_eq_int("Tri-stated output never drives a visible high", high_ui_pulses, 0);
    expect_true("io_enb=1 keeps enabled channel tri-stated", ch_pwm_pin[0] === 1'bz);

    wait_for_sof();
    read_expect(CTRL_ADDR, 32'h0001_0011, "CTRL active bit can assert while io_enb keeps output tri-stated");
end
endtask

initial begin
    clk = 1'b0;
    total_checks = 0;
    failed_checks = 0;

    apply_reset();

    test_reset_defaults();
    test_register_readback_and_wstrb();
    test_single_channel_pwm();
    test_shadow_update_on_next_frame();
    test_mid_frame_disable();
    test_mid_frame_enable();
    test_io_enb_behavior();

    repeat (5) @(posedge clk);

    if (failed_checks == 0) begin
        $display("TB PASS: %0d checks", total_checks);
    end else begin
        $fatal(1, "TB FAIL: %0d of %0d checks failed", failed_checks, total_checks);
    end

    $finish;
end

initial begin
    #(2_000_000);
    $fatal(1, "Simulation timeout");
end

endmodule
