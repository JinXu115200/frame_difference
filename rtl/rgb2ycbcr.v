module rgb2ycbcr (
    // System host?
    input   wire                sys_clk             ,   //system operating clock
    input   wire                sys_rst_n           ,   //reset signal with low level valid

    // RGB image input port
    input   wire                per_frame_href      ,   //Horizontal Synchronization signal for input image
    input   wire                per_frame_vsync     ,   //Vertikale Synchronization signal for input image
    input   wire    [23:0]      pix_data_in         ,   //rgb pix data
    input   wire                per_frame_clken     ,   

    // YCbCr output port   
    output  wire    [23:0]      gray_data           ,   //YCbCr pix data
    output  wire                post_frame_clken    ,   
    output  wire                post_frame_vsync    ,   //Vertikale Synchronization signal for output image
    output  wire                post_frame_href        //Horizontal Synchronization signal for output image   
 
);


//wire difination
wire [7:0]  R_0  ;
wire [7:0]  G_0  ;
wire [7:0]  B_0  ;

//reg difination
reg  [15:0] R_1  ;   // registor of data in red channel for frist level operation
reg  [15:0] G_1  ;   // registor of data in green channel for frist level operation
reg  [15:0] B_1  ;   // registor of data in blue channel for frist level operation

reg  [15:0] R_2  ;   // registor of data in red channel for second level operation
reg  [15:0] G_2  ;   // registor of data in green channel for second level operation
reg  [15:0] B_2  ;   // registor of data in blue channel for second level operation

reg  [15:0] R_3  ;   // registor of data in red channel for thrid level operation
reg  [15:0] G_3  ;   // registor of data in green channel for thrid level operation
reg  [15:0] B_3  ;   // registor of data in blue channel for thrid level operation

reg  [16:0] Y_1  ;
reg  [16:0] Cb_1 ;
reg  [16:0] Cr_1 ;  

reg  [7:0] Y_2  ;
reg  [7:0] Cb_2 ;
reg  [7:0] Cr_2 ; 





//*******************************************************************************************************************//
//******************************************************main code****************************************************//
//*******************************************************************************************************************//

//pix data with form "RGB565" to "RGB888"
//assign R_0 = {pix_data_in [15:11] , pix_data_in [15:13]} ;
//assign G_0 = {pix_data_in [10:5] , pix_data_in [10:9]};
//assign B_0 = {pix_data_in [4:0] , pix_data_in [4:2]};
assign R_0 = pix_data_in [23:16]    ;
assign G_0 = pix_data_in [15:8]     ;
assign B_0 = pix_data_in [7:0]      ;

//frist level operation: multiplication operation
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
               {R_1, G_1, B_1} <= {16'd0, 16'd0, 16'd0};
               {R_2, G_2, B_2} <= {16'd0, 16'd0, 16'd0};
               {R_3, G_3, B_3} <= {16'd0, 16'd0, 16'd0};
            end
        else 
            begin
                {R_1, G_1, B_1} <= { {R_0 * 16'd77} , {G_0 * 16'd150} , {B_0 * 16'd29} }; 
                {R_2, G_2, B_2} <= { {R_0 * 16'd43} , {G_0 * 16'd85} ,  {B_0 * 16'd128} };
                {R_3, G_3, B_3} <= { {R_0 * 16'd128}, {G_0 * 16'd107} , {B_0 * 16'd21} };
            end
    end

//second level operation: Addition and subtraction operation
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                Y_1  <= 16'd0;  
                Cb_1 <= 16'd0;  
                Cr_1 <= 16'd0;  
            end
        else
            begin
                Y_1  <= R_1 + G_1 + B_1;
                Cb_1 <= B_2 - R_2 - G_2 + 16'd32768;
                Cr_1 <= R_3 - G_3 - B_3 + 16'd32768;
            end
    end

//thrid level operation: bit shift operation
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                Y_2  <= 16'd0;  
                Cb_2 <= 16'd0;  
                Cr_2 <= 16'd0;  
            end
        else
            begin
                Y_2  <= Y_1  >> 8;
                Cb_2 <= Cb_1 >> 8;
                Cr_2 <= Cr_1 >> 8;
            end
    end

reg	[2:0]	per_frame_vsync_r;
reg	[2:0]	per_frame_href_r;	
reg	[2:0]	per_frame_clken_r;
always@(posedge sys_clk or negedge sys_rst_n)
begin
	if(sys_rst_n == 1'b0)
		begin
		per_frame_vsync_r <= 0;
		per_frame_href_r <= 0;
		per_frame_clken_r <= 0;
		end
	else
		begin
		per_frame_vsync_r 	<= 	{per_frame_vsync_r[1:0], 	per_frame_vsync};
		per_frame_href_r 	<= 	{per_frame_href_r[1:0], 	per_frame_href};
		per_frame_clken_r 	<= 	{per_frame_clken_r[1:0], 	per_frame_clken};
		end
end
assign	post_frame_vsync 	= 	per_frame_vsync_r[2];
assign	post_frame_href 	= 	per_frame_href_r[2];
assign	post_frame_clken 	= 	per_frame_clken_r[2];

assign  gray_data = (post_frame_href == 1'b1) ? {Y_2 [7:0], Y_2 [7:0], Y_2 [7:0]} : 24'd0;

endmodule