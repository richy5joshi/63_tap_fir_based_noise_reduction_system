
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.fir_filter_pkg.ALL;

entity fir_filter is
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        data_in     : in  data_type;
        coeffs      : in  coeff_array;
        data_out    : out data_type;
        data_valid  : out STD_LOGIC
    );
end fir_filter;

architecture Behavioral of fir_filter is

    signal samples : data_array := (others => (others => '0'));

    signal sample_count : integer range 0 to NUM_TAPS := 0;

begin

    process(clk)

        variable samples_next : data_array;
        variable accumulator  : acc_type;
        variable rounded_acc  : acc_type;
        variable magnitude    : acc_type;
        variable result_temp  : acc_type;

    begin

        if rising_edge(clk) then

            if rst = '1' then

                samples <= (others => (others => '0'));

                sample_count <= 0;

                data_out <= (others => '0');

                data_valid <= '0';

            else

                data_valid <= '0';

                -- Shift previous samples
                for i in 0 to NUM_TAPS-2 loop
                    samples_next(i+1) := samples(i);
                end loop;

                -- Insert current input sample
                samples_next(0) := data_in;

                samples <= samples_next;

                -- Count the number of received samples
                if sample_count < NUM_TAPS then
                    sample_count <= sample_count + 1;
                end if;

                -- Start filtering after receiving 63 samples
                if sample_count >= NUM_TAPS-1 then

                    accumulator := (others => '0');

                    -- 63-tap FIR multiplication and accumulation
                    for i in 0 to NUM_TAPS-1 loop

                        accumulator := accumulator +
                            resize(
                                samples_next(i) * coeffs(i),
                                ACC_WIDTH
                            );

                    end loop;

                    -- Symmetric rounding to nearest integer
                    if accumulator >= 0 then

                        rounded_acc := accumulator +
                            to_signed(16384, ACC_WIDTH);

                        result_temp := shift_right(rounded_acc, 15);

                    else

                        magnitude := -accumulator;

                        magnitude := magnitude +
                            to_signed(16384, ACC_WIDTH);

                        result_temp := -shift_right(magnitude, 15);

                    end if;

                    -- Signed 16-bit saturation
                    if result_temp > to_signed(32767, ACC_WIDTH) then

                        data_out <= to_signed(32767, DATA_WIDTH);

                    elsif result_temp < to_signed(-32768, ACC_WIDTH) then

                        data_out <= to_signed(-32768, DATA_WIDTH);

                    else

                        data_out <= resize(result_temp, DATA_WIDTH);

                    end if;

                    data_valid <= '1';

                end if;

            end if;

        end if;

    end process;

end Behavioral;
