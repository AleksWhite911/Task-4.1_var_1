`timescale 1ns / 1ps
module testbench #(
  parameter T_DATA_WIDTH = 4,
  parameter T_DATA_RATIO = 2,
	parameter CLK_PERIOD  = 10
)();
	logic clk, rst_n, s_last_i, s_valid_i, m_ready_i;
	logic [T_DATA_WIDTH-1:0] s_data_i;
	wire s_ready_o;

	stream_upsize DUT (.clk(clk), .rst_n(rst_n), .s_last_i(s_last_i), .s_valid_i(s_valid_i), .s_data_i(s_data_i), .s_ready_o(s_ready_o), .m_ready_i(m_ready_i));
	initial begin
			wait(~rst_n)
			s_valid_i <= 0;
			s_data_i  <= 0;
			s_last_i  <= 0;
			wait(rst_n);
			repeat (1000) begin
				@(posedge clk);
				s_valid_i <= 1;
				s_data_i <= $urandom_range(0, T_DATA_WIDTH-1); 
				do begin
				 	@(posedge clk);
				end
				while(~s_ready_o);
				 	s_valid_i <= 0;
			end
			$stop();
		end






initial begin
	clk <= 0;
	forever begin
		#(CLK_PERIOD/2) clk <= ~clk;
	end
end
	
initial begin
	rst_n <= 0;
	#(CLK_PERIOD);
	rst_n <= 1;
	m_ready_i <= 1;
end

	initial
		$dumpvars;
endmodule	