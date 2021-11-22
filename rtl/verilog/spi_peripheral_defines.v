`include "timescale.v"
`default_nettype none

`define SPI_BUS_WIDTH_8
//`define SPI_BUS_WIDTH_16
//`define SPI_BUS_WIDTH_32

`ifdef SPI_BUS_WIDTH_8
    `define SPI_BUS_WIDTH	    8
    `define SPI_COUNT_WIDTH	    3
`elsif SPI_BUS_WIDTH_16
    `define SPI_BUS_WIDTH	    16
    `define SPI_COUNT_WIDTH	    4
`elsif SPI_BUS_WIDTH_32
    `define SPI_BUS_WIDTH	    32
    `define SPI_COUNT_WIDTH	    5
`else
    `define SPI_BUS_WIDTH       16
    `define SPI_COUNT_WIDTH     4
`endif

`define SPI_REG_CNT             8

`define SPI_CPOL                0
`define SPI_CPHA                0
`define SPI_LSB_FRST            0


