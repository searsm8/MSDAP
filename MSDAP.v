
//EEDG 6306 Final Project
//MSDAP structural description
//Mark Sears and Seoha Lee

module MSDAP_top(
input sclk, 
input dclk, 
input start, 
input reset, 
input frame, 
input inputL, 
input inputR, 
output inReady, 
output outReady, 
output outputL, 
output outputR
);

wire [3:0] state;
wire input_en;
wire clear;
wire zero_detect_L, zero_detect_R;
wire [15:0] new_data_L, new_data_R;
wire compute_en_L, compute_en_R;
wire new_data_ready_L, new_data_ready_R;
wire input_read_L, input_read_R;
wire [2:0] done_L, done_R;
wire [1:0] op_L, op_R;
wire [15:0] next_data_L, next_data_R;
wire [39:0] result_L, result_R;

MSDAP_state_controller controller ( 
.sclk(sclk),
.dclk(dclk),
.start(start),
.reset(reset),
.frame(frame),
.done_L(done_L),
.done_R(done_R),
.zero_detect_L(zero_detect_L),
.zero_detect_R(zero_detect_R),
.input_en(input_en),
.clear(clear),
.inReady(inReady),
.outReady(outReady),
.state(state)
);

//modules for LEFT channel
MSDAP_S2P input_module_L (
.sclk(sclk),
.dclk(dclk),
.input_en(input_en),
.clear(clear),
.data_in(inputL),
.input_read(input_read_L),
.new_data(new_data_L),
.new_data_ready(new_data_ready_L),
.zero_detect(zero_detect_L)
);


MSDAP_data_manager data_manager_L(
.sclk(sclk),
.frame(frame),
.state(state),
.new_data(new_data_L),
.new_data_ready(new_data_ready_L),
.clear(clear),
.done(done_L),
.compute_en(compute_en_L),
.input_read(input_read_L),
.op(op_L),
.next_data(next_data_L)
);

MSDAP_ALU ALU_L (
.sclk(sclk),
.compute_en(compute_en_L),
.clear(clear),
.op(op_L),
.next_data(next_data_L),
.result(result_L)
);

MSDAP_P2S output_module_L (
.sclk(sclk),
.clear(clear),
.result(result_L),
.outReady(outReady),
.out_bit(outputL)
);


//modules for RIGHT channel
MSDAP_S2P input_module_R (
.sclk(sclk),
.dclk(dclk),
.input_en(input_en),
.clear(clear),
.data_in(inputR),
.input_read(input_read_R),
.new_data(new_data_R),
.new_data_ready(new_data_ready_R),
.zero_detect(zero_detect_R)
);

MSDAP_data_manager data_manager_R (
.sclk(sclk),
.frame(frame),
.state(state),
.new_data(new_data_R),
.new_data_ready(new_data_ready_R),
.clear(clear),
.done(done_R),
.compute_en(compute_en_R),
.input_read(input_read_R),
.op(op_R),
.next_data(next_data_R)
);

MSDAP_ALU ALU_R (
.sclk(sclk),
.compute_en(compute_en_R),
.clear(clear),
.op(op_R),
.next_data(next_data_R),
.result(result_R)
);

MSDAP_P2S output_module_R (
.sclk(sclk),
.clear(clear),
.result(result_R),
.outReady(outReady),
.out_bit(outputR)
);
  
endmodule //end MSDAP_top


module MSDAP_state_controller( 
  input sclk,
  input dclk,
  input start,
  input reset,
  input frame,
  input [2:0] done_L, //done[0] = rj_done, done[1] = coeff_done, done[2] = computation_done
  input [2:0] done_R,
  input zero_detect_L,
  input zero_detect_R,
  
  output input_en,
  output clear,
  output inReady,
  output outReady,
  output reg [3:0] state
);

parameter
INITIALIZE = 0,
WAIT_RJ = 1,
READ_RJ = 2,
WAIT_COEFF = 3,
READ_COEFF = 4,
WAIT_INPUT = 5,
WORKING = 6,
CLEARING = 15,
SLEEP = 8;

parameter SLEEP_TIME = 800; //number of all 0 inputs before going to sleep

wire [3:0] input_count;
wire [5:0] output_count;
wire [9:0] sleep_count;
wire [8:0] clear_count;
reg [3:0] next_state;
wire [2:0] done;
wire zero_detect;
wire detector_reset;

