module Chip(Sclk, Dclk, Start, Reset_n, Frame, InputL, InputR, InReady, OutReady, OutputL, OutputR );
	input Sclk;
	input Dclk;
	input Start;
	input Reset_n;
	input Frame;
	input InputL;
	input InputR;
	output InReady;
	output OutReady;
	output OutputL;
	output OutputR;

	wire Sclk_s;
	wire Dclk_s;
	wire Start_s;
	wire Reset_n_s;
	wire Frame_s;
	wire InputL_s;
	wire InputR_s;
	wire InReady_s;
	wire OutReady_s;
	wire OutputL_s;
	wire OutputR_s;	
	
	MSDAP P_MSDAP(Sclk_s, Dclk_s, Start_s, Reset_n_s, Frame_s, InputL_s, InputR_s, InReady_s,OutReady_s, OutputL_s, OutputR_s );
	
	PB2 Sclk_PB (.PAD(Sclk),.OEN(1'b1),.C(Sclk_s));
	PB2 Dclk_PB (.PAD(Dclk),.OEN(1'b1),.C(Dclk_s));
	PB2 Start_PB (.PAD(Start),.OEN(1'b1),.C(Start_s));
	PB2 Reset_n_PB (.PAD(Reset_n),.OEN(1'b1),.C(Reset_n_s));
	PB2 Frame_PB (.PAD(Frame),.OEN(1'b1),.C(Frame_s));
	PB2 InputL_PB (.PAD(InputL),.OEN(1'b1),.C(InputL_s));
	PB2 InputR_PB (.PAD(InputR),.OEN(1'b1),.C(InputR_s));
	PB2 InReady_PB (.PAD(InReady),.OEN(1'b0),.I(InReady_s));
	PB2 OutReady_PB (.PAD(OutReady),.OEN(1'b0),.I(OutReady_s));
	PB2 OutputL_PB (.PAD(OutputL),.OEN(1'b0),.I(OutputL_s));
	PB2 OutputR_PB (.PAD(OutputR),.OEN(1'b0),.I(OutputR_s));
endmodule