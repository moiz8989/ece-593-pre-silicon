//v5
module ats21_rm(input logic clk,reset,req, input logic [15:0]ctrlA,ctrlB, output logic ready, output logic stat[2], output logic data[24]);
// meaning: control register
  logic [7:0] CR_bits;
//logic [15:0] base_clk [16];
  logic [15:0] base_clk[16];
  logic [15:0] alarm_timer[24];
  // meaning:
logic clk_en[16];
logic clk_half, clk_quarter, clk_selA, clk_selB;
logic at_en[24];
	
	
	logic [1:0] rateA, rateB;
//bit [31:0] CA_clk,CA_clk_en,CA_at,CA_at_en;
//bit [31:0] CB_clk,CB_clk_en,CB_at,CB_at_en;
//int i,j;

//////////////////////////////load logic start////////////////////////////////////////////////  
bit load_upper;
bit [31:0] ctrlA_32bits,ctrlB_32bits;

	
//////////////////////////////load logic end////////////////////////////////////////////////  

///////////////////////////// reset logic start////////////////////////////////////////////
always_ff@(posedge clk)
begin
  if(reset)
	begin
	  ready   <= 1'b0;
	  CR_bits <= '0;
	  stat    <= '0;
	  data    <= '0;
          foreach(base_clk[i])
	    base_clk[i] <= '0;
	  foreach(alarm_timer[i]) //-----?
	    alarm_timer[i] <= '0; //-----?
	  rateA <= '0;
	  rateB <= '0;
	end
  else
	ready <= ready; //TODO: ready == 1 always if not reset???
	CR_bits <= CR_bits;
	stat    <= stat;
	data    <= data;
        foreach(base_clk[i])
	   base_clk[i] <= base_clk[i];
	foreach(alarm_timer[i]) //-----?
	   alarm_timer[i] <= alarm_timer[i]; //-----?
	rateA <= rateA;
	rateB <= rateB;
end
///////////////////////////// reset logic end////////////////////////////////////////////

// opcode logic
always@(posedge clk)
	if (!load_upper && req && ready) begin
	ctrlA_32bits[31:16] <= ctrlA;
	ctrlB_32bits[31:16] <= ctrlB;
  end
	else if(load_upper && req && ready) begin
        ctrlA_32bits[15:0] <= ctrlA;
        ctrlB_32bits[15:0] <= ctrlB;
end
else begin
  ctrlA_32bits <= ctrlA_32bits;
  ctrlB_32bits <= ctrlB_32bits;	
end
	
// status logic
always_ff@(posedge clk) begin
	if(req && ctrlA) stat[0] <= 1'b1;
	else stat[0] <= 1'b0;
	if(req && ctrlB) stat[1] <= 1'b1;
	else stat[1] <= 1'b0;
end

// rate logic
always_ff@(posedge clk) 
	clk_half <= clk;
always_ff@(posedge clk_half)
	clk_quarter <= clk_half;

// clock select
// rate A
always_comb begin
	if(rateA == 0)        clk_selA = clk;
	else if(rateA == 1)   clk_selA = clk_half;
	else if(rateA == 2)   clk_selA = clk_quarter;
	else                  clk_selA = clk;	
end
// rate B	
always_comb begin
	if(rateB == 0)        clk_selA = clk;
	else if(rateB == 1)   clk_selA = clk_half;
	else if(rateB == 2)   clk_selA = clk_quarter;
	else                  clk_selA = clk;	
end
		
	
typedef enum bit[2:0] {
  nop     = 3'b000,
  set_clk = 3'b001,
  clk_en  = 3'b010,
  set_mode = 3'b011,
  set_alarm = 3'b101,
  set_timer = 3'b110,
  at_en = 3'b111
} opcode_t;

opcode_t op_A,op_B;

always_comb
begin
  fork
  case(ctrlA_32bits[31:29])
	3'b000: op_A = no_op;// -----
	3'b001: op_A = set_clk;
	3'b010: op_A = clk_ed;
	3'b011: op_A = set_mode;// -----
	3'b101: op_A = set_alarm;
	3'b110: op_A = set_timer;
	3'b111: op_A = at_ed;
  endcase
  case(ctrlB_32bits[31:29])
	3'b000: op_B = no_op; //-----
	3'b001: op_B = set_clk;
	3'b010: op_B = clk_ed;
	3'b011: op_B = set_mode; //-----
	3'b101: op_B = set_alarm;
	3'b110: op_B = set_timer;
	3'b111: op_B = at_ed;
  endcase
  join
end



