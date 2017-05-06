
interface alu_if;

logic clk;
logic rst;
logic [7:0] a,b;
logic ci;
logic pushin;
logic stopout;
logic [7:0] z;
logic cout;
logic pushout;
logic stopin;
logic [1:0] ctl;
  
  clocking clkb @(posedge clk);
    inout a,b,ci,clk;
    inout z,cout;
  endclocking
  
  modport mon_mp (clocking clkb);
  
  modport dut_mp (input clk, input rst, input pushin, output stopout, input a, input b, input ci, output z, output cout,output pushout, input stopin,input ctl);

endinterface: alu_if

