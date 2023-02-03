module frame_difference 
(
    // system host
    input   wire            sys_clk             ,
    input   wire            sys_rst_n           ,

    //input port for image data 
    input   wire            per_frame_vsync     ,
    input   wire            per_frame_href      ,
    input   wire            per_frame_clken     ,
    input   wire  [7:0]     per_img_Y           ,
    //sdram port?
    input   wire  [7:0]     YCbCr_img_Y_pre     ,
    
    //output port for processed image data
    output  wire            post_frame_vsync    ,
    output  wire            post_frame_href     ,
    output  wire            post_frame_clken    ,
    output  wire            post_img_Bit        ,

    //user host
    input   wire [7:0]      Diff_Threshold
);

//wire design
wire        YCbCr_img_Y_pre_valid;
//reg design
reg [7:0]   per_img_Y_delay;
reg         post_img_Bit_r;

reg [1:0]   per_frame_clken_r;
reg [1:0]   per_frame_href_r;
reg [1:0]   per_frame_vsync_r;

//***********************************************************************************************//
//*******************************************main code*******************************************//
//***********************************************************************************************//

//the time difference between the input value (gray value) in current frame and input value (gray value) in previous frame is around 1 system clock cycles
assign YCbCr_img_Y_pre_valid = per_frame_clken_r [0];

//input value in current frame delay one sytem operating cycles
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            per_img_Y_delay <= 8'd0;
        else
            per_img_Y_delay <= per_img_Y;
    end

//Compare and get the difference
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            post_img_Bit_r <= 1'b0;
        else if (YCbCr_img_Y_pre_valid == 1'b1)
            begin
                if (per_img_Y_delay > YCbCr_img_Y_pre)
                    begin
                        if ((per_img_Y_delay - YCbCr_img_Y_pre) > Diff_Threshold)
                            post_img_Bit_r <= 1'b1;
                        else 
                            post_img_Bit_r <= 1'b0;
                    end
                else
                    begin
                        if ((YCbCr_img_Y_pre - per_img_Y_delay) > Diff_Threshold)
                            post_img_Bit_r <= 1'b1;
                        else 
                            post_img_Bit_r <= 1'b0;
                    end
            end

    end

always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                per_frame_clken_r  <= 2'b0;
                per_frame_href_r   <= 2'b0;
                per_frame_vsync_r  <= 2'b0;
            end 
        else
            begin
                per_frame_clken_r   <= {per_frame_clken_r [0], per_frame_clken };
                per_frame_href_r    <= {per_frame_href_r  [0], per_frame_href  };
                per_frame_vsync_r   <= {per_frame_vsync_r [0], per_frame_vsync };            
            end
    end

assign post_frame_vsync  = per_frame_vsync_r [1];
assign post_frame_href   = per_frame_href_r  [1];
assign post_frame_clken  = per_frame_clken_r [1];

assign post_img_Bit = (post_frame_href == 1'b1) ? post_img_Bit_r : 1'b0;

endmodule