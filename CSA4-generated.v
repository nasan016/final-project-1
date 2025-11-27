// 1-bit Full Adder
module FA(output sum, cout, input a, b, cin);
  wire w0, w1, w2;

  xor (w0, a, b);
  xor (sum, w0, cin);

  and (w1, w0, cin);
  and (w2, a, b);
  or  (cout, w1, w2);
endmodule


// 2-bit Ripple-Carry Adder using two FAs
module RCA2(output [1:0] sum, output cout,
            input  [1:0] a, b,
            input        cin);
  wire c1;

  // LSB
  FA fa0(
    .sum(sum[0]),
    .cout(c1),
    .a(a[0]),
    .b(b[0]),
    .cin(cin)
  );

  // MSB
  FA fa1(
    .sum(sum[1]),
    .cout(cout),
    .a(a[1]),
    .b(b[1]),
    .cin(c1)
  );
endmodule


// 1-bit 2:1 MUX
module MUX2to1_w1(output y, input i0, i1, s);
  wire sn, w0, w1;

  not (sn, s);
  and (w0, i0, sn);
  and (w1, i1, s);
  or  (y, w0, w1);
endmodule


// 2-bit 2:1 MUX (bitwise implementation)
module MUX2to1_w2(output [1:0] y,
                  input  [1:0] i0, i1,
                  input        s);
  wire sn;
  wire [1:0] w0, w1;

  not (sn, s);

  // Bit 0
  and (w0[0], i0[0], sn);
  and (w1[0], i1[0], s);
  or  (y[0],  w0[0], w1[0]);

  // Bit 1
  and (w0[1], i0[1], sn);
  and (w1[1], i1[1], s);
  or  (y[1],  w0[1], w1[1]);
endmodule


// 4-bit Carry-Select Adder (CSA4)
module CSA4(output [3:0] sum,
            output        cout,
            input  [3:0] a, b);

  // Lower 2-bit block wires
  wire [1:0] sum0_low, sum1_low;
  wire       cout0_0, cout0_1;
  wire       c1;          // selected carry out of lower block

  // Upper 2-bit block wires
  wire [1:0] sum0_high, sum1_high;
  wire       cout1_0, cout1_1;

  // ------------------------------------------------------------
  // Lower 2-bit block: carry-select structure, but select = 0
  // ------------------------------------------------------------

  // Precompute for cin = 0
  RCA2 rca_low_c0(
    .sum(sum0_low),
    .cout(cout0_0),
    .a(a[1:0]),
    .b(b[1:0]),
    .cin(1'b0)
  );

  // Precompute for cin = 1
  RCA2 rca_low_c1(
    .sum(sum1_low),
    .cout(cout0_1),
    .a(a[1:0]),
    .b(b[1:0]),
    .cin(1'b1)
  );

  // Select path (hard-wired s = 0, so this behaves like cin = 0)
  MUX2to1_w2 mux_low_sum(
    .y(sum[1:0]),
    .i0(sum0_low),
    .i1(sum1_low),
    .s(1'b0)
  );

  MUX2to1_w1 mux_low_carry(
    .y(c1),
    .i0(cout0_0),
    .i1(cout0_1),
    .s(1'b0)
  );

  // ------------------------------------------------------------
  // Upper 2-bit block: true carry-select using c1
  // ------------------------------------------------------------

  // Precompute for cin = 0
  RCA2 rca_high_c0(
    .sum(sum0_high),
    .cout(cout1_0),
    .a(a[3:2]),
    .b(b[3:2]),
    .cin(1'b0)
  );

  // Precompute for cin = 1
  RCA2 rca_high_c1(
    .sum(sum1_high),
    .cout(cout1_1),
    .a(a[3:2]),
    .b(b[3:2]),
    .cin(1'b1)
  );

  // Select based on carry out of lower block (c1)
  MUX2to1_w2 mux_high_sum(
    .y(sum[3:2]),
    .i0(sum0_high),
    .i1(sum1_high),
    .s(c1)
  );

  MUX2to1_w1 mux_high_carry(
    .y(cout),
    .i0(cout1_0),
    .i1(cout1_1),
    .s(c1)
  );

endmodule

