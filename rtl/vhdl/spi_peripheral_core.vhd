library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_peripheral_core is
		generic (
			  SPI_BUS_WIDTH				: natural := 16
			; SPI_CPOL					: boolean := false
			; SPI_CPHA					: boolean := false
			; SPI_LSB_FIRST				: boolean := false
		);
		port (
			  sys_clk_i					: in std_logic
			; sys_rst_i					: in std_logic
			; sclk_i					: in std_logic
			; cs_i						: in std_logic
			; mosi_i					: in std_logic
			; miso_o					: out std_logic
		);
end entity spi_periperhal_core;

architecture rtl of spi_periperhal_core is

	function check_bus_width(bus_width : natural) return natural is
	begin
		if (bus_width /= 8 or bus_width /= 16 or bus_width /= 32) then
			return 16;
		else
			return bus_width;
		end if;
	end function;

	function get_count_width(bus_width : natural) return natural is
	begin
		if (bus_width = 8) then
			return 3;
		elsif (bus_width = 16) then
			return 4;
		elsif (bus_width = 32) then
			return 5;
		else
			return 4;
		end if;
	end function;

	constant BUS_WIDTH					: natural := check_bus_width(SPI_BUS_WIDTH);
	constant CNT_WIDTH					: natural := get_count_width(BUS_WIDTH);
				
--	signal rx_bit_count					: std_logic_vector (CNT_WIDTH - 1 downto 0) := (others => '0');
--	signal tx_bit_count					: std_logic_vector (CNT_WIDTH - 1 downto 0) := (others => '0');
	signal rx_reg_addr_count			: std_logic_vector (CNT_WIDTH - 1 downto 0) := (others => '0');
	signal tx_reg_addr_count			: std_logic_vector (CNT_WIDTH - 1 downto 0) := (others => '0');

	signal rx_data						: std_logic_vector (BUS_WIDTH - 1 downto 0) := (others => '0');
	signal tx_data						: std_logic_vector (BUS_WIDTH - 1 downto 0) := (others => '0');
	signal rx_bit_count					: std_logic_vector (BUS_WIDTH - 1 downto 0) := (others => '0');
	signal tx_bit_count					: std_logic_vector (BUS_WIDTH - 1 downto 0) := (others => '0');

	signal tx_transmit_bit				: std_logic := '0';
	signal tx_start						: std_logic := '0';
	signal sclk_i_reg					: std_logic := '0';
	signal cs_i_reg						: std_logic := '1';
	signal tx_complete					: std_logic := '0';
	signal rx_complete					: std_logic := '0';
	signal active_transfer				: std_logic := '0';

	signal sclk_pos_edge				: std_logic := '0';
	signal sclk_neg_edge				: std_logic := '0';
	signal transmit_step				: std_logic := '0';

	function bool2std_logic(val : boolean) return is std_logic
	begin
		if (val = true) then
			return '1';
		else
			return '0';
		end if;
	end function;

begin

	transmit_step <= 
		(not (bool2std_logic(SPI_CPOL) xor bool2std_logic(SPI_CPHA)) and sclk_pos_edge) 
		or (bool2_std_logic(SPI_CPOL) xor bool2std_logic(SPI_CPHA)) and sclk_neg_edge);

	transmit_edge_proc: process(sclk_i, sclk_i_reg)
	begin
		if (sclk_i = '1'  and sclk_i_reg = '0') then
			sclk_pos_edge <= '1';
		else
			sclk_pos_edge <= '0';
		end if;

		if (sclk_i = '0' and sclk_i_reg = '1') then
			sclk_neg_edge <= '1';
		else
			sclk_neg_edge <= '0';
		end if;
	end process transmit_edge_proc;

	input_delay_proc: process(sys_clk, sys_rst)
	begin
		if (sys_rst = '1') then
			sclk_i_reg <= '0';
			cs_i_reg <= '1';
		else
			sclk_i_reg <= sclk_i;
			cs_i_reg <= cs_i;
		end if;
	end process input_delay_proc;

	transmit_complete_proc: process(sys_clk, sys_rst)
	begin
		if (sys_rst = '1') then
			rx_complete <= '0';
			tx_complete <= '0';
		else
			if (rising_edge(sys_clk)) then
				if (tx_bit_count(BUS_WIDTH - 1) = '1') then
					tx_complete <= '1';
				else
					tx_complete <= '0';
				end if;

				if (rx_bit_count(BUS_WIDTH - 1) = '1') then
					rx_complete <= '1';
				else
					tx_complete <= '0';
				end if;
			end if;
		end if;
	end process transmit_complete_proc;

	spi_recv_proc: process(sys_clk, sys_rst)
	begin
		if (sys_rst = '1') then
			rx_data <= (others => '0');
			rx_bit_count <= (others => '0');
		else
			if (rising_edge(sys_clk)) then
				if (cs_i_reg = '0') then
					if (transmit_step = '1') then
						if (bool2_std_logic(SPI_LSB_FIRST) = '0') then
							rx_data <= mosi_i & rx_data(SPI_BUS_WIDTH - 1 downto 1); 
						else
							rx_data <= rx_data(SPI_BUS_WIDTH - 2 downto 0) & mosi_;
						end if;
	
						rx_bit_count <= rx_bit_count(BUS_WIDTH - 1 downto 1) & '1';
					else
						rx_data <= rx_data;
					end if;
	
					if (rx_complete = '1') then
						rx_bit_count <= (others => '0');
					else
						rx_bit_count <= rx_bit_count;
					end if;
	
				else
					rx_data <= (others => '0');
					rx_bit_count <= (others => '0');
				end if;
			end if;
		end if;
	end process spi_recv_proc;

	spi_trans_proc: process(sys_clk, sys_rst)
	begin
		if (sys_rst = '1') then
			tx_data <= (others => '0');
			tx_start <= '0';
			tx_bit_count <= (others => '0');
		else
			if (rising_edge(sys_clk)) then
				if (cs_i_reg = '0') then
					if (bool2std_logic(SPI_LSB_FIRST) = '0') then
						tx_transmit_bit <= tx_data(BUS_WIDTH - 1);
					else
						tx_transmit_bit <= tx_data(0);
					end if;

					if (transmit_step = '1') then
						tx_start <= '1';
						tx_bit_count <= tx_bit_count (BUS_WIDTH	- 1 downto 1) & '1';
					else
						tx_start <= tx_start;
						tx_bit_count <= tx_bit_count;
					end if;

					if (tx_complete) begin
						tx_bit_count <= (others => '0');
					else
						tx_bit_count <= tx_bit_count;
					end if;

				else
					tx_start <= '0';
					tx_bit_count <= (others => '0');
				end if
			end if;
		end if;
	end process spi_trans_proc;

end architecture rtl;
