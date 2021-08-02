`include "spi_peripheral_defines.v"

module spi_slave (
    // Wishbone Signals
    wb_clk_i,
    wb_rst_i,
    wb_adr_i,
    wb_dat_i,
    wb_dat_o,
    wb_stb_i,
    wb_cyc_i,
    wb_we_i,
    wb_ack_o,
    wb_err_o,
    wb_int_o,
    // SPI Signals
    sclk_i,
    cs_i,
    mosi_i,
    miso_o
);

/*
parameter SPI_BUS_WIDTH	    = 8;
parameter SPI_CPOL	    = 1'b0;
parameter SPI_CPHA	    = 1'b0;
parameter SPI_LSB	    = 1'b0;
*/

parameter TP = 1;

// WB
//Inputs
input				wb_clk_i;
input				wb_rst_i;
input [7:0]			wb_adr_i;
input [7:0]			wb_dat_i;
input				wb_stb_i;
input				wb_cyc_i;
input				wb_we_i;
// Outputs
output reg [7:0]		wb_dat_o;
output reg			wb_ack_o;
output reg			wb_err_o;
output reg			wb_int_o;
output reg			wb_stall_o;
//SPI
// Inputs
input				sclk_i;
input				cs_i;
input				mosi_i;
// Output(s)
output				miso_o;

reg [SPI_COUNT_WIDTH -1:0]	rx_bit_count;
reg [SPI_COUNT_WIDTH -1:0]	rx_reg_addr_count;
reg [SPI_COUNT_WIDTH -1:0]	tx_reg_addr_count;
reg [SPI_COUNT_WIDTH -1:0]	tx_bit_count;
reg [SPI_BUS_WIDTH -1:0]	rx_data;
reg [SPI_BUS_WIDTH -1:0]	tx_data;
reg				tx_transmit_bit;
reg				tx_start;
reg				sclk_i_reg;
reg				cs_i_reg;
reg				tx_complete;
reg				rx_complete;
reg				active_transfer;

wire				sclk_pos_edge;
wire				sclk_neg_edge;
wire				transmit_step;
//wire				tx_complete;
//wire				rx_complete;

initial
begin
    rx_bit_count = 0;
    rx_data = 0;
    rx_complete = 0;
    tx_bit_count = 0;
    tx_data = 0;
    tx_complete = 0;
    cs_i_reg = 0;
    active_transfer = 0;
end

//assertion: wb_clk_i is much faster than sclk_i
always@(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i) begin
	sclk_i_reg <= 1'b0;
	cs_i_reg <= 1'b0;
    end
    else begin
	sclk_i_reg <= sclk_i;
	cs_i_reg <= cs_i;
    end
end

/* Edge detection  on SPI SCLK */
assign sclk_pos_edge = (sclk_i == 1'b1) && (sclk_i_reg == 1'b0);
assign sclk_neg_edge = (sclk_i == 1'b0) && (sclk_i_reg == 1'b1);
assign transmit_step = (~(SPI_CPOL ^ SPI_CPHA) & sclk_pos_edge) | (SPI_CPOL ^ SPI_CPHA & sclk_neg_edge);

/* SPI RECEIVE */
always@(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i) begin
	rx_data <= {SPI_BUS_WIDTH{1'b0}};
	rx_bit_count <= 8'b0;
    end
    else begin
	if (cs_i_reg) begin
	    if (transmit_step) begin
		if (~SPI_LSB) begin
		    rx_data <= {mosi_i, rx_data[(SPI_BUS_WIDTH -2):0]}; 
		end
		else begin
		    rx_data <= {rx_data[(SPI_BUS_WIDTH -2):0], mosi_i};
		end
		rx_bit_count <= rx_bit_count + 1'b1;
	    end
	    else begin
		rx_data <= rx_data;
	    end
	end
	else begin
	    rx_data <= {SPI_BUS_WIDTH{1'b0}};
	    rx_bit_count <= 8'b0;
	end
    end
end

/* SPI TRANSMIT */
always@(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i) begin
	tx_data <= {SPI_BUS_WIDTH{1'b0}};
	tx_start <= 1'b0;
	tx_bit_count <= 8'b0;
    end
    else begin
	if (cs_i_reg) begin
	    if (~SPI_LSB) begin
		tx_transmit_bit <= tx_data [(SPI_BUS_WIDTH -1) - tx_bit_count];
	    end
	    else begin
		tx_transmit_bit <= tx_data [tx_bit_count];
	    end

	    if (transmit_step) begin
		tx_start <= 1'b1;
		tx_bit_count <= tx_bit_count + 1'b1;
	    end
	end
	else begin
	    tx_start <= 1'b0;
	    tx_bit_count <= 8'b0;
	end
    end
end

assign miso_o = (tx_start) ? tx_transmit_bit : 1'bz;
//assign tx_complete = (tx_bit_count == (SPI_BUS_WIDTH -1)) ? 1'b1 : 1'b0;
//assign rx_complete = (rx_bit_count == (SPI_BUS_WIDTH -1)) ? 1'b1 : 1'b0;

always@(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i) begin
	rx_complete <= 1'b0;
	tx_complete <= 1'b0;
    end
    else begin
	if (tx_bit_count == (SPI_BUS_WIDTH -1)) begin
	    tx_complete <= 1'b1;
	end
	else begin
	    tx_complete <= 1'b0;
	end

	if (rx_bit_count == (SPI_BUS_WIDTH -1)) begin
	    rx_complete <= 1'b1;
	end
	else begin
	    rx_complete <= 1'b0;
	end
    end
end

always@(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i) begin
	active_transfer <= 1'b0;
    end
    else begin
	if (tx_bit_count != 0 || rx_bit_count != 0) begin
	    active_transfer <= 1'b1;
	else begin
	    active_transfer <= 1'b0;
	end
    end
end

initial
begin
    wb_dat_o = 0;
    wb_ack_o = 0;
    wb_err_o = 0;
    wb_int_o = 0;
    wb_stall_o = 0;
end

always@(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i) begin
	wb_int_o <= 1'b0;
    end
    else begin
	if (tx_complete || rx_complete) begin
	    wb_int_o <= 1'b1'
	end
	/* only reset interrupt when there was a successfull transmission on the SPI lines */
	else if (wb_ack_o && !wb_stb_i) begin
	    wb_int_o <= 1'b0;
	end
    end
end

always@(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i) begin
	tx_data <= {SPI_BUS_WIDTH{1'b0}};
	wb_stall_o <= 1'b0;
    end
    else begin
	if (wb_we_i && !active_transfer) begin
	    //TODO: implement concatentations for mismatch of SPI_BUS_WIDTH and Wb_DATA_WIDTH
	    tx_data <= wb_data_i;
	    wb_stall_o <= 1'b0;
	end
	else  begin
	    wb_stall_o <= 1'b1;
	end
    end
end

endmodule 
