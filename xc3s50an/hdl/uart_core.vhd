-------------------------------------------
-- 16.01.2020
-- sboldenko
-- COEFF_BAUDRATE = Faclk/Fuart
-------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity uart_core is 
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
end uart_core;

architecture behavioral of uart_core is

    component tx_module is
    generic
    (
        COEFF_BAUDRATE : std_logic_vector(15 downto 0):= x"0C35"
    );
    port
    (
        aclk     : in  std_logic;
        areset   : in  std_logic;
        valid_in : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        ready    : out std_logic;       
        tx_out   : out std_logic
    );
    end component;  
    
    component rx_module is 
    generic
    (
        COEFF_BAUDRATE : std_logic_vector(15 downto 0):= x"0C35"
    );
    port
    (
        aclk      : in  std_logic;
        areset    : in  std_logic;
        valid_out : out std_logic;
        data_out  : out std_logic_vector(7 downto 0);   
        rx_in     : in  std_logic
    );
    end component;
    
begin 
    
    tx_module_inst: tx_module
    generic map
    (
        COEFF_BAUDRATE => COEFF_BAUDRATE
    )
    port map
    (
        aclk     => aclk,
        areset   => areset,
        valid_in => s_axis_valid,
        data_in  => s_axis_data,
        ready    => s_axis_ready,
        tx_out   => tx
    );
    
    rx_module_inst: rx_module
    generic map
    (
        COEFF_BAUDRATE => COEFF_BAUDRATE
    )
    port map
    (
        aclk      => aclk,
        areset    => areset,
        valid_out => m_axis_valid,
        data_out  => m_axis_data,
        rx_in     => rx
    );
    
end behavioral;