--------------------------------------------------------------------------------
-- Engineer: sboldenko
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

library unisim;
use unisim.vcomponents.all;

library std;
use std.textio.all;

entity digital_clock_tb is
generic
(
    COEFF_BAUDRATE   : std_logic_vector(15 downto 0):= x"0C35";
    G_RD_FILE_NAME_1 : string:= "data_file_start.txt";
    G_RD_FILE_NAME_2 : string:= "data_file_hr.txt";
    G_RD_FILE_NAME_3 : string:= "data_file_min.txt";
    G_RD_FILE_NAME_4 : string:= "data_file_sec.txt"
);
end digital_clock_tb;
 
architecture behavior of digital_clock_tb is 

    constant CONST_CLK_PERIOD : time := 33.33 ns; --30 MHz

    component digital_clock
    port
    (
        aclk           : in    std_logic;
        tm1637_clk     : out   std_logic;
        tm1637_do      : out   std_logic;
        esp_01_uart_rx : in    std_logic;
        esp_01_uart_tx : out   std_logic;
        i2c_sda        : inout std_logic;
        i2c_scl        : inout std_logic
    );
    end component;
    
    signal aclk           : std_logic:= '0';
    signal tm1637_clk     : std_logic;
    signal tm1637_do      : std_logic;
    signal esp_01_uart_rx : std_logic;
    signal esp_01_uart_tx : std_logic;
    
    signal in_valid       : std_logic;
    signal in_data        : std_logic_vector(7 downto 0);
    signal in_valid_d     : std_logic;
    signal in_data_d      : std_logic_vector(7 downto 0);

    signal i2c_sda        : std_logic:= '1';
    signal i2c_scl        : std_logic;
    signal i2c_scl_z      : std_logic;
    signal counter        : std_logic_vector(3 downto 0):= (others => '0');
    signal buffer_en      : std_logic:= '1';
    signal buffer_in      : std_logic:= '1';
    signal counter_end    : std_logic_vector(7 downto 0):= (others => '0');

    component uart_core 
    generic
    (
        COEFF_BAUDRATE : std_logic_vector(15 downto 0):= x"0C35"
    );
    port
    (
        aclk         : in  std_logic;
        areset       : in  std_logic;
        s_axis_valid : in  std_logic;
        s_axis_data  : in  std_logic_vector(7 downto 0);
        s_axis_ready : out std_logic;
        m_axis_valid : out std_logic;
        m_axis_data  : out std_logic_vector(7 downto 0);
        tx           : out std_logic;
        rx           : in  std_logic    
    );
    end component;  

    procedure FUNC_READ_FILE
    (
        filename               : string;
        clk_period             : time;
        signal clk             : in  std_logic;
        signal valid_out       : out std_logic;
        signal data_out        : out std_logic_vector(7 downto 0) 
    ) is
        file     file_for_read : text;
        variable in_line       : line;
        variable in_data       : std_logic_vector(7 downto 0);
    begin
        file_open(file_for_read, filename, read_mode);

        wait until falling_edge(clk);

        while not endfile(file_for_read) loop 
            for i in 1 to 1 loop
                readline(file_for_read, in_line);
                hread(in_line, in_data);
                data_out <= in_data;
                valid_out <= '1';   
                wait for CONST_CLK_PERIOD;
            end loop;
            
            valid_out <= '0';

            wait for 1 us;

        end loop;

        file_close(file_for_read);
    end;
    
begin
    
    digital_clock_inst: digital_clock 
    port map 
    (
        aclk           => aclk,
        tm1637_clk     => tm1637_clk,
        tm1637_do      => tm1637_do,
        esp_01_uart_rx => esp_01_uart_rx,
        esp_01_uart_tx => esp_01_uart_tx,
        i2c_sda        => i2c_sda,
        i2c_scl        => i2c_scl    
    );
    
    uart_core_inst: uart_core
    generic map
    (
        COEFF_BAUDRATE => COEFF_BAUDRATE
    )
    port map
    (
        aclk         => aclk,
        areset       => '0',
        s_axis_valid => in_valid_d,
        s_axis_data  => in_data_d,
        s_axis_ready => open,
        m_axis_valid => open,
        m_axis_data  => open,
        tx           => esp_01_uart_rx,
        rx           => esp_01_uart_tx
    );

    IOBUF_inst: IOBUF
    generic map 
    (
        DRIVE            => 12,
        IBUF_DELAY_VALUE => "0", -- Specify the amount of added input delay for buffer, "0"-"16" 
        IFD_DELAY_VALUE  => "AUTO", -- Specify the amount of added delay for input register, "AUTO", "0"-"8" 
        IOSTANDARD       => "DEFAULT",
        SLEW             => "SLOW"
    )
    port map 
    (
        O  => open,         -- Buffer output
        IO => i2c_sda,      -- Buffer inout port (connect directly to top-level port)
        I  => buffer_in,    -- Buffer input
        T  => buffer_en     -- 3-state enable input, high=input, low=output 
    );

    clk_process: process
    begin
        aclk <= '0';
        wait for CONST_CLK_PERIOD / 2;
        aclk <= '1';
        wait for CONST_CLK_PERIOD / 2;
    end process;
    
    stim_process: process
    begin
        in_valid <= '0';
        in_data <= (others => '0');
        wait for 100 us;
        wait until falling_edge(aclk);
        FUNC_READ_FILE(G_RD_FILE_NAME_1, CONST_CLK_PERIOD, aclk, in_valid, in_data);
        wait for 1.2 ms;
        FUNC_READ_FILE(G_RD_FILE_NAME_2, CONST_CLK_PERIOD, aclk, in_valid, in_data);
        wait for 1.2 ms;
        FUNC_READ_FILE(G_RD_FILE_NAME_3, CONST_CLK_PERIOD, aclk, in_valid, in_data);
        wait for 1.2 ms;
        FUNC_READ_FILE(G_RD_FILE_NAME_4, CONST_CLK_PERIOD, aclk, in_valid, in_data);     
        wait;
    end process;
    
    process(aclk)
    begin
        if rising_edge(aclk) then
            in_valid_d <= in_valid;
            in_data_d <= in_data;
--            i2c_scl_z <= i2c_scl;
            
--            if (i2c_scl_z = '0' and i2c_scl = '1') then
--                counter <= counter + '1';
--            end if;
            
--            buffer_in <= '1';

--            if (counter = x"A") then
--                counter_end <= counter_end + '1';
--            else
--                counter_end <= x"00";    
--            end if;   

--            if (counter = x"9" and i2c_scl = '0') then
--                buffer_en <= '0';
--            elsif (counter_end = x"FF") then   
--                buffer_en <= '1'; 
--                counter <= x"1";
--            elsif (counter = x"A" and i2c_scl_z = '1' and i2c_scl = '0') then
--               buffer_en <= '1';
--                counter <= x"1";
--            end if;
        end if;
    end process;


    
end;    