always_ff@(posedge clk)
begin 
    case(ctrlA_32bits[31:29])
	    no_op:   
	        begin
		     //do nothing
	        end
	    set_clk: 
	        begin
		        if(ctrlA_32bits[23:22] == 2'b00 && clk_en[ctrlA_32bits[28:25]]==1'b1 )
		            begin
                                         base_clk <= ctrlA_32bits[15:0];
                      $display("vlaue ofvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv clk =%d",base_clk);
			         /*forever
			         @(posedge clk)
			         //base_clk[ctrlA_32bits[28:25]]++;
                     base_clk[ctrlA_32bits[28:25]]++;*/
                      
		            end
		        else if(ctrlA_32bits[23:22] == 2'b01 && clk_en[ctrlA_32bits[28:25]]==1'b1 )
		            begin
			         forever
			         repeat(2) @(posedge clk);
			         base_clk[ctrlA_32bits[28:25]]++;
		            end
		        else if(ctrlA_32bits[23:22] == 2'b10 && clk_en[ctrlA_32bits[28:25]]==1'b1 )
		            begin
			         forever
			         repeat(4) @(posedge clk);
			         base_clk[ctrlA_32bits[28:25]]++;
		            end
	        end
	    clk_ed : 
	        begin
		        if(ctrlA_32bits[23] == 1'b0) //0-disable
		         clk_en[ctrlA_32bits[28:25]]=1'b0;
		        else
		         clk_en[ctrlA_32bits[28:25]]=1'b1;// enable
	        end
	    set_mode:
	        begin
			CR_bits <= {3'b000, ctrlA_32bits[28:24]};
	        end
	    set_alarm:
	        begin
		        if(at_en[ctrlA_32bits[28:24]]==1'b1)//if enable
		            begin
			         alarm_timer[ctrlA_32bits[28:24]] <= ctrlA_32bits[15:0];
			            if(ctrlA_32bits[23]==1'b1)//REPEAT
			                begin	
				             forever
				                if(alarm_timer[ctrlA_32bits[28:24]] == base_clk[ctrlA_32bits[19:16]])  
					                begin
					                 data[ctrlA_32bits[28:24]]=1'b1;
					                 repeat(2)
						             @(posedge clk);
					                 data[ctrlA_32bits[28:24]]=1'b0;
					                end
				                else
				                    data[ctrlA_32bits[28:24]]=1'b0;
			                end
			            else if(ctrlA_32bits[23]==1'b0)//NO REPEAT
			                begin
				                if(alarm_timer[ctrlA_32bits[28:24]] == base_clk[ctrlA_32bits[19:16]])                          
				                 data[ctrlA_32bits[28:24]]=1'b1;
				                 repeat(2)
				                 @(posedge clk);
				                 data[ctrlA_32bits[28:24]]=1'b0;  
			                end
		            end
		        else if(at_en[ctrlA_32bits[28:24]]==1'b0)//if disable
		         data[ctrlA_32bits[28:24]]=1'b0;
		        else
		            begin
			         alarm_timer[ctrlA_32bits[28:24]] <= ctrlA_32bits[15:0];
			            if(ctrlA_32bits[23]==1'b1)//repeat			          
			                begin
				             forever
				                if(alarm_timer[ctrlA_32bits[28:24]] == base_clk[ctrlA_32bits[19:16]])
					                begin
					                 data[ctrlA_32bits[28:24]]=1'b1;
					                 repeat(2)
						             @(posedge clk);
					                 data[ctrlA_32bits[28:24]]=1'b0;
					                end
				                else
				                 data[ctrlA_32bits[28:24]]=1'b0;
			                end
			            else if(ctrlA_32bits[23]==1'b0)//no repeat
			                begin
				                if(alarm_timer[ctrlA_32bits[28:24]] == base_clk[ctrlA_32bits[19:16]])
				                    begin
					                 data[ctrlA_32bits[28:24]]=1'b1;
					                 repeat(2)
					                 @(posedge clk);
					                 data[ctrlA_32bits[28:24]]=1'b0;  
				                    end
			                end
		            end
	        end
        set_timer: 
		    begin
	         alarm_timer[ctrlA_32bits[28:24]] <= ctrlA_32bits[15:0]; 
	         for(int i= alarm_timer[ctrlA_32bits[28:24]]; i>=0; i--)
	            begin
				 @(base_clk[ctrlA_32bits[19:16]]);
		        end
				if(at_en[ctrlA_32bits[28:24]]!=1'b0)
		         data[ctrlA_32bits[28:24]]=1'b1;
            end	
		at_ed:
		    begin
		        if(ctrlA_32bits[23] == 1'b0) //0-disable
                  at_en[ctrlA_32bits[28:24]]=1'b0;
		        else
                  at_en[ctrlA_32bits[28:24]]=1'b1;// enable
		    end
	endcase
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	case(op_B)
	    no_op:   
	        begin
		     //do nothing
	        end
	    set_clk: 
	        begin
		        if(ctrlB_32bits[23:22] == 2'b00 && clk_en[ctrlB_32bits[28:25]]==1'b1 )
		            begin
			         forever
			         @(posedge clk)
			         base_clk[ctrlB_32bits[28:25]]++;
		            end
		        else if(ctrlB_32bits[23:22] == 2'b01 && clk_en[ctrlB_32bits[28:25]]==1'b1 )
		            begin
			         forever
			         repeat(2) @(posedge clk);
			         base_clk[ctrlB_32bits[28:25]]++;
		            end
		        else if(ctrlB_32bits[23:22] == 2'b10 && clk_en[ctrlB_32bits[28:25]]==1'b1 )
		            begin
			         forever
			         repeat(4) @(posedge clk);
			         base_clk[ctrlB_32bits[28:25]]++;
		            end
	        end
	    clk_ed : 
	        begin
		        if(ctrlB_32bits[23] == 1'b0) //0-disable
		         clk_en[ctrlB_32bits[28:25]]=1'b0;
		        else
		         clk_en[ctrlB_32bits[28:25]]=1'b1;// enable
	        end
	    set_mode:
	        begin
		     CR_bits <= {ctrlB_32bits[28:24],3'b000};
	        end
	    set_alarm:
	        begin
		        if(at_en[ctrlB_32bits[28:24]]==1'b1)//if enable
		            begin
			         alarm_timer[ctrlB_32bits[28:24]] <= ctrlB_32bits[15:0];
			            if(ctrlB_32bits[23]==1'b1)//REPEAT
			                begin	
				             forever
				                if(alarm_timer[ctrlB_32bits[28:24]] == base_clk[ctrlB_32bits[19:16]])  
					                begin
					                 data[ctrlB_32bits[28:24]]=1'b1;
					                 repeat(2)
						             @(posedge clk);
					                 data[ctrlB_32bits[28:24]]=1'b0;
					                end
				                else
				                    data[ctrlB_32bits[28:24]]=1'b0;
			                end
			            else if(ctrlB_32bits[23]==1'b0)//NO REPEAT
			                begin
				                if(alarm_timer[ctrlB_32bits[28:24]] == base_clk[ctrlB_32bits[19:16]])                          
				                 data[ctrlB_32bits[28:24]]=1'b1;
				                 repeat(2)
				                 @(posedge clk);
				                 data[ctrlB_32bits[28:24]]=1'b0;  
			                end
		            end
		        else if(at_en[ctrlB_32bits[28:24]]==1'b0)//if disable
		         data[ctrlB_32bits[28:24]]=1'b0;
		        else
		            begin
			         alarm_timer[ctrlB_32bits[28:24]] <= ctrlB_32bits[15:0];
			            if(ctrlB_32bits[23]==1'b1)//repeat			          
			                begin
				             forever
				                if(alarm_timer[ctrlB_32bits[28:24]] == base_clk[ctrlB_32bits[19:16]])
					                begin
					                 data[ctrlB_32bits[28:24]]=1'b1;
					                 repeat(2)
						             @(posedge clk);
					                 data[ctrlB_32bits[28:24]]=1'b0;
					                end
				                else
				                 data[ctrlB_32bits[28:24]]=1'b0;
			                end
			            else if(ctrlB_32bits[23]==1'b0)//no repeat
			                begin
				                if(alarm_timer[ctrlB_32bits[28:24]] == base_clk[ctrlB_32bits[19:16]])
				                    begin
					                 data[ctrlB_32bits[28:24]]=1'b1;
					                 repeat(2)
					                 @(posedge clk);
					                 data[ctrlB_32bits[28:24]]=1'b0;  
				                    end
			                end
		            end
	        end
        set_timer:
		    begin
			 alarm_timer[ctrlB_32bits[28:24]] <= ctrlB_32bits[15:0]; 
			 for(int i= alarm_timer[ctrlB_32bits[28:24]]; i>=0; i--)
			    begin
			     @(base_clk[ctrlB_32bits[19:16]]);
			    end
			    if(at_en[ctrlB_32bits[28:24]]!=1'b0)
			     data[ctrlB_32bits[28:24]]=1'b1;
		    end			            
		at_ed:
		    begin
		        if(ctrlB_32bits[23] == 1'b0) //0-disable
                  at_en[ctrlB_32bits[28:24]]=1'b0;
		        else
                  at_en[ctrlB_32bits[28:24]]=1'b1;// enable
		    end
	endcase
end
  
  /*always @(posedge clk)
  $display("vlaue ofvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv clk =%d",base_clk);*/
  
  
endmodule	

























