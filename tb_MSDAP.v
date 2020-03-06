//testbench for MSDAP
//Mark Sears and Seoha Lee
`timescale 1ns/1ps
`define EOF -1


module tb_MSDAP();
  
//parameter sclk_period = 1/0.02688; //system clock period = 1/26.88MHz = 37.2ns
parameter sclk_period = 40;
parameter dclk_period = 1302; //data clock period 1302ns = 768kHz

reg sclk;
reg dclk;
reg start;
reg reset;
reg frame;
reg inputL;
reg inputR;

wire inReady;
wire outReady;
wire outputL;
wire outputR;

//instantiate UUT
MSDAP_top uut_MSDAP(.sclk(sclk), .dclk(dclk), .start(start), .reset(reset), .frame(frame), .inputL(inputL), .inputR(inputR), .inReady(inReady), .outReady(outReady), .outputL(outputL), .outputR(outputR) );
//Chip uut_MSDAP(.sclk(sclk), .dclk(dclk), .start(start), .reset(reset), .frame(frame), .inputL(inputL), .inputR(inputR), .inReady(inReady), .outReady(outReady), .outputL(outputL), .outputR(outputR) );
integer i, j, data_file, output_file, first_char, cmds_on_line;
reg [5:0] out_index; //used to count in the 40 output bits
reg [3:0] send_index; //used to send out the 16 data bits
reg receive_output;

reg [15:0] new_L; //used to transmit input data
reg [15:0] new_R;

reg [39:0] new_out_L; //used to receive output data
reg [39:0] new_out_R;

reg [500:1] line; //line buffer for file reading

reg [100:1] comments [3:0]; //used to parse comments

initial 
begin

sclk = 1'b0;
dclk = 1'b0;
reset = 1'b0;
frame = 1'b0;
inputL = 1'b0;
inputR = 1'b0;
out_index = 1'b0;
new_L = 0;
new_R = 0;

start = 1'b0;
#50;
start = 1'b1;
#50;
start = 1'b0;

//open in/out files
//NOTE: ensure the file path is correct
data_file   = $fopen("./data/data2.in", "r");
output_file = $fopen("./data/output2.out", "w");

send_index = 0;

first_char = $fgetc(data_file); 

end //end initial


//give a new data bit on the falling data clock edge
always@(negedge dclk) begin

if(first_char != `EOF && inReady) begin //read until end of file
  
  if(send_index == 0) begin //if not already sending data, read the next line and set frame high
        
    while(first_char == "/") //skip comment lines
    begin
      $fgets(line, data_file);   
      first_char = $fgetc(data_file);
    end  
        
    $ungetc(first_char, data_file);    
    $fgets(line, data_file);    //take the next cmd line
    cmds_on_line = $sscanf(line, "%h %h %s %s %s %s", new_L, new_R, comments[0], comments[1], comments[2], comments[3]);
    first_char = $fgetc(data_file); //peek at next line
    if(first_char != `EOF)
      frame = 1'b1; //set frame high to indicate sending data bits
  end 
  
  if(send_index == 1) begin
    frame = 1'b0;
  end   
     
  if( cmds_on_line == 6 && comments[3] == "reset" && send_index == 5) begin //if 6 items are on the line, send reset on input 5               
        #3000; //arbitrary asynchronous timing for reset signal
        reset = 1'b1;
        #50;                
        reset = 1'b0;
  end
       
    //set the input lines to the next bit         
    inputL = new_L[send_index];
    inputR = new_R[send_index];       
    
end //end if(eof)
  
end //end always@(negedge dclk)

always@(posedge dclk)
begin
  if(inReady)
    send_index = send_index + 1;  
end

integer output_count = 0;
//when the MSDAP sends output, read it in and write it to file
always@(posedge sclk)
begin
  if(outReady & receive_output == 0) output_count = output_count+1;
  if(outReady)
    receive_output = 1'b1; //set flag to receive output
end

//receive the outputs on the negedge of sclk
always@(negedge sclk) 
begin
  if(receive_output) begin    
    if(outReady == 1'b0) begin
      out_index = 0;
      receive_output = 1'b0;
    end
    else begin    
    new_out_L[out_index] = outputL; //read the new output data bit
    new_out_R[out_index] = outputR;
        
    out_index = out_index+1;
    end
  end    
end

always@(negedge outReady) //after all 40 bits of the outputs are sent, write to file
begin
    out_index <= 0;
    receive_output <= 0;
    $fwrite(output_file, "%010X", new_out_L);
    $fwrite(output_file, "\t%010X\n", new_out_R);
end


always
begin
#(sclk_period/2); //system clock T = 37.2ns frequency = 26.88MHz
sclk = !sclk;
end

always
begin
#(dclk_period/2); //data clock 1302ns = 768kHz
dclk = !dclk;
end

endmodule