`default_nettype none 
`timescale 1 ns / 10 ps

module LED_counter_tb ();
	
	//---------------------------------
	//-- Simulation time
	//---------------------------------
	
	parameter DURATION          = 1000;
    parameter real CLOCK_PERIOD = 5.0;
    parameter real HALF_PERIOD  = CLOCK_PERIOD / 2; 
	
	initial begin
		$dumpfile("power/out/ihp-sg13g2/power_activity.vcd");
        $dumpvars(0, DUT);
		// `ifdef SDF_FILE_PATH
    	//   	$display("INFO: SDF file provided. Annotating delays for timing simulation.");
    	//   	$sdf_annotate(`SDF_FILE_PATH, DUT);
    	// `else
    	//   	$display("INFO: No SDF file provided. Running functional simulation.");
    	// `endif

		#(DURATION) $display("End of simulation");
		$finish;
	end	
	
	//--------------------------------------
	//-- Wires and Registers               
	//--------------------------------------
	
	//-- Inputs
    reg clk;
    reg rst;
    //-- Outputs
    wire [7:0] leds;
        
    //--------------------------------------
	//-- LED Counter Instance
	//--------------------------------------
	
	LED_counter DUT (
		            .clk(clk),
		            .rst(rst),
		            .leds(leds)
		            ); 

    //---------------------------------
	//-- Test Values
	//---------------------------------

	initial begin
	    clk 		= 0;
	    rst 		= 1;
    
	    #(10*CLOCK_PERIOD)
     	rst 		= 0;
    end
    
    always #(HALF_PERIOD) clk = ~clk;
        
endmodule
