TOP ?= spi_peripheral

VERILATOR=verilator
VERILATOR_ROOT = /usr/shar/verilator
VINC := $(VERILATOR_ROOT)/include

SRC_PATH := $(PWD)/../rtl/verilog

.PHONY: all
all: $(SRC_PATH)/$(TOP)

obj_dir/V$(TOP).cpp: $(SRC_PATH)/$(TOP).v
	$(VERILATOR) -I$(SRC_PATH) -Wall -cc $(SRC_PATH)/$(TOP).v

obj_dir/V$(TOP)__ALL.a: obj_dir/V$(TOP).cpp
	make --no-print-directory -C obj_dir -f V$(TOP).mk

$(SRC_PATH)/$(TOP): $(TOP).cpp obj_dir/V$(TOP)__ALL.a
	g++ -I$(VINC)/include -I obj_dir -I$(SRC_PATH) \
		$(VINC)/verilated.cpp \
		$(VINC)/verilated_vcd_c.cpp \
		$(TOP).cpp obj_dir/V$(TOP)__ALL.a \
		-o $(TOP)


.PHONY: clean
clean:
	rm -rf obj_dir/ $(TOP) $(TOP).vcd
