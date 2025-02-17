#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv(compile_builtins=True, vhdl_standard="2008")

lib = VU.add_library("lib")
lib.add_source_files(ROOT / "hVHDL_uart/uart_rx/uart_rx_pkg.vhd")
lib.add_source_files(ROOT / "hVHDL_uart/uart_tx/uart_tx_pkg.vhd")
lib.add_source_files(ROOT / "serial_protocol_generic_pkg.vhd")

lib.add_source_files(ROOT / "hVHDL_fpga_interconnect/fpga_interconnect_generic_pkg.vhd")
lib.add_source_files(ROOT / "fpga_interconnect_16bit_pkg.vhd")

lib.add_source_files(ROOT / "uart_protocol_pkg.vhd")
lib.add_source_files(ROOT / "communications.vhd")

lib.add_source_files(ROOT / "serial_protocol_test_pkg.vhd")
lib.add_source_files(ROOT / "testbenches/uart_communication/uart_communication_tb.vhd")
VU.set_sim_option("nvc.sim_flags", ["-w"])
VU.main()