assign done = done_L & done_R;
assign zero_detect = zero_detect_L & zero_detect_R;

//Registers to control inReady, outReady, and I/O counters
DFF input_en_DFF (.clk(sclk), .reset(clear), .D((|input_count) | (frame & inReady)), .Q(input_en));
DFF outReady_DFF (.clk(frame), .reset(clear | output_count == 41), .D(done[2] & state == 6), .Q(outReady));
DFF inReady_DFF  (.clk(sclk), .reset(clear), .D(~(state == INITIALIZE | state == CLEARING)), .Q(inReady));
DFF reset_detector_DFF (.clk(sclk), .reset(detector_reset), .D(start|reset), .Q(clear));
DFF detector_reset_DFF (.clk(~sclk), .reset(~clear), .D(clear), .Q(detector_reset));
//DFF detector_reset_DFF (.clk(~sclk), .reset(1'b0), .D(clear), .Q(detector_reset));

counter#(4) input_counter (.clk(dclk), .reset(clear), .enable(input_en), .count(input_count));

counter#(6) output_counter (.clk(sclk), .reset(clear | ~outReady), .enable(outReady), .count(output_count));

counter#(10) sleep_counter (.clk(input_en), .reset(clear | ~zero_detect), .enable(state == WORKING), .count(sleep_count));

counter#(9) clear_counter (.clk(sclk), .reset(clear), .enable(state == INITIALIZE | state == CLEARING), .count(clear_count));

//STATE MACHINE
/*
always@(posedge start) next_state <= INITIALIZE;

always@(posedge reset) begin
  if(state == WORKING || state == SLEEP || state == CLEARING)
    next_state <= CLEARING; //async reset only in states 6, 7, or 8
end
*/

always@(posedge sclk) begin
    /*if(start) 
      state <= INITIALIZE;  
  else if(reset)// & (state == WORKING | state == SLEEP | state == CLEARING))
    state <= CLEARING; //async reset only in states 6, 7, or 8
  else  */
  state <= next_state;
end

always@(state or start or reset or clear_count or frame or done or sleep_count or zero_detect) begin
            
      if(start)
        next_state = INITIALIZE;  
    else if(reset & (state == WORKING || state == SLEEP || state == CLEARING))
        next_state = CLEARING; //async reset only in states 6, 7, or 8
    
else case(state)
    INITIALIZE: begin
      if(clear_count == 511)
        next_state = WAIT_RJ;
    else next_state = INITIALIZE;    
    end
    
    WAIT_RJ: begin      
      if(frame) 
        next_state = READ_RJ;
        else next_state = WAIT_RJ;
    end
    
    READ_RJ: begin
      if(done[0]) //rj_done
        next_state = WAIT_COEFF; 
        else next_state = READ_RJ;                
    end
    
    WAIT_COEFF: begin     
      if(frame) 
        next_state = READ_COEFF;
        else next_state = WAIT_COEFF;
    end
    
    READ_COEFF: begin    
      if(done[1]) //coeff_done
        next_state = WAIT_INPUT;
        else next_state = READ_COEFF;
    end
    
    WAIT_INPUT: begin
      if(frame) //if the frame is high, a new input is ready to be read in
        next_state = WORKING;
        else next_state = WAIT_INPUT;
    end
    
    WORKING: begin
      if(sleep_count == SLEEP_TIME)
            next_state = SLEEP;
            else next_state = WORKING;                                             
    end
    
    CLEARING: begin    
      if(clear_count == 255) 
        next_state = WAIT_INPUT;
        else next_state = CLEARING;      
    end
    
    SLEEP: begin 
      if(~zero_detect)
        next_state = WORKING;
        else next_state = SLEEP;
    end           
  endcase     
end
  
endmodule //end MSDAP_state_controller



//module MSDAP_S2P is used to shift in new data 1 bit at a time (LSB first)
module MSDAP_S2P
(
  input sclk,
  input dclk,
  input input_en,
  input clear,
  input data_in,
  input input_read,
  output [15:0] new_data,
  output new_data_ready,
  output zero_detect //true when a zero input is received
);
//wire new_data_reset;
wire input_complete;
//wire new_data_delay;
wire [15:0] input_data;

