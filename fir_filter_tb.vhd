
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.ENV.ALL;

use work.fir_filter_pkg.ALL;

entity fir_filter_tb is
end fir_filter_tb;

architecture Behavioral of fir_filter_tb is

    signal clk        : STD_LOGIC := '0';
    signal rst        : STD_LOGIC := '0';

    signal data_in    : data_type := (others => '0');
    signal data_out   : data_type;
    signal data_valid : STD_LOGIC;

    signal coeffs     : coeff_array := (others => (others => '0'));

    constant CLK_PERIOD : time := 10 ns;
    constant NUM_INPUTS : integer := 400;
    constant NUM_OUTPUTS : integer := 338;

begin

    -- DUT instantiation

    DUT: entity work.fir_filter
        port map (
            clk        => clk,
            rst        => rst,
            data_in    => data_in,
            coeffs     => coeffs,
            data_out   => data_out,
            data_valid => data_valid
        );

    -- Clock generation: 100 MHz

    clk <= not clk after CLK_PERIOD/2;

    -- Testbench process

    stimulus_process: process

        file input_file    : text;
        file coeff_file    : text;
        file expected_file : text;

        variable file_status : file_open_status;

        variable input_line    : line;
        variable coeff_line    : line;
        variable expected_line : line;

        variable input_word    : STD_LOGIC_VECTOR(15 downto 0);
        variable coeff_word    : STD_LOGIC_VECTOR(15 downto 0);
        variable expected_word : STD_LOGIC_VECTOR(15 downto 0);

        variable output_count  : integer := 0;
        variable error_count   : integer := 0;

    begin

        report "====================================";
        report "63-TAP FIR FILTER TESTBENCH STARTED";
        report "====================================";

        ------------------------------------------------
        -- 1. OPEN INPUT MEMORY FILE
        ------------------------------------------------

        file_open(
            file_status,
            input_file,
            "input_data.mem",
            read_mode
        );

        assert file_status = open_ok
            report "ERROR: Cannot open input_data.mem"
            severity failure;

        ------------------------------------------------
        -- 2. OPEN COEFFICIENT MEMORY FILE
        ------------------------------------------------

        file_open(
            file_status,
            coeff_file,
            "fir_coefficients.mem",
            read_mode
        );

        assert file_status = open_ok
            report "ERROR: Cannot open fir_coefficients.mem"
            severity failure;

        ------------------------------------------------
        -- 3. OPEN EXPECTED OUTPUT MEMORY FILE
        ------------------------------------------------

        file_open(
            file_status,
            expected_file,
            "expected_output.mem",
            read_mode
        );

        assert file_status = open_ok
            report "ERROR: Cannot open expected_output.mem"
            severity failure;

        ------------------------------------------------
        -- 4. LOAD 63 FIR COEFFICIENTS
        ------------------------------------------------

        report "Loading FIR coefficients...";

        for i in 0 to NUM_TAPS-1 loop

            assert not endfile(coeff_file)
                report "ERROR: Insufficient FIR coefficients"
                severity failure;

            readline(coeff_file, coeff_line);
            hread(coeff_line, coeff_word);

            coeffs(i) <= signed(coeff_word);

        end loop;

        wait for 1 ns;

        report "63 FIR coefficients loaded successfully.";

        ------------------------------------------------
        -- 5. RESET DUT
        ------------------------------------------------

        rst <= '1';
        data_in <= (others => '0');

        wait for 3*CLK_PERIOD;

        wait until falling_edge(clk);

        rst <= '0';

        ------------------------------------------------
        -- 6. APPLY 400 INPUT SAMPLES
        ------------------------------------------------

        report "Applying noisy input samples...";

        for i in 0 to NUM_INPUTS-1 loop

            assert not endfile(input_file)
                report "ERROR: Insufficient input samples"
                severity failure;

            readline(input_file, input_line);
            hread(input_line, input_word);

            wait until falling_edge(clk);

            data_in <= signed(input_word);

            wait until rising_edge(clk);

            wait for 1 ns;

            ------------------------------------------------
            -- 7. CHECK VALID OUTPUT
            ------------------------------------------------

            if data_valid = '1' then

                assert not endfile(expected_file)
                    report "ERROR: Expected output file ended early"
                    severity failure;

                readline(expected_file, expected_line);
                hread(expected_line, expected_word);

                output_count := output_count + 1;

                if data_out /= signed(expected_word) then

                    error_count := error_count + 1;

                    report "MISMATCH at output sample " &
                           integer'image(output_count) &
                           " | Expected = " &
                           integer'image(to_integer(signed(expected_word))) &
                           " | Actual = " &
                           integer'image(to_integer(data_out))
                           severity error;

                end if;

            end if;

        end loop;

        ------------------------------------------------
        -- 8. CLOSE MEMORY FILES
        ------------------------------------------------

        file_close(input_file);
        file_close(coeff_file);
        file_close(expected_file);

        ------------------------------------------------
        -- 9. FINAL VERIFICATION REPORT
        ------------------------------------------------

        report "====================================";
        report "FIR FILTER VERIFICATION COMPLETED";
        report "====================================";

        report "Input samples  : " &
               integer'image(NUM_INPUTS);

        report "Output samples : " &
               integer'image(output_count);

        report "Expected outputs: " &
               integer'image(NUM_OUTPUTS);

        report "Total errors   : " &
               integer'image(error_count);

        if output_count = NUM_OUTPUTS and error_count = 0 then

            report "FINAL RESULT: PASS"
                severity note;

        else

            report "FINAL RESULT: FAIL"
                severity error;

        end if;

        report "====================================";

        finish;

        wait;

    end process;

end Behavioral;
