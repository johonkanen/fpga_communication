echo off
SET source=%1

ghdl -a --ieee=synopsys --std=08 %source%\hVHDL_fpga_interconnect/interconnect_configuration/data_15_address_15_bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%\hVHDL_fpga_interconnect/fpga_interconnect_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%\hVHDL_uart/uart_rx/uart_rx_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%\hVHDL_uart/uart_tx/uart_tx_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%\hVHDL_uart/uart_protocol/uart_protocol_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%\communications.vhd