//generate 16 DFFs to implement a S2P shift register
genvar i;
for(i = 0; i < 16; i=i+1)
begin : S2P
  DFF flop ( .clk(dclk & input_en), .reset(clear), .D(i == 15 ? data_in : input_data[i+1]), .Q(input_data[i]) );
end

DFF input_complete_DFF( .clk(~input_en), .reset(clear | input_read), .D(1'b1), .Q(input_complete) );
//DFF new_data_delay_DFF( .clk(~dclk), .reset(clear | new_data_reset), .D(input_complete), .Q(new_data_delay) );
DFF new_data_ready_DFF( .clk(sclk), .reset(clear), .D(input_complete), .Q(new_data_ready) );
//DFF new_data_reset_DFF( .clk(sclk), .reset(clear), .D(new_data_ready), .Q(new_data_reset) );
DFF zero_detect_DFF ( .clk(~dclk), .reset(clear), .D(input_data == 16'b0), .Q(zero_detect) );
register#(16) new_input_register ( .clk(new_data_ready), .reset(clear), .D(input_data), .Q(new_data) );
endmodule //end MSDAP_input

//structural description of data manager
module MSDAP_data_manager
(
  input sclk,
  input frame,
  input [3:0] state,
  input [15:0] new_data,
  input new_data_ready,
  input clear,
  
  output [2:0] done,
  output compute_en,
  output input_read,
  output [1:0] op, //op: 00 = ADD, 01 = SUB, 10 = SHIFT
  output [15:0] next_data
);

parameter NUM_RJ = 16;
parameter NUM_COEFF = 512; //assumed maximum number of coefficients
parameter ORDER = 256; //the order of the filter

parameter
INITIALIZE = 0,
WAIT_RJ = 1,
READ_RJ = 2,
WAIT_COEFF = 3,
READ_COEFF = 4,
WAIT_INPUT = 5,
WORKING = 6,
CLEARING = 15,
SLEEP = 8;

wire [3:0] rj_addr;
wire [8:0] coeff_addr;
wire [7:0] data_addr;
wire [7:0] n; //counts how many data inputs are received
wire [7:0] coeffs_processed;

wire [7:0] next_rj;
wire [8:0] next_coeff;
wire input_received;
wire new_data_input_ready;
wire coeff_en;
wire shift;

assign new_data_input_ready = state == INITIALIZE | state == CLEARING | (new_data_ready & state == WORKING & ~compute_en);

//rj memory: 8 bit words, 4 addr bits, 16 locations
memory#(8, 4, NUM_RJ) rj_mem (
.clk(sclk),
.new_data( state == READ_RJ ? new_data[7:0] : 8'b0 ), //describes mux
.r_w( state == INITIALIZE | (new_data_ready & state == READ_RJ) ),
.addr(rj_addr),
.data_out(next_rj) 
);

//coeff memory: 9 bit words, 9 addr bits, 512 locations
memory#(9, 9, NUM_COEFF) coeff_mem (
.clk(sclk),
.new_data( state == READ_COEFF ? new_data[8:0] : 9'b0 ),
.r_w( state == INITIALIZE | (new_data_ready & state == READ_COEFF) ),
.addr(coeff_addr),
.data_out(next_coeff)
);

//data memory: 16 bit words, 8 addr bits, 256 locations
memory#(16, 8, ORDER) data_mem (
.clk(~sclk),
.new_data( state == WORKING ? new_data : 16'b0 ),
.r_w( new_data_input_ready ),
.addr(new_data_input_ready ? n : data_addr),
.data_out(next_data)
);

//create address counters for the memories
counter#(4) rj_addr_counter (
.clk(sclk),
.reset(clear),
.enable(state == INITIALIZE | (state == READ_RJ & new_data_ready) | (compute_en & shift)),
.count(rj_addr)
);
   
counter#(9) coeff_addr_counter (
.clk(sclk),
.reset(clear),
.enable(state == INITIALIZE | (state == READ_COEFF & new_data_ready) | coeff_en),
.count(coeff_addr)
);
                            
counter#(8) coeffs_processed_counter (
.clk(sclk),
.reset(clear | shift),
.enable(coeff_en),
.count(coeffs_processed)
);

counter#(8) n_counter (
.clk(sclk),
.reset(clear),
.enable((state == INITIALIZE | state == CLEARING) | (input_read & state == WORKING)),
.count(n)
);

