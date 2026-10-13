LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.fpga_interconnect_pkg.all;

-- signal_scope sampling a counter that steps on every sample event : the
-- trigger primed over the bus, a trigger event at a known sample, then the
-- whole buffer read out over the bus : the samples come out from the oldest
-- on, all consecutive, the triggering sample among them with the scope's
-- samples after trigger (ram_depth/2) after it, to within a sample
entity signal_scope_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of signal_scope_tb is

    constant clock_period : time := 1 ns;
    constant ram_bit_width : positive := 16;
    constant ram_depth_pow2 : positive := 6;
    constant ram_depth : positive := 2**ram_depth_pow2;
    constant trigger_address : positive := 1000;
    constant data_address : positive := 1001;
    constant samples_after_trigger_address : positive := 1002;
    -- the scope's default, ram_depth/2
    constant samples_after_trigger : natural := ram_depth/2;
    -- the counter's value at the trigger event
    constant trigger_sample : natural := 300;

    signal clock : std_logic := '0';
    signal bus_to_scope : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_scope : fpga_interconnect_record;

    signal clock_count : natural := 0;
    signal counter : unsigned(ram_bit_width-1 downto 0) := (others => '0');
    signal sampled_data : std_logic_vector(ram_bit_width-1 downto 0);
    signal sample_event : boolean := false;
    signal trigger_event : boolean := false;

    type sample_array is array (0 to ram_depth-1) of natural;
    signal samples : sample_array := (others => 0);
    signal samples_read : natural := 0;
    signal reading_samples : boolean := false;

begin

    clock <= not clock after clock_period/2;
    sampled_data <= std_logic_vector(counter);

    stimulus : process
        procedure bus_read(address : natural) is
        begin
            wait until rising_edge(clock);
            request_data_from_address(bus_to_scope, address);
            wait until rising_edge(clock);
            init_bus(bus_to_scope);
        end bus_read;

        variable trigger_index : integer := -1;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            if run("the_buffer_holds_consecutive_samples_around_the_trigger") then
                wait for 20*clock_period;
                bus_read(trigger_address);  -- primes the trigger

                wait until rising_edge(clock) and to_integer(counter) = trigger_sample - 1 and sample_event;
                trigger_event <= true;
                wait until rising_edge(clock);
                trigger_event <= false;

                -- the samples after the trigger, then some
                wait for 8*ram_depth*clock_period;

                reading_samples <= true;
                for i in 0 to ram_depth-1 loop
                    bus_read(data_address);
                    wait until rising_edge(clock) and samples_read = i+1 for 20*clock_period;
                    check_equal(samples_read, i+1, "a read answered");
                end loop;

                for i in 0 to ram_depth-1 loop
                    info("sample " & integer'image(i) & " : " & integer'image(samples(i)));
                end loop;
                for i in 1 to ram_depth-1 loop
                    check_equal(samples(i), (samples(i-1) + 1) mod 2**ram_bit_width, "sample " & integer'image(i) & " follows the one before");
                end loop;
                for i in 0 to ram_depth-1 loop
                    if samples(i) = trigger_sample then
                        trigger_index := i;
                    end if;
                end loop;
                info("first sample " & integer'image(samples(0)) & ", the trigger sample at " & integer'image(trigger_index)
                     & ", " & integer'image(ram_depth-1 - trigger_index) & " samples after it");
                check(trigger_index >= 0, "the trigger sample is in the buffer");
                check(abs(ram_depth-1 - trigger_index - samples_after_trigger) <= 1,
                      "samples after the trigger : " & integer'image(ram_depth-1 - trigger_index));
            end if;
        end loop;

        test_runner_cleanup(runner);
        wait;
    end process;

    -- a sample event every third clock, the counter stepping with it
    events : process(clock)
    begin
        if rising_edge(clock) then
            clock_count <= clock_count + 1;
            sample_event <= clock_count mod 3 = 0;
            if sample_event then
                counter <= counter + 1;
            end if;

            if reading_samples and write_to_address_is_requested(bus_from_scope, 0) and samples_read < ram_depth then
                samples(samples_read) <= get_data(bus_from_scope);
                samples_read <= samples_read + 1;
            end if;
        end if;
    end process;

    u_scope : entity work.signal_scope
    generic map(
        g_ram_bit_width    => ram_bit_width
        , g_ram_depth_pow2 => ram_depth_pow2
        , g_trigger_address => trigger_address
        , g_data_address    => data_address
        , g_samples_after_trigger_address => samples_after_trigger_address)
    port map(
        main_clock              => clock
        , bus_in                => bus_to_scope
        , bus_from_signal_scope => bus_from_scope
        , trigger_event1        => trigger_event
        , sample_event1         => sample_event
        , sampled_data1         => sampled_data);

end vunit_simulation;
