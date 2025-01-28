
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity signal_scope is
    generic(g_ram_bit_width    : positive
            ;g_ram_depth_pow2  : positive
            ;g_trigger_address : positive := 1000
            ;g_data_address    : positive := 1001
            ;g_samples_after_trigger_address : positive := 1002
           );
    port (
      main_clock              : in std_logic
      ; bus_in                : in work.fpga_interconnect_pkg.fpga_interconnect_record
      ; bus_from_signal_scope : out work.fpga_interconnect_pkg.fpga_interconnect_record
      ; trigger_event1         : in boolean
      ; sample_event1          : in boolean
      ; sampled_data1          : in std_logic_vector
    );
end entity signal_scope;

architecture rtl of signal_scope is

    use work.fpga_interconnect_pkg.all;

    package scope_ram_port_pkg is new work.ram_port_generic_pkg 
        generic map(
            g_ram_bit_width    => g_ram_bit_width
            , g_ram_depth_pow2 => g_ram_depth_pow2);

    package scope_sample_trigger_pkg is new work.sample_trigger_generic_pkg 
        generic map(g_ram_depth => scope_ram_port_pkg.ram_depth);

    use scope_ram_port_pkg.all;
    use scope_sample_trigger_pkg.all;

    signal samples_after_trigger : natural range 0 to ram_depth-1 := ram_depth/2;

    procedure create_scope(
      signal trigger          : inout sample_trigger_record
      ; bus_in                : in fpga_interconnect_record
      ; signal bus_out        : out fpga_interconnect_record
      ; signal ram_port_in_a  : out ram_in_record
      ; signal ram_port_out_a : in ram_out_record
      ; signal ram_port_in_b  : out ram_in_record
      ; signal ram_port_out_b : in ram_out_record
      ; trigger_event          : in boolean
      ; sample_event          : in boolean
      ; sampled_data          : in std_logic_vector

    ) is
    begin
        create_trigger(trigger, trigger_event, sample_event);

        if sampling_enabled(trigger) and sample_event then
            write_data_to_ram(ram_port_in_b, get_write_address(trigger), sampled_data);
        end if;

        if data_is_requested_from_address(bus_in, g_trigger_address) then
            write_data_to_address(bus_out, address => 0, data => 3);
            prime_trigger(trigger, samples_after_trigger);
        end if;
        
        if data_is_requested_from_address(bus_in, g_data_address) then
            calculate_read_address(trigger);
            request_data_from_ram(ram_port_in_a, get_sample_address(trigger));
        end if;

        if ram_read_is_ready(ram_port_out_a) then
            write_data_to_address(bus_out, address => 0, data => get_ram_data(ram_port_out_a));
        end if;
    end create_scope;

    signal sample_trigger : sample_trigger_record := init_trigger;

    signal ram_a_in  : ram_in_record;
    signal ram_a_out : ram_out_record;
    --------------------
    signal ram_b_in  : ram_in_record;
    signal ram_b_out : ram_out_record;

begin

    process(main_clock) is
    begin
        if rising_edge(main_clock) then
            init_ram(ram_a_in);
            init_ram(ram_b_in);
            init_bus(bus_from_signal_scope);

            connect_data_to_address(bus_in, bus_from_signal_scope, g_samples_after_trigger_address, samples_after_trigger);

            create_scope(sample_trigger
            , bus_in
            , bus_from_signal_scope
            , ram_a_in
            , ram_a_out
            , ram_b_in
            , ram_b_out
            , trigger_event1
            , sample_event1
            , sampled_data1
            );
        end if;
    end process;

    u_dpram : entity work.generic_dual_port_ram
    generic map(scope_ram_port_pkg)
    port map(
    main_clock ,
    ram_a_in   ,
    ram_a_out  ,
    --------------
    ram_b_in  ,
    ram_b_out);
------------------------------------------------------------------------
end rtl;
