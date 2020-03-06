
//EEDG 6306 Final Project
//MSDAP structural description
//Mark Sears and Seoha Lee

module MSDAP_top_struct(
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
wire compute_en;
wire reset_regs;
wire reset_coeffs;
wire [15:0] new_data_L;
wire [15:0] new_data_R;

wire compute_en_L;
wire compute_en_R;
wire [1:0] op_L;
wire [1:0] op_R;
wire [15:0] data_word_L;
wire [15:0] data_word_R;
wire [39:0] answer_L;
wire [39:0] answer_R;

MSDAP_state_controller controller ( .sclk(sclk), .dclk(dclk), .start(start), .reset(reset), .frame(frame), .rj_done(rj_done), .coeff_done(coeff_done),
                                .input_en(input_en), .compute_en(compute_en), .reset_regs(reset_regs), .reset_coeffs(reset_coeffs), .inReady(inReady), .outReady(outReady), .state(state) );

//modules for LEFT channel
MSDAP_input input_module_L (.dclk(dclk), .input_en(input_en), .RST(reset_regs), .data_in(inputL), .new_data(new_data_L));

MSDAP_data_manager mem_L ( .sclk(sclk), .frame(frame), .state(state), .new_input(new_data_L), .new_input_ready(~input_en), .reset_regs(reset_regs), .reset_coeffs(reset_coeffs), 
                            .rj_done(rj_done), .coeff_done(coeff_done), .compute_en(compute_en_L), .op(op_L), .data_word(data_word_L) );

MSDAP_ALU compute_L (.sclk(sclk), .compute_en(compute_en_L), .RST(reset_regs), .op(op_L), .next_data(data_word_L), .computation_result(answer_L));

MSDAP_output output_module_L (.sclk(sclk), .RST(reset_regs), .computation_result(answer_L), .outReady(outReady), .out_bit(output_L));


//modules for RIGHT channel
MSDAP_input input_module_R (.dclk(dclk), .input_en(input_en), .RST(reset_regs), .data_in(inputR), .new_data(new_data_R));

MSDAP_data_manager mem_R ( .sclk(sclk), .frame(frame), .state(state), .new_input(new_data_R), .new_input_ready(~input_en), .reset_regs(reset_regs), .reset_coeffs(reset_coeffs), 
                            .rj_done(rj_done), .coeff_done(coeff_done), .compute_en(compute_en_R), .op(op_R), .data_word(data_word_R) );

MSDAP_ALU compute_R (.sclk(sclk), .compute_en(compute_en_R), .RST(reset_regs), .op(op_R), .next_data(data_word_R), .computation_result(answer_R));

MSDAP_output output_module_R (.sclk(sclk), .RST(reset_regs), .computation_result(answer_R), .outReady(outReady), .out_bit(output_R));
  
endmodule

module MSDAP_state_controller( 
  input sclk,
  input dclk,
  input start,
  input reset,
  input frame,
  input rj_done,
  input coeff_done,
  
  output reg input_en,
  output reg compute_en,
  output reg reset_regs,
  output reg reset_coeffs,
  output reg inReady,
  output reg outReady,
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
CLEARING = 7,
SLEEP = 8;

//reg [3:0] state;
reg [3:0] next_state;

reg [3:0] input_counter; //counts 16 input bits
reg [5:0] output_counter; //counts 40 input bits

always@(posedge start) state <= INITIALIZE;

always@(posedge sclk, posedge reset)begin
  if(reset && (state == WORKING || state == SLEEP || state == CLEARING))
    state <= CLEARING;
  else
    state <= next_state;
end

always@(posedge frame)begin
  input_en <= 1;
  input_counter <= 0;
  
  outReady <= 1;
  output_counter <= 0;
end

always@(posedge dclk)begin
  if(input_en) begin      
      if(input_counter == 15) //if done with 16 inputs
        input_en <= 0;
      input_counter <= input_counter + 1;
    end
end

always@(posedge sclk)begin
  if(outReady == 1)  begin
    if(output_counter == 39) //if done with 40 outputs    
      outReady <= 0;      
    output_counter <= output_counter + 1;
  end
end

always@(*)begin
  case(state)
    INITIALIZE: begin
      reset_regs <= 1;
      reset_coeffs <= 1;
      inReady <= 0;
      input_en <= 0;
      compute_en <= 0;
      
      next_state <= WAIT_RJ;
    end
    
    WAIT_RJ: begin    
      reset_regs <= 0;
      reset_coeffs <= 0;     
      inReady <= 1;      
      if(frame) 
        next_state <= READ_RJ;
    else next_state <= WAIT_RJ;
    end
    
    READ_RJ: begin      
      inReady <= 1'b1;
      if(rj_done)
        next_state <= WAIT_COEFF;                  
    end
    
    WAIT_COEFF: begin
      inReady <= 1'b1;      
      if(frame) 
        next_state <= READ_COEFF;
      else next_state <= WAIT_COEFF;
    end
    
    READ_COEFF: begin
      inReady <= 1'b1;
      if(coeff_done)
        next_state <= WAIT_INPUT;
    end
    
    WAIT_INPUT: begin
      inReady <= 1'b1;    
      if(frame) 
        next_state <= WORKING; //if the frame is high, a new input is ready to be read in                          
    end
    
    WORKING: begin      
      inReady <= 1'b1;
      compute_en <= 1'b1;                                         
    end
    
    CLEARING: begin
      inReady <= 1'b0;
      compute_en <= 1'b0;
      if(reset) next_state = CLEARING;
      else next_state = WAIT_INPUT;
    end
    
    SLEEP: begin      
      inReady <= 1;
      compute_en <= 1'b0;
      next_state = SLEEP;
    end               
  endcase 
end
  
endmodule //end MSDAP_state_controller



//module MSDAP_input is used to shift in new data 1 bit at a time (LSB first)
//and store in a 16-bit register
module MSDAP_input
(
  input dclk,
  input input_en,
  input RST,
  input data_in,  
  output [15:0] new_data
);

reg [15:0] shift_reg;
integer i;

always@(posedge RST)  shift_reg <= 0;

always@(posedge dclk)begin
  if(input_en)  begin
    for(i = 14; i >= 0; i=i-1)
      shift_reg[i] <= shift_reg[i+1];    
    shift_reg[15] <= data_in;
  end
end

assign new_data = shift_reg;    

endmodule //end MSDAP_input


//memory storage for RJ, coeff, and input data
//outputs previous data words in the order determined by the coefficients
module MSDAP_data_manager(
input sclk,
input frame,
input [3:0] state,
input [15:0] new_input,
input new_input_ready,
input reset_regs,
input reset_coeffs,

output reg rj_done,
output reg coeff_done,
output reg compute_en, //enables the computation
output reg [1:0] op, //op: 00 = ADD, 01 = SUB, 10 = SHIFT
output reg [15:0] data_word
);

parameter ORDER = 256; //the order of the filter
parameter NUM_COEFF = 512; //assumed maximum number of coefficients
integer i;

wire [7:0] target_addr;
reg [7:0] n; //points to the most recent input
reg [7:0] rj [15:0]; //all 16 RJ values (each 8-bits)
reg [8:0] coeff [NUM_COEFF-1:0]; //all 512 coeffs (each 9-bits)
reg [15:0] data [ORDER-1:0]; //memory for the most recent 256 inputs (each 16 bits)

reg [3:0] rj_addr;
reg [8:0] coeff_addr;
reg [7:0] data_addr;
reg [7:0] coeffs_processed; //used to count how many coeffs to process for a particular RJ

//reset registers (except RJs and coeffs)
always@(posedge reset_regs)begin
  for(i  = 0; i < ORDER; i=i+1)   
    data[i] <= 0; 
     
  n <= 0;  
  rj_addr <= 0;
  coeff_addr <= 0;
  data_addr <= 0;
  coeffs_processed <= 0;
  
  rj_done <= 0;
  coeff_done <= 0;
  compute_en <= 0;
  op <= 0;
  data_word <= 0;
end

//reset RJs and coeffs
always@(posedge reset_coeffs)begin
  for(i  = 0; i < 16; i=i+1)   
    rj[i] <= 0;
  for(i  = 0; i < NUM_COEFF; i=i+1)   
    coeff[i] <= 0;  
end


//whenever new inputs are ready, put it in the appropriate memory
always@(posedge new_input_ready)begin
  case(state)        
    2 : begin //READ_RJ
      rj[rj_addr] <= new_input;
      rj_addr <= rj_addr + 1;
      if(rj_addr == 15)
        rj_done <= 1;      
    end
        
    4 : begin //READ_COEFF
      coeff[coeff_addr] <= new_input;
      coeff_addr <= coeff_addr + 1;
      if(coeff_addr == NUM_COEFF-1)
        coeff_done <= 1; 
    end
        
    6 : begin //WORKING
      data[n] <= new_input;
      n <= n + 1;
    end      
  endcase
end //end always@(new_input_ready)


//always@(negedge sclk)begin end 
  
assign target_addr = n-1-coeff[coeff_addr];
//assign data_word   = data[target_addr];

always@(negedge sclk)begin
  if(frame && state == 6) begin
    compute_en <= 1;
  end  
end

//need to setup next data on posedge sclk
//because the computation occurs on negedge sclk,
always@(posedge sclk)begin
  
  data_word <= data[target_addr];
  
  if(compute_en) begin //if WORKING
    if(coeff_addr == 0 && ~frame)  //if done with computation      
        compute_en <= 0;
    else begin
    
      coeff_addr <= coeff_addr + 1;
        
      if(coeffs_processed == rj[rj_addr] - 1) begin //if done with this RJ
        coeffs_processed <= 0;
        rj_addr <= rj_addr + 1;             
      end    
      else     
        coeffs_processed <= coeffs_processed + 1;               
    end
        
    if(coeffs_processed == rj[rj_addr] - 1) //if the next coeff is the last, set SHIFT op
      op[1] <= 1; //set op to SHIFT
    else op[1] <= 0;
    
    op[0] <= coeff[coeff_addr][8]; //set op to ADD or SUB                  
  end     
end //end always@(posedge sclk)
endmodule //end MSDAP_memory



module MSDAP_ALU( //arithmetic logic for convolution computation
input sclk,
input compute_en,
input RST,
input [1:0] op, //op: 00 = ADD, 01 = SUB, 10 = SHIFT
input [15:0] next_data, //the next piece of data to be processed
output reg [39:0] computation_result
);

//wire [15:0] xor_data;
wire [15:0] twos_complement;
wire signed [39:0] next_sum;
reg signed [39:0] accumulator;

always@(posedge RST)  
  accumulator <= 0;

  //assign xor_data = next_data ^ {16{op[0]}};
  assign twos_complement = next_data ^ {16{op[0]}} + op[0];
  
  //perform ADD or SUB using combinational logic 
assign next_sum = accumulator + { {8{twos_complement[15]}}, twos_complement, {16{1'b0}} };
  
//perform computation on negedge sclk
always@(negedge sclk) begin
  if(compute_en)  begin        
    if(op[1] == 1'b0) //perform add    
      accumulator <= next_sum;          
    else if(op[1] == 1'b1) //perform add and shift    
      accumulator <= next_sum >>> 1;          
  end
end

always@(negedge compute_en) begin
  computation_result <= accumulator; // >>> 1; //perform last shift
  accumulator <= 0;
end
  
endmodule //end MSDAP_ALU


//module for sending output data serially on sclk (LSB first)
module MSDAP_output(
input sclk,
input RST,
input [39:0] computation_result,
input outReady,
output out_bit
);

reg [39:0] shift_reg;
integer i;

always@(posedge RST)  
  shift_reg <= 0;

always@(posedge outReady) 
  shift_reg <= computation_result;

always@(posedge sclk)begin
  if(outReady)  
    for(i = 0; i < 39; i=i+1)
      shift_reg[i] <= shift_reg[i+1];
  else shift_reg <= 0; 
end

assign out_bit = shift_reg[0];    
  
endmodule //end MSDAP_output


//variable length register with synchronous reset
module register #(parameter WIDTH = 1)
(
  input clk,
  input reset,
  input [WIDTH-1:0] D,
  
  output reg [WIDTH-1:0] Q
);
always@(posedge clk) begin
  if(reset)
    Q <= 0;
  else 
    Q <= D;
end
endmodule //register
