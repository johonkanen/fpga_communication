use work.uart_rx_pkg.all;
use work.uart_tx_pkg.all;

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
                ,g_data_bit_width    => 16
                ,g_address_bit_width => 16
            );
