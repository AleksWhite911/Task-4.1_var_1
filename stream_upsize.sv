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
  input  logic                    m_ready_i
);

logic [T_DATA_RATIO-1:0] push_data_for_fifo, fifo_full, counter_trn_reg, counter_trn, pointer, pop_data_for_fifo, fifo_empty;
logic [T_DATA_WIDTH-1:0] data_fifo [T_DATA_RATIO-1:0];
logic [T_DATA_RATIO-1:0] m_keep_o_logic;
logic trn_vld, push_keep, pop_keep, empty_keep, full_keep;

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


always_comb begin
  if (s_valid_i && s_ready_o)
    push_data_for_fifo = (1'b1 << pointer);

  if ((counter_trn_reg == T_DATA_RATIO) && ~s_last_i && ~full_keep)
    push_keep = 1'b1;
  else
    push_keep = '0;

  if (counter_trn_reg == T_DATA_RATIO)
    s_ready_o =   '0;
  else
    s_ready_o = 1'b1;

    
end

  // enum logic[2:0]
  //   {
  //      IDLE_VLD_DATA = 3'b000,
  //      TRANSFER_STATE = 3'b001
  //   }
  //   state, new_state;



  // always_comb
  //   begin
  //     new_state = state;

  //     case (state)
  //       IDLE_VLD_DATA:
  //       begin
  //         if (pointer )
  //        end
//        TRANSFER_STATE:
//        begin
//          s_ready_o = '0;   
//          //pop_data_for_fifo = m_keep_o;
//          m_valid_o = 1'b1;
//          new_state = IDLE_VLD_DATA;
//        end
// //       F0:   
// //         if (  a) new_state = S1;
// //         else     new_state = IDLE;
// //       S1:   
// //         if (~ a) new_state = S0;
// //             else     new_state = F1;
// //       S0:   if (  a) new_state = S1;
// //             else     new_state = IDLE;
//      endcase
//    end

//   // Output logic (depends only on the current state)
//   // assign detected = (state == S0);

    // State update
    // always_ff @ (posedge clk)
    //   if (~rst_n)
    //     state <= IDLE_VLD_DATA;
    //   else
    //     state <= new_state;


 always_ff @ (posedge clk) begin
    if (~rst_n) begin
      counter_trn_reg   <= 0;
      m_keep_o_logic    <= 0;
      pointer           <= 0;
    end else begin

      if (s_valid_i && ~s_last_i) begin
        if (counter_trn_reg < T_DATA_RATIO) begin
          counter_trn_reg <= counter_trn_reg + 1'b1;
          m_keep_o_logic <= m_keep_o_logic + push_data_for_fifo;
        end else begin
          counter_trn_reg <= 0;
          m_keep_o_logic  <= 0;
        end 
      end


      if (s_valid_i && s_ready_o && ~s_last_i) begin
        if (pointer < T_DATA_RATIO - 1)
          pointer <= pointer + 1;
        else
          pointer <= '0;
      end
    end
    // if (trn_vld)  
    //   m_keep_o_logic <= m_keep_o_logic | push_data_for_fifo;
    // else begin
    //   pop_data_for_fifo <= m_keep_o_logic;
    //   m_keep_o_logic <= '0;
    // end
end

endmodule