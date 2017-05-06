// 
// 
//
class alu_seq_item extends uvm_sequence_item;

rand logic [7:0] a,b;
rand logic ci;
rand logic [1:0] ctl;
logic rst,nopushin;
logic [7:0] z;
logic cout;
logic stopin;

  
`uvm_object_utils_begin(alu_seq_item)
  `uvm_field_int(z,UVM_ALL_ON)
  `uvm_field_int(cout,UVM_ALL_ON)
  `uvm_field_int(a,UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_field_int(b,UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_field_int(ci,UVM_ALL_ON|UVM_NOCOMPARE)
`uvm_object_utils_end

function new(string name = "alu_seq_item");
  super.new(name);
endfunction

function void do_copy(uvm_object rhs);
  alu_seq_item rhs_;

  if(!$cast(rhs_, rhs)) begin
    uvm_report_error("do_copy", "cast failed, check types");
  end
  a = rhs_.a;
  b = rhs_.b;
  ci = rhs_.ci;
  z = rhs_.z;
  ctl = rhs_.ctl;
  cout = rhs_.cout;
endfunction: do_copy

function bit do_compare(uvm_object rhs, uvm_comparer comparer);
  alu_seq_item rhs_;

  do_compare = $cast(rhs_, rhs) &&
               super.do_compare(rhs, comparer) &&
               a == rhs_.a &&
               b == rhs_.b &&
               ci == rhs_.ci &&
               z == rhs_.z &&
               ctl == rhs_.ctl &&
               cout == rhs_.cout ;
endfunction: do_compare

function string toStr();
  return $sformatf("a=%0d(%02h) b=%0d(%02h) ci=%0d ctl %d cout %d z %d", a,a,b,b,ci,ctl,cout,z);
endfunction: toStr

function void do_print(uvm_printer printer);

  if(printer.knobs.sprint == 0) begin
    $display(toStr());
  end
  else begin
    printer.m_string = toStr();
  end

endfunction: do_print

function void do_record(uvm_recorder recorder);
  super.do_record(recorder);

  `uvm_record_field("a", a);
  `uvm_record_field("b", b);
  `uvm_record_field("ci", ci);
  `uvm_record_field("z",z);
  `uvm_record_field("ctl",ctl);
  `uvm_record_field("cout",cout);

endfunction: do_record

endclass: alu_seq_item

//
// Sequence model
//

class alu_seq extends uvm_sequence #(alu_seq_item);

`uvm_object_utils(alu_seq)

// alu sequence_item
alu_seq_item req,req2;

// Controls the number of request sequence items sent
rand int no_reqs = 600;

function new(string name = "alu_seq");
  super.new(name);
endfunction

task body;
  string six;
  begin 
    req = alu_seq_item::type_id::create("req");
    req2 = alu_seq_item::type_id::create("req2");
    req.rst=1;
    req.nopushin=0;
    start_item(req);
    req.rst=1;
    req.nopushin=0;
    finish_item(req);
    repeat(no_reqs) begin
      start_item(req);
      req.randomize() with { ctl==1; a==~b; ci==1; };
//--------------------Adding Random test cases starts from here-----------------------------------------------
//    req.randomize() with { ctl==0; a==~b; ci==1; }; // Case 0, 6 fails
//    req.randomize() with { a==~b; ci==1; };         // Case 6 fails
//    req.randomize() with { a==67; b==97; ci==1; };
//    req.randomize() with { ctl==0; a==8'h43; b==8'h61; }; // Case 0,3,4,9
//    req.randomize() with { a<=8'h43; b<=8'h61; }; Case 6 fail
//    req.randomize() with { a>=8'h43; b>=8'h61; }; Case 6,9 fail
      req.rst=0;
      finish_item(req);
    end
    repeat(no_reqs) begin
      start_item(req);
      req.randomize() with { a==67; b==97; ci==1; };
      req.rst=0;
      finish_item(req);
    end
    repeat(no_reqs) begin
      start_item(req);
      req.randomize() with { a==~b; ci==1; };
      req.rst=0;
      finish_item(req);
    end
    repeat(3) begin
      start_item(req);
      req.nopushin=1;
      finish_item(req);
    end
    req.nopushin=0;
  end
endtask: body

endclass: alu_seq


class stopin_seq extends uvm_sequence #(alu_seq_item);

`uvm_object_utils(stopin_seq)

// alu sequence_item
alu_seq_item req,req2;

// Controls the number of request sequence items sent
rand int no_reqs = 600;

function new(string name = "stopin_seq");
  super.new(name);
endfunction

task body;
  string six;
  begin
    req = alu_seq_item::type_id::create("reqx");
    repeat(no_reqs) begin
      start_item(req);
      req.stopin=$urandom_range(0,20)>15; 
      req.rst=0;
      finish_item(req);
    end
  end
endtask: body

endclass: stopin_seq

//
//
//

class stopin_driver extends uvm_driver #(alu_seq_item);

`uvm_component_utils(stopin_driver)

alu_seq_item req;

virtual alu_if alu;

function new(string name = "alu_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual alu_if)::get(null, "uvm_test_top",
        "alu_if", this.alu)) begin
          `uvm_error("connect", "alu_if not found")
         end 
endfunction: connect_phase;

task run_phase(uvm_phase phase);
  alu.stopin <= 0;
  fork
  forever
    begin
      seq_item_port.get_next_item(req); // Gets the sequence_item
      alu.stopin = req.stopin;
      @(alu.clkb);
      #1;
      alu.stopin <= 0;
      seq_item_port.item_done();
    end
  join_none

endtask : run_phase

endclass : stopin_driver
//
// Simple Scoreboard
//
class alu_scoreboard extends uvm_scoreboard;

uvm_tlm_analysis_fifo #(alu_seq_item) ae_inp;

uvm_tlm_analysis_fifo #(alu_seq_item) ae_res;

alu_seq_item req,resp;
`uvm_component_utils(alu_scoreboard)

logic [8:0] resx;


function new(string name = "alu_scoreboard", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  begin
    ae_inp = new("ae_inp",this);
    ae_res = new("ae_res",this);
  end
endfunction : build_phase

task run_phase(uvm_phase phase);
  fork
    forever begin
      ae_inp.get(req);
//      `uvm_info("help",req.toStr(),UVM_LOW)
      ae_res.get(resp);
//      `uvm_info("helpr",resp.toStr(),UVM_LOW)
      case(req.ctl)
        0: resx = {1'b0,req.a};
        1: resx = req.a+req.b+{8'b0,req.ci};
        2: resx = req.a-req.b+{8'b0,req.ci};
        3: resx = req.a*req.b;
      endcase
      if(resx !== { resp.cout,resp.z } )begin
        `uvm_error("oops",$sformatf("e %h r %h",resx,{resp.cout,resp.z}))  
      end
    
    end
  join_none

endtask : run_phase

function void report_phase(uvm_phase phase);
 if(ae_inp.used() > 0) begin
    `uvm_error("oops","Not all data pushed out")
  end
endfunction : report_phase

endclass : alu_scoreboard

//
// Our monitor
//
class res_monitor extends uvm_monitor;

`uvm_component_utils(res_monitor)

uvm_analysis_port #(alu_seq_item) afx;
alu_seq_item req;

virtual alu_if ann;

function new(string name = "alu_monitor", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  begin
   afx = new("afr",this);
  end
endfunction : build_phase

function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual alu_if)::get(null, "uvm_test_top",
        "alu_if", this.ann)) begin
          `uvm_error("connect", "alu_if not found")
         end 
endfunction: connect_phase;

task run_phase(uvm_phase phase);
	begin
 	  fork 
            forever begin
 		@(posedge(ann.clk));
		if(ann.pushout && !ann.rst && !ann.stopin) begin
		  req = new();
		  req.cout = ann.cout;
		  req.z = ann.z;
		  afx.write(req);
		end
	    end
	  join_none
	end
endtask : run_phase

endclass : res_monitor

//
// Our monitor
//
class alu_monitor extends uvm_monitor;

`uvm_component_utils(alu_monitor)

uvm_analysis_port #(alu_seq_item) afx;
alu_seq_item req;

virtual alu_if ann;

function new(string name = "alu_monitor", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  begin
   afx = new("afx",this);
  end
endfunction : build_phase

function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual alu_if)::get(null, "uvm_test_top",
        "alu_if", this.ann)) begin
          `uvm_error("connect", "alu_if not found")
         end 
endfunction: connect_phase;

task run_phase(uvm_phase phase);
	begin
 	  fork 
            forever begin
 		@(posedge(ann.clk));
		if(ann.pushin && !ann.rst && !ann.stopout) begin
		  req = new();
		  req.a = ann.a;
		  req.b = ann.b;
		  req.ci = ann.ci;
		  req.ctl = ann.ctl;
		  afx.write(req);
		end
	    end
	  join_none
	end
endtask : run_phase

endclass : alu_monitor

//
//
//

class alu_driver extends uvm_driver #(alu_seq_item);

`uvm_component_utils(alu_driver)

alu_seq_item req;

virtual alu_if alu;

function new(string name = "alu_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual alu_if)::get(null, "uvm_test_top",
        "alu_if", this.alu)) begin
          `uvm_error("connect", "alu_if not found")
         end 
endfunction: connect_phase;

task run_phase(uvm_phase phase);
  alu.rst <= 0;
  alu.ctl <= 1;
  alu.pushin <= 0;
  alu.stopin <= 0;
  fork
  forever
    begin
      seq_item_port.get_next_item(req); // Gets the sequence_item
      if(req.rst) begin
        alu.rst <= 1;
        repeat(10) @(alu.clkb);
        #2;
        alu.rst <= 0;
      end else if(req.nopushin) begin
        alu.a <= req.a;
        alu.b <= req.b;
        alu.ci <= req.ci;
        alu.ctl <= req.ctl;
        alu.pushin <= 0;
        repeat(3) @(alu.clkb) #1;
      end else begin
        alu.a <= req.a;
        alu.b <= req.b;
        alu.ci <= req.ci;
        alu.ctl <= req.ctl;
        alu.pushin <= 1;
        @(alu.clkb);
        while(alu.stopout) @(alu.clkb);
        #1;
        alu.pushin <= 0;
      end
      seq_item_port.item_done();
    end
  join_none
endtask: run_phase

endclass: alu_driver


//
//
//


class alu_seqr extends uvm_sequencer #(alu_seq_item);
  `uvm_object_utils(alu_seqr)
  
  function new(string name="alu_seqr");
    super.new(name);
  endfunction : new

endclass : alu_seqr

class stopin_seqr extends uvm_sequencer #(alu_seq_item);
  `uvm_object_utils(stopin_seqr)
  
  function new(string name="stopin_seqr");
    super.new(name);
  endfunction : new

endclass : stopin_seqr



//
// The agent. Things happen here to hook things up
//


class agent1 extends uvm_agent;
  
  alu_driver driver1;
  stopin_driver stopdrive;
  alu_seq test_seq;
  alu_seqr seqr;
  stopin_seqr stopseqr;
  alu_monitor monitor;
  res_monitor resmon;
  alu_scoreboard scoreboard;
  stopin_seq stopseq;

  `uvm_component_utils_begin(agent1)
    `uvm_field_object(driver1,UVM_ALL_ON)
    `uvm_field_object(stopdrive,UVM_ALL_ON)
    `uvm_field_object(test_seq,UVM_ALL_ON)
    `uvm_field_object(seqr,UVM_ALL_ON)
    `uvm_field_object(stopseqr,UVM_ALL_ON)
    `uvm_field_object(monitor,UVM_ALL_ON)
    `uvm_field_object(resmon,UVM_ALL_ON)
  `uvm_component_utils_end

  function void build_phase(uvm_phase phase);
   begin
    super.build_phase(phase);
    test_seq = alu_seq::type_id::create("test_seq",this);
    seqr = alu_seqr::type_id::create("seqr",this);
    driver1 = alu_driver::type_id::create("alu_driver",this);
    stopdrive = stopin_driver::type_id::create("stop_driver",this);
    stopseqr = stopin_seqr::type_id::create("stop_seqr",this);
    monitor = alu_monitor::type_id::create("alu_monitor",this);
    resmon = res_monitor::type_id::create("alu_resmonitor",this);
    scoreboard = alu_scoreboard::type_id::create("alu_scoreboard",this);
    stopseq = stopin_seq::type_id::create("stopin_seq",this);
   end
   endfunction: build_phase;


  function void connect_phase(uvm_phase phase);
    driver1.seq_item_port.connect(seqr.seq_item_export);
    stopdrive.seq_item_port.connect(stopseqr.seq_item_export);
    monitor.afx.connect(scoreboard.ae_inp.analysis_export);
    resmon.afx.connect(scoreboard.ae_res.analysis_export);
  endfunction: connect_phase;
  task run_phase(uvm_phase phase);
    phase.raise_objection(this, "start of test");
    test_seq.start(seqr);
    fork
      test_seq.start(seqr);
      stopseq.start(stopseqr);
    join
    phase.drop_objection(this, "end of test");
  endtask: run_phase;

  function new(string name = "agent1", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  
endclass: agent1

//
// The environment
//

class env1 extends uvm_env;
  agent1 agnt;
  `uvm_component_utils_begin(env1)
    `uvm_field_object(agnt,UVM_ALL_ON)  
  `uvm_component_utils_end
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnt = agent1::type_id::create("agnt",this); 
  endfunction: build_phase;
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase;
  
  function new(string name="env1", uvm_component parent=null);
    super.new(name,parent);
  endfunction: new;
endclass : env1
 
// Test instantiates, builds and connects the driver and the sequencer
// then runs the sequence
//
class alu_test extends uvm_test;


env1 environ;
`uvm_component_utils_begin(alu_test)
  `uvm_field_object(environ,UVM_ALL_ON)
`uvm_component_utils_end
function new(string name = "alu_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  environ = env1::type_id::create("env1",this);
endfunction: build_phase


endclass: alu_test


