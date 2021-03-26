--------------------------------------------------------------------------------
-- Engineer: sboldenko
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity digital_clock_tb is
generic
(
    COEFF_BAUDRATE : std_logic_vector(15 downto 0):= x"0C35"
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
        esp_01_uart_tx : out   std_logic
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
    
begin
    
    digital_clock_inst: digital_clock 
    port map 
    (
        aclk           => aclk,
        tm1637_clk     => tm1637_clk,
        tm1637_do      => tm1637_do,
        esp_01_uart_rx => esp_01_uart_rx,
        esp_01_uart_tx => esp_01_uart_tx    
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
        in_valid <= '1';
        in_data <= x"17";
        wait for CONST_CLK_PERIOD;
        in_valid <= '0';
        in_data <= (others => '0');
        wait;
    end process;
    
    process(aclk)
    begin
        if rising_edge(aclk) then
            in_valid_d <= in_valid;
            in_data_d <= in_data;
        end if;
    end process;
    
end;    
