`timescale 1ns / 1ps
module testbench #(
  parameter T_DATA_WIDTH = 4,
  parameter T_DATA_RATIO = 2,
	parameter CLK_PERIOD  = 10
)();
	logic clk, rst_n, s_last_i, s_valid_i, m_ready_i;
	logic [T_DATA_WIDTH-1:0] s_data_i;
	wire s_ready_o, m_valid_o;
	wire [T_DATA_RATIO-1:0] push_data_for_fifo;
	wire [T_DATA_WIDTH-1:0] m_data_o [T_DATA_RATIO-1:0];

	stream_upsize DUT (
		.clk(clk), 
		.rst_n(rst_n), 
		.s_last_i(s_last_i), 
		.s_valid_i(s_valid_i), 
		.s_data_i(s_data_i), 
		.s_ready_o(s_ready_o), 
		.m_ready_i(m_ready_i),
		.push_data_for_fifo(push_data_for_fifo),
		.m_valid_o(m_valid_o),
		.m_data_o(m_data_o)
	);


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



	typedef struct {
		logic [T_DATA_WIDTH-1:0] data_1;
		logic [T_DATA_WIDTH-1:0] data_2;
	} packet;

	mailbox#(packet) in_mbx = new();
	mailbox#(packet) out_mbx = new();

	initial begin
		packet p;
		wait(~rst_n)
		forever begin
			@(posedge clk);
			if (s_valid_i && s_ready_o && (push_data_for_fifo == 1)) begin
				p.data_1 = s_data_i;
			end else if (s_valid_i && s_ready_o && (push_data_for_fifo == 2)) begin
				p.data_2 = s_data_i;
				in_mbx.put(p);
			end
		end
	end

	initial begin
		packet p;
		wait(~rst_n)
		forever begin
			@(posedge clk);
			if (m_valid_o & m_ready_i) begin
				p.data_1 = m_data_o[0];
				p.data_2 = m_data_o[1];
				out_mbx.put(p);
			end
		end
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


	initial begin
		packet in_p, out_p;
		forever begin
			in_mbx.get(in_p);
			out_mbx.get(out_p);
			if (in_p.data_1 !== out_p.data_1) begin
				$error("Invalid data: Real: %h, Expected: %h",
					out_p.data_1, in_p.data_1);
			end
			if (in_p.data_2 !== out_p.data_2) begin
				$error("Invalid data: Real: %h, Expected: %h",
					out_p.data_2, in_p.data_2);
			end
		end
	end


endmodule	