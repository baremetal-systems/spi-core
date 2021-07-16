#include <stdio.h>
#include <stdlib.h>
#include "Vspi_slave.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

void tick(int tickCount, Vspi_slave *tb, VerilatedVcdC *tf;)
{
    tb->eval();

    if (tfp) {
	tfp->dump(tickCount * 10 - 2);
    }

    tb->wb_clk_i = 1;
    tb->eval();

    if (tfp) {
	tfp->dump(tickCount * 10);
    }

    tb->wb_clk_i = 0;
    tb->eval();

    if (tfp) {
	tfp->dump(tickCount * 10 + 5);
	tfp->flush();
    }

    return;
}

int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);

    Vspi_slave *tb = new Vspi_slave;
    
    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    tb->trace(tfp, 00);
    tfp->open(spi_slave.vcd);

    return 0;
}