//perform subtraction (n-k) to get the relative address "data_addr"
//adder#(8) addr_adder ( .a(n), .b(~next_coeff[7:0]), .cin(1'b0), .z(data_addr), .cout() );
adder#(8) addr_adder ( .a(n), .b(~next_coeff[7:0]), .cin(1'b0), .z(data_addr), .cout() );

DFF shift_op0_DFF   ( .clk(~sclk), .reset(clear), .D(next_coeff[8]), .Q(op[0]) );
DFF shift_op1_DFF   ( .clk(~sclk), .reset(clear), .D(coeffs_processed == next_rj-1), .Q(shift) );
DFF shift_op1_delay ( .clk(~sclk), .reset(clear), .D(shift), .Q(op[1]) );
DFF rj_done_DFF    ( .clk(state == READ_RJ & new_data_ready), .reset(clear & state == INITIALIZE), .D(rj_addr == NUM_RJ-1), .Q(done[0]) );
DFF coeff_done_DFF ( .clk(state == READ_COEFF & new_data_ready), .reset(clear & state == INITIALIZE), .D(coeff_addr == NUM_COEFF-1), .Q(done[1]) );
//DFF computation_done_DFF ( .clk(~compute_en), .reset(clear | state == 8), .D(1'b1), .Q(done[2]) );
DFF computation_done_DFF ( .clk(~compute_en), .reset(clear | state == SLEEP), .D(state == WORKING), .Q(done[2]) );
DFF input_read_DFF ( .clk(~sclk), .reset(clear), .D(new_data_input_ready | (new_data_ready & (state == READ_RJ | state == READ_COEFF))), .Q(input_read) );

//DFF input_received_DFF ( .clk(new_data_ready & state == 6), .reset(clear | state == 8), .D(1'b1), .Q(input_received) );
DFF input_received_DFF ( .clk(new_data_ready), .reset(clear | state == SLEEP), .D(state == WORKING), .Q(input_received) );
//DFF coeff_en_delay_DFF ( .clk(~sclk), .reset(clear), .D(state == 6 & ((coeff_en_delay & coeff_addr != 0) | frame) & input_received & ~new_data_ready), .Q(coeff_en_delay) );
//DFF coeff_en_DFF   ( .clk(~sclk), .reset(clear), .D((coeff_en_delay & ~new_data_ready) & (coeff_addr != 0 | frame)), .Q(coeff_en) );
DFF coeff_en_DFF   ( .clk(~sclk), .reset(clear), .D(state == WORKING & ((coeff_en & coeff_addr != 0) | frame) & input_received), .Q(coeff_en) );
DFF compute_en_DFF ( .clk(~sclk), .reset(clear), .D(coeff_en), .Q(compute_en) );

endmodule //MSDAP_data_manager

//memory storage for RJ, coeff, and input data
module memory #(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=8, parameter DEPTH=256)
(
input clk,
input [DATA_WIDTH-1:0] new_data,
input r_w, //0 = read, 1 = write
input [ADDR_WIDTH-1:0] addr,

output reg [DATA_WIDTH-1:0] data_out
);

reg [DATA_WIDTH-1:0] mem [DEPTH-1:0]; 

always@(posedge clk) begin
  if(r_w) //write
    mem[addr] <= new_data;
  else //read
    data_out <= mem[addr];

end
endmodule //memory


//arithmetic logic for convolution computation
module MSDAP_ALU(
input sclk,
input compute_en,
input clear,
input [1:0] op, //op: 00 = ADD, 01 = SUB, 10 = ADD & SHIFT, 11 = SUB & SHIFT
input [15:0] next_data, //the next piece of data to be processed
output [39:0] result
);

wire [14:0] xor_out;
wire sign_bit;
wire [39:0] sum_out;
wire [39:0] shift_out;
wire [39:0] accum_out;

assign xor_out = next_data ^ {15{op[0]}};
assign sign_bit = next_data[15] ^ op[0];
  
adder#(24) ALU_adder ( .a({ {9{sign_bit}}, xor_out }), .b(accum_out[39:16]), .cin(op[0]), .z(sum_out[39:16]), .cout() );

assign sum_out[15:0] = accum_out[15:0];

