`timescale 1ns/1ps

module CSA4_tb;

  // ------------------------------------------------------------
  // DUT interface
  // ------------------------------------------------------------
  reg  [3:0] a;
  reg  [3:0] b;
  wire [3:0] sum;
  wire       cout;

  // Instantiate the DUT (golden CSA4)
  CSA4 dut (
    .sum(sum),
    .cout(cout),
    .a(a),
    .b(b)
  );

  // ------------------------------------------------------------
  // Internal signals (mapped to golden CSA4 internals)
  //
  // Golden CSA4 has:
  //   wire [3:0] sum0, sum1;
  //   wire       c1;
  //   wire       cout0_0, cout0_1;
  //   wire       cout1_0, cout1_1;
  //
  // We derive:
  //   lower block: sum0[1:0], sum1[1:0]
  //   upper block: sum0[3:2], sum1[3:2]
  // ------------------------------------------------------------
  wire [1:0] sum0_low   = dut.sum0[1:0];
  wire [1:0] sum1_low   = dut.sum1[1:0];
  wire       cout0_0    = dut.cout0_0;
  wire       cout0_1    = dut.cout0_1;
  wire       c1         = dut.c1;

  wire [1:0] sum0_high  = dut.sum0[3:2];
  wire [1:0] sum1_high  = dut.sum1[3:2];
  wire       cout1_0    = dut.cout1_0;
  wire       cout1_1    = dut.cout1_1;

  // ------------------------------------------------------------
  // Reference / expected values
  // ------------------------------------------------------------
  integer i, j;

  integer total_tests = 0;
  integer pass_count  = 0;
  integer fail_count  = 0;

  reg [4:0] expected_full;       // {carry, sum[3:0]} for a+b
  reg [2:0] expected_low_c0;     // {carry_low0, sum_low0[1:0]} for cin=0
  reg [2:0] expected_low_c1;     // {carry_low1, sum_low1[1:0]} for cin=1
  reg [2:0] expected_high_c0;    // {carry_high0, sum_high0[1:0]} for cin=0
  reg [2:0] expected_high_c1;    // {carry_high1, sum_high1[1:0]} for cin=1

  // ------------------------------------------------------------
  // Task: check one test vector (a,b)
  // ------------------------------------------------------------
  task check_vector;
    begin
      total_tests = total_tests + 1;

      // Expected overall result: a + b (no cin)
      expected_full = a + b;

      // Lower 2-bit block expectations:
      // cin = 0
      expected_low_c0 = {1'b0, a[1:0]} + {1'b0, b[1:0]} + 3'd0;
      // cin = 1
      expected_low_c1 = {1'b0, a[1:0]} + {1'b0, b[1:0]} + 3'd1;

      // Upper 2-bit block expectations:
      // cin = 0
      expected_high_c0 = {1'b0, a[3:2]} + {1'b0, b[3:2]} + 3'd0;
      // cin = 1
      expected_high_c1 = {1'b0, a[3:2]} + {1'b0, b[3:2]} + 3'd1;

      // --------------------------------------------------------
      // Primary output check: overall adder result
      // --------------------------------------------------------
      if ({cout, sum} !== expected_full) begin
        $display("FAIL (PRIMARY): a=%0d (0x%0h), b=%0d (0x%0h) | {cout,sum}=%b expected=%b",
                 a, a, b, b, {cout, sum}, expected_full);
        fail_count = fail_count + 1;
        $display("  INTERNAL (for debug): c1=%b sum0_low=%b sum1_low=%b sum0_high=%b sum1_high=%b",
                 c1, sum0_low, sum1_low, sum0_high, sum1_high);
      end else begin
        // ------------------------------------------------------
        // Internal signal checks
        // ------------------------------------------------------
        // Lower block: mux is hard-wired to s=0, so must select
        // cin=0 results:
        //   sum[1:0] == sum0_low
        //   c1       == cout0_0
        // And sum0_low/cout0_0 must match the cin=0 addition
        // sum1_low/cout0_1 must match the cin=1 addition
        // ------------------------------------------------------
        if ( sum0_low   !== expected_low_c0[1:0] ||
             cout0_0    !== expected_low_c0[2]   ||
             sum1_low   !== expected_low_c1[1:0] ||
             cout0_1    !== expected_low_c1[2]   ||
             sum[1:0]   !== sum0_low             ||  // mux select=0
             c1         !== cout0_0 ) begin
          $display("FAIL (LOW BLOCK INTERNAL): a=%0d (0x%0h), b=%0d (0x%0h)", a, a, b, b);
          $display("  expected_low_c0: carry=%b sum=%b  | actual: carry=%b sum0_low=%b",
                   expected_low_c0[2], expected_low_c0[1:0],
                   cout0_0, sum0_low);
          $display("  expected_low_c1: carry=%b sum=%b  | actual: carry=%b sum1_low=%b",
                   expected_low_c1[2], expected_low_c1[1:0],
                   cout0_1, sum1_low);
          $display("  c1=%b, sum[1:0]=%b (should equal sum0_low)", c1, sum[1:0]);
          fail_count = fail_count + 1;
        end else begin
          // ----------------------------------------------------
          // Upper block: true carry-select on c1
          // We always precompute cin=0 and cin=1:
          //   sum0_high/cout1_0 -> cin=0 path
          //   sum1_high/cout1_1 -> cin=1 path
          //
          // They must match the expected high-block additions,
          // and the mux must select based on c1.
          // ----------------------------------------------------
          if ( sum0_high  !== expected_high_c0[1:0] ||
               cout1_0    !== expected_high_c0[2]   ||
               sum1_high  !== expected_high_c1[1:0] ||
               cout1_1    !== expected_high_c1[2] ) begin
            $display("FAIL (HIGH BLOCK PRECOMP): a=%0d (0x%0h), b=%0d (0x%0h)", a, a, b, b);
            $display("  expected_high_c0: carry=%b sum=%b  | actual: carry=%b sum0_high=%b",
                     expected_high_c0[2], expected_high_c0[1:0],
                     cout1_0, sum0_high);
            $display("  expected_high_c1: carry=%b sum=%b  | actual: carry=%b sum1_high=%b",
                     cout1_1, sum1_high,   // note: just diagnostics
                     sum1_high);
            fail_count = fail_count + 1;
          end else begin
            // Check mux selection behavior
            if (c1 == 1'b0) begin
              if ( sum[3:2] !== sum0_high || cout !== cout1_0 ) begin
                $display("FAIL (HIGH MUX, c1=0): a=%0d (0x%0h), b=%0d (0x%0h)", a, a, b, b);
                $display("  c1=0: expected sum[3:2]=%b cout=%b | actual sum[3:2]=%b cout=%b",
                         sum0_high, cout1_0, sum[3:2], cout);
                fail_count = fail_count + 1;
              end else begin
                pass_count = pass_count + 1;
              end
            end else begin
              if ( sum[3:2] !== sum1_high || cout !== cout1_1 ) begin
                $display("FAIL (HIGH MUX, c1=1): a=%0d (0x%0h), b=%0d (0x%0h)", a, a, b, b);
                $display("  c1=1: expected sum[3:2]=%b cout=%b | actual sum[3:2]=%b cout=%b",
                         sum1_high, cout1_1, sum[3:2], cout);
                fail_count = fail_count + 1;
              end else begin
                pass_count = pass_count + 1;
              end
            end
          end
        end
      end

      // Optional verbose trace:
      // $display("TRACE: a=%0d b=%0d | sum=%b cout=%b | c1=%b | sum0=%b sum1=%b",
      //          a, b, sum, cout, c1, dut.sum0, dut.sum1);
    end
  endtask

  // ------------------------------------------------------------
  // Main stimulus process
  // ------------------------------------------------------------
  initial begin
    $display("Starting CSA4 testbench (golden CSA4)...");

    // Sweep all 4-bit combinations of a and b (256 tests)
    for (i = 0; i < 16; i = i + 1) begin
      for (j = 0; j < 16; j = j + 1) begin
        a = i[3:0];
        b = j[3:0];
        #1;          // allow signals to propagate
        check_vector();
      end
    end

    // Summary
    $display("--------------------------------------------------");
    $display("CSA4 TESTBENCH SUMMARY");
    $display("  Total tests : %0d", total_tests);
    $display("  Pass count  : %0d", pass_count);
    $display("  Fail count  : %0d", fail_count);
    if (fail_count == 0)
      $display("  RESULT      : PASS (all tests)");
    else
      $display("  RESULT      : FAIL (see messages above)");
    $display("--------------------------------------------------");

    $finish;
  end

endmodule

