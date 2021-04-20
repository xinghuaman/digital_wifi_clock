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
    G_RD_FILE_NAME_1 : string:= "preamble.txt";
    G_RD_FILE_NAME_2 : string:= "data_file_start.txt";
    G_RD_FILE_NAME_3 : string:= "data_file_hr.txt";
    G_RD_FILE_NAME_4 : string:= "data_file_min.txt";
    G_RD_FILE_NAME_5 : string:= "data_file_sec.txt";
    G_RD_FILE_NAME_6 : string:= "error_file.txt"
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

    signal i2c_sda        : std_logic;
    signal i2c_scl        : std_logic;

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

        for i in 0 to 20 loop
            FUNC_READ_FILE(G_RD_FILE_NAME_6, CONST_CLK_PERIOD, aclk, in_valid, in_data);
            wait for 1.2 ms;
        end loop;
        FUNC_READ_FILE(G_RD_FILE_NAME_1, CONST_CLK_PERIOD, aclk, in_valid, in_data);
        wait for 1.2 ms;
        FUNC_READ_FILE(G_RD_FILE_NAME_2, CONST_CLK_PERIOD, aclk, in_valid, in_data);
        wait for 1.2 ms;
        FUNC_READ_FILE(G_RD_FILE_NAME_3, CONST_CLK_PERIOD, aclk, in_valid, in_data);
        wait for 1.2 ms;
        FUNC_READ_FILE(G_RD_FILE_NAME_4, CONST_CLK_PERIOD, aclk, in_valid, in_data);
        wait for 1.2 ms;
        FUNC_READ_FILE(G_RD_FILE_NAME_5, CONST_CLK_PERIOD, aclk, in_valid, in_data);
        wait for 1.2 ms;
        
        for i in 0 to 20 loop
            FUNC_READ_FILE(G_RD_FILE_NAME_6, CONST_CLK_PERIOD, aclk, in_valid, in_data);
            wait for 1.2 ms;
        end loop;
        wait;
    end process;
    
    process(aclk)
    begin
        if rising_edge(aclk) then
            in_valid_d <= in_valid;
            in_data_d <= in_data;
        end if;
    end process;

    PULLUP_inst: PULLUP
    port map 
    (
        O => i2c_sda     -- Pullup output (connect directly to top-level port)
    );
    
end;    