shifter_1b#(40) shifter ( .a(sum_out), .op(op[1]), .z(shift_out) ); //performs the shift when op[1] is true

register#(40) accumulator ( .clk(~sclk), .reset(clear), .D(shift_out & {40{compute_en}}), .Q(accum_out) );
register#(40) result_reg  ( .clk(~compute_en), .reset(clear), .D(accum_out), .Q(result) );

endmodule //end MSDAP_ALU


//module for sending output data serially on sclk (LSB first)
module MSDAP_P2S(
input sclk,
input clear,
input [39:0] result,
input outReady,
output out_bit
);

wire gated_clk;
wire load;
wire send_output;
DFF load_DFF (.clk(outReady), .reset(clear | send_output), .D(1'b1), .Q(load) );
DFF send_output_DFF (.clk(sclk), .reset(clear | ~outReady), .D(outReady), .Q(send_output) );
assign gated_clk = send_output & sclk; //only clock the P2S when loading or outputing

genvar i;
for(i = 0; i < 40; i=i+1)
begin : P2S
  wire dff_Q;
  wire mux_z;
  wire mux_a;
  
  if(i == 39) assign mux_a = 1'b0;
  else        assign mux_a = P2S[i+1].dff_Q;
  
  mux2 m (
  .a(mux_a),
  .b(result[i]),
  .sel(load),
  .z(mux_z)
  );
  
  DFF d (
  .clk(gated_clk),
  .reset(clear),
  .D(mux_z),
  .Q(dff_Q)
  );
end    
  assign out_bit = P2S[0].dff_Q;
endmodule //end MSDAP_P2S


//****LOW-LEVEL MODULES****

//variable length register with synchronous reset
module register #(parameter WIDTH = 1)
(
  input clk,
  input reset,
  input [WIDTH-1:0] D,
  
  output [WIDTH-1:0] Q
);
genvar i;
for(i = 0; i < WIDTH; i=i+1)
  DFF reg_dff ( .clk(clk), .reset(reset), .D(D[i]), .Q(Q[i]) );

endmodule //register

//D-flip flop with asynchronous reset
module DFF
(
  input clk,
  input reset,
  input D,
  output reg Q
);
always@(posedge clk, posedge reset) begin
  if(reset)
    Q <= 1'b0;
  else Q <= D;
end
endmodule //DFF

module shifter_1b #(parameter WIDTH = 1)
(
  input [WIDTH-1:0] a,
  input op,
  output [WIDTH-1:0] z
);
genvar i;
for(i = 0; i < WIDTH-1; i=i+1) //generate mux2's to implement the shift function
  mux2 shift_mux ( .a(a[i]), .b(a[i+1]), .sel(op), .z(z[i]) );
assign z[WIDTH-1] = a[WIDTH-1]; //always preserve the sign bit
endmodule //shifter_1b

module counter #(parameter WIDTH = 1)
(
  input clk,
  input reset,
  input enable,
  
  output [WIDTH-1:0] count 
);
genvar i;
for(i = 0; i < WIDTH; i=i+1) //create a series of DFFs that implements a n-bit counter
begin : count_flops
  wire flop_enable;
  if(i == 0)  assign flop_enable = enable; 
  else assign flop_enable = count_flops[i-1].flop_enable & count[i-1];
  
  DFF flop ( .clk(clk), .reset(reset), .D( flop_enable ^ count[i] ), .Q(count[i]) );
  
end
endmodule //counter

//2-input multiplexer
//if sel = 0, outputs a
//if sel = 1, outputs b
module mux2 (input a, input b, input sel, output z);
  assign z = ( sel ? b : a );  
endmodule //mux2

module FA (input a, input b, input cin, output z, output cout);
  assign z = a ^ b ^ cin;
  assign cout = (a&b) | (b&cin) | (a&cin);
endmodule //FA

module adder #(parameter WIDTH = 1)
(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  input cin,
  output [WIDTH-1:0] z,
  output cout  
);
wire carries [WIDTH:0];
assign carries[0] = cin;

genvar i;
for(i = 0; i < WIDTH; i=i+1)
  FA adder_FA ( .a(a[i]), .b(b[i]), .cin(carries[i]), .z(z[i]), .cout(carries[i+1]) );

assign cout = carries[WIDTH];
  
endmodule //adder