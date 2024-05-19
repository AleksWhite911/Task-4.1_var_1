module stream_upsize #(
  parameter T_DATA_WIDTH = 4,
  parameter T_DATA_RATIO = 2
)(
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic [T_DATA_WIDTH-1:0] s_data_i,
  input  logic                    s_last_i,
  input  logic                    s_valid_i,
  output logic                    s_ready_o,
  output logic [T_DATA_WIDTH-1:0] m_data_o [T_DATA_RATIO-1:0],
  output logic [T_DATA_RATIO-1:0] m_keep_o,
  output logic                    m_last_o,
  output logic                    m_valid_o,
  input  logic                    m_ready_i,
  output logic [T_DATA_RATIO-1:0] push_data_for_fifo // for testbench
);

logic [T_DATA_RATIO-1:0] fifo_full, counter_trn_reg, counter_trn, pointer, pop_data_for_fifo, fifo_empty;
logic [T_DATA_WIDTH-1:0] data_fifo [T_DATA_RATIO-1:0];
logic [T_DATA_RATIO-1:0] m_keep_o_logic;
logic trn_vld, push_keep, pop_keep, empty_keep, full_keep, overflow, overflow_ptr;

//Implement FIFO modules for save data
generate
for(genvar i = 0; i < T_DATA_RATIO; i++) begin : flip_flop_fifo
  flip_flop_fifo #(T_DATA_WIDTH, 10) flip_flop_fifo (
    .clk(clk),
    .rst(~rst_n),
    .push(push_data_for_fifo[i]),
    .pop(pop_data_for_fifo[i]),
    .write_data(s_data_i),
    .read_data(data_fifo[i]),
    .empty(fifo_empty[i]),
    .full(fifo_full[i])
  );
end



for(genvar fifo_idx = 0; fifo_idx < T_DATA_RATIO; fifo_idx++) begin : fifo_matrix
  assign m_data_o[fifo_idx] = data_fifo[fifo_idx];
end
endgenerate

  flip_flop_fifo #(T_DATA_RATIO, 10) m_keep_fifo (
    .clk(clk),
    .rst(~rst_n),
    .push(push_keep),
    .pop(pop_keep),
    .write_data(m_keep_o_logic),
    .read_data(m_keep_o),
    .empty(empty_keep),
    .full(full_keep)  
  );

always_comb
  if (s_valid_i && s_ready_o) begin
    push_data_for_fifo = pointer;
  end else begin
    push_data_for_fifo = '0;
  end

always_comb
    if (m_ready_i && ~empty_keep) begin
      pop_keep = 1'b1;
      m_valid_o = 1'b1;
      pop_data_for_fifo = m_keep_o;
    end else begin
      pop_keep = '0;
      m_valid_o = '0;
      pop_data_for_fifo = '0;
    end    

always_comb begin
  if ((counter_trn_reg == T_DATA_RATIO) && ~s_last_i && ~full_keep) begin
    push_keep = 1'b1;
    s_ready_o =   '0;
    overflow =  1'b1;
  end else if (s_last_i && ~full_keep) begin
    push_keep = 1'b1;
    s_ready_o =   '0;
    overflow =  1'b1;
  end else begin
    push_keep =   '0;
    s_ready_o = 1'b1;
    overflow  =   '0;
  end
  // if ((counter_trn_reg == T_DATA_RATIO) || fifo_full) begin
  //   s_ready_o =   '0;
  //   overflow = 1'b1;
  // end else begin
  //   s_ready_o = 1'b1;
  //   overflow  =   '0;
  // end

  if ((pointer == T_DATA_RATIO) || s_last_i)
    overflow_ptr = 1'b1;
  else
    overflow_ptr = '0;
end

 always_ff @ (posedge clk) begin
    if (~rst_n) begin
      counter_trn_reg   <= 0;
      m_keep_o_logic    <= 0;
      pointer           <= 1;
    end else begin

      if (s_valid_i && ~s_last_i && ~overflow && s_ready_o) begin
        counter_trn_reg <= counter_trn_reg + 1'b1;
        m_keep_o_logic  <= m_keep_o_logic + push_data_for_fifo;
      end else if (overflow) begin
        counter_trn_reg <= 0;
        m_keep_o_logic  <= 0;
      end 

      if (s_valid_i && s_ready_o && ~s_last_i && ~overflow_ptr)
        pointer <= pointer * 2;
      else if (overflow_ptr && s_valid_i && s_ready_o && ~s_last_i)
        pointer <= 1;
    end
end

endmodule