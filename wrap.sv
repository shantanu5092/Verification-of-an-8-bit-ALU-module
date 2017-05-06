//
// This is a simple wrapper to map the interface to the DUT.
// This also is a good place to put assertions and covergroups
//

module wrap(alu_if.dut_mp q);


alu9 a(q.clk,q.rst,q.pushin,q.stopout,
    q.ctl,q.a,q.b,q.ci,q.pushout,q.cout,q.z,q.stopin);


endmodule
