library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity fpga_communications is
    generic(
                package fpga_interconnect_pkg is new work.fpga_interconnect_generic_pkg generic map(<>)
                ;g_clock_divider : natural := 24
            );
    port (
        clock : in std_logic;
        uart_rx : in std_logic;
        uart_tx : out std_logic;
        bus_to_communications : in fpga_interconnect_pkg.fpga_interconnect_record;
        bus_from_communications : out fpga_interconnect_pkg.fpga_interconnect_record
    );
end entity fpga_communications;

architecture rtl of fpga_communications is
    
    use work.uart_rx_pkg.all;
    use work.uart_tx_pkg.all;
    use fpga_interconnect_pkg.all;

    package uart_protocol_pkg is new work.serial_protocol_generic_pkg
    generic map(serial_rx_data_output_record => uart_rx_data_output_group
                ,serial_tx_data_input_record  => uart_tx_data_input_group
                ,serial_tx_data_output_record => uart_tx_data_output_group
                --------------------------------
                ,serial_rx_data_is_ready => uart_rx_data_is_ready
                --------------------------------
                ,get_serial_rx_data => get_uart_rx_data
                --------------------------------
                ,init_serial => init_uart
                --------------------------------
                ,transmit_8bit_data_package => transmit_8bit_data_package
                --------------------------------
                ,serial_tx_is_ready  => uart_tx_is_ready
                ,g_data_bit_width    => bus_to_communications.data'length
                ,g_address_bit_width => bus_to_communications.address'length
            );

    use uart_protocol_pkg.all;
    alias bus_in  is bus_to_communications;
    alias bus_out is bus_from_communications;

    signal uart_rx_data_in  : uart_rx_data_input_group;
    signal uart_rx_data_out : uart_rx_data_output_group;

    signal uart_tx_data_in  : uart_tx_data_input_group;
    signal uart_tx_data_out : uart_tx_data_output_group;
    signal uart_protocol    : serial_communcation_record := init_serial_communcation;

    signal number_of_registers_to_stream : integer range 0 to 2**23-1 := 0;
    signal stream_address : integer range 0 to 2**16-1 := 0;

    signal fpga_controlled_stream_requested : boolean := false;

begin

------------------------------------------------------------------------
------------------------------------------------------------------------
    test_uart : process(clock)
    begin
        if rising_edge(clock) then

            init_bus(bus_out);
            create_serial_protocol(uart_protocol, uart_rx_data_out, uart_tx_data_in, uart_tx_data_out);
            set_number_of_clocks_per_bit(uart_tx_data_in, g_clock_divider);
            set_number_of_clocks_per_bit(uart_rx_data_in, g_clock_divider);

            ------------------------------------------------------------------------
            if frame_has_been_received(uart_protocol) then
                CASE get_command(uart_protocol) is
                    WHEN read_is_requested_from_address_from_serial =>
                        request_data_from_address(bus_out, get_command_address(uart_protocol));

                    WHEN write_to_address_is_requested_from_serial =>
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
                    respond_to_data_request(uart_protocol, write_data_to_register(address => 0, data => get_data(bus_in)));
                end if;
            end if;
            
        end if; -- rising_edge
    end process test_uart;	
------------------------------------------------------------------------
    u_uart_rx : entity work.uart_rx
    port map(clock => clock                    
        ,uart_rx_FPGA_in.uart_rx => uart_rx         
        ,uart_rx_data_in         => uart_rx_data_in 
        ,uart_rx_data_out        => uart_rx_data_out);
------------------------------------------------------------------------
    u_uart_tx : entity work.uart_tx
        port map(clock => clock                     
        ,uart_tx_fpga_out.uart_tx => uart_tx         
        ,uart_tx_data_in          => uart_tx_data_in 
        ,uart_tx_data_out         => uart_tx_data_out);
------------------------------------------------------------------------
end rtl;
