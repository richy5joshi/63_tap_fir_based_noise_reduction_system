
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package fir_filter_pkg is

    constant DATA_WIDTH : integer := 16;
    constant COEFF_WIDTH : integer := 16;
    constant ACC_WIDTH  : integer := 40;
    constant NUM_TAPS   : integer := 63;

    subtype data_type is signed(DATA_WIDTH-1 downto 0);
    subtype coeff_type is signed(COEFF_WIDTH-1 downto 0);
    subtype acc_type is signed(ACC_WIDTH-1 downto 0);

    type data_array is array (0 to NUM_TAPS-1) of data_type;
    type coeff_array is array (0 to NUM_TAPS-1) of coeff_type;

end package fir_filter_pkg;
