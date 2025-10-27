`timescale 1ns/1ns

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "project_configs.sv"
`include "otp_if.sv"
`include "top.v"
  `include "otp_sequence_item.sv"
  `include "otp_sequence.sv"
  `include "otp_sequencer.sv"
  `include "otp_driver.sv"
  `include "otp_active_monitor.sv"
  `include "otp_passive_monitor.sv"
  `include "otp_active_agent.sv"
  `include "otp_passive_agent.sv"
  `include "otp_scoreboard.sv"
  `include "otp_subscriber.sv"
  `include "otp_bind.sv"
  `include "otp_assertions.sv"
  `include "otp_environment.sv"
  `include "otp_test.sv"

module tb_top;
  bit clk,reset_n;

  always #10 clk = ~ clk; //50MHz clock

  initial begin
    clk = 1'b0;
    reset_n = 1'b1; 
    #10 reset_n = 1'b0; 
    #20 reset_n = 1'b1;
  end

  otp_if intf(clk, reset_n);

  //DUT instantiation
  top dut (
    .clk(clk),
    .reset_n(reset_n),
    .user_in(intf.user_in),
    .otp_latch(intf.otp_latch),
    .user_latch(intf.user_latch),
    .lfsr_out(intf.lfsr_out),
    .user_out(intf.user_out),
    .an(intf.an)
  );

  initial begin
    uvm_config_db#(virtual otp_if)::set(null,"uvm_test_top.env.active_agent.driver","vif",intf);
    uvm_config_db#(virtual otp_if)::set(null,"uvm_test_top.env.active_agent.monitor","vif",intf);
    uvm_config_db#(virtual otp_if)::set(null,"uvm_test_top.env.passive_agent.monitor","vif",intf);
    uvm_config_db#(virtual otp_if)::set(null,"uvm_test_top.env.scoreboard","vif",intf);
  end
  
  initial begin
    run_test();
    #100;
    $display("Simulation Finished");
    $finish;
  end
endmodule