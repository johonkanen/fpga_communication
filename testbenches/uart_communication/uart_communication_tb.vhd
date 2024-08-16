LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.fpga_interconnect_pkg.all;
    use work.uart_rx_pkg.all;
    use work.uart_tx_pkg.all;
    use work.uart_protocol_pkg.all;

entity uart_communication_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of uart_communication_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal bus_in  : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_out  : fpga_interconnect_record := init_fpga_interconnect;

    signal uart_rx_data_in  : uart_rx_data_input_group := (number_of_clocks_per_bit => 24);
    signal uart_rx_data_out : uart_rx_data_output_group;

    signal uart_tx_data_in    : uart_tx_data_input_group := init_uart_tx(24);
    signal uart_tx_data_out   : uart_tx_data_output_group;
    signal uart_protocol : serial_communcation_record := init_serial_communcation;

    signal number_of_registers_to_stream : integer range 0 to 2**23-1 := 0;
    signal stream_address : integer range 0 to 2**16-1 := 0;

    signal fpga_controlled_stream_requested : boolean := false;

    signal bus_to_communications : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;


    constant g_clock_divider : integer := 24;


    signal uart_rx : std_logic;
    signal uart_tx : std_logic;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    test_uart : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            init_bus(bus_out);
            init_uart(uart_tx_data_in, g_clock_divider);
            set_number_of_clocks_per_bit(uart_rx_data_in, g_clock_divider);
            create_serial_protocol(uart_protocol, uart_rx_data_out, uart_tx_data_in, uart_tx_data_out);

            ------------------------------------------------------------------------
            if frame_has_been_received(uart_protocol) then
                CASE get_command(uart_protocol) is
                    WHEN read_is_requested_from_address_from_uart =>
                        request_data_from_address(bus_out, get_command_address(uart_protocol));

                    WHEN write_to_address_is_requested_from_uart =>
                        write_data_to_address(bus_out, get_command_address(uart_protocol), get_command_data(uart_protocol));

                    WHEN stream_data_from_address =>
                        number_of_registers_to_stream <= get_number_of_registers_to_stream(uart_protocol);
                        stream_address                <= get_command_address(uart_protocol);
                        request_data_from_address(bus_out, get_command_address(uart_protocol));
                        fpga_controlled_stream_requested <= false;

                    WHEN request_stream_from_address =>
                        request_data_from_address(bus_out, get_command_address(uart_protocol));
                        number_of_registers_to_stream <= get_number_of_registers_to_stream(uart_protocol);
                        fpga_controlled_stream_requested <= true;

                    WHEN others => -- do nothing
                end CASE;
            end if;

            if number_of_registers_to_stream > 0 then
                if not fpga_controlled_stream_requested then
                    if transmit_is_ready(uart_protocol) then
                        request_data_from_address(bus_out, stream_address);
                    end if;
                end if;

                if write_to_address_is_requested(bus_in, 0) then
                    number_of_registers_to_stream <= number_of_registers_to_stream - 1;
                    send_stream_data_packet(uart_protocol, get_data(bus_in));
                    if number_of_registers_to_stream = 1 then
                        fpga_controlled_stream_requested <= false;
                    end if;
                end if;
            else
                if write_to_address_is_requested(bus_in, 0) then
                    transmit_words_with_uart(uart_protocol, write_data_to_register(address => 0, data => get_data(bus_in)));
                end if;
            end if;
            
        end if; -- rising_edge
    end process test_uart;	
------------------------------------------------------------------------
    u_uart_rx : entity work.uart_rx
    port map(clock => simulator_clock   ,
          uart_rx_FPGA_in.uart_rx => uart_rx ,
    	  uart_rx_data_in  => uart_rx_data_in     ,
    	  uart_rx_data_out => uart_rx_data_out); 
------------------------------------------------------------------------
    u_uart_tx : entity work.uart_tx
        port map(clock => simulator_clock               ,
          uart_tx_fpga_out.uart_tx => uart_tx ,
    	  uart_tx_data_in => uart_tx_data_in  ,
    	  uart_tx_data_out => uart_tx_data_out);
------------------------------------------------------------------------
    communications_under_test : entity work.fpga_communications
    generic map(fpga_interconnect_pkg => work.fpga_interconnect_pkg)
        port map(
            clock => simulator_clock                              ,
            uart_rx                 => uart_rx               ,
            uart_tx                 => uart_tx               ,
            bus_to_communications   => bus_to_communications ,
            bus_from_communications => bus_from_communications
        );
------------------------------------------------------------------------
end vunit_simulation;
