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

lib.add_source_files(ROOT / "communications.vhd")

lib.add_source_files(ROOT / "serial_protocol_test_pkg.vhd")
lib.add_source_files(ROOT / "testbenches/uart_communication/uart_communication_tb.vhd")
lib.add_source_files(ROOT / "testbenches/uart_communication/uart_comm_32_bit_tb.vhd")

# signal_scope, its ram and trigger from hVHDL_memory_library
memory = ROOT / "hVHDL_memory_library"
lib.add_source_files(ROOT / "fpga_interconnect_16bit_pkg.vhd")
lib.add_source_files(memory / "vhdl2008/dp_ram_w_configurable_records.vhd")
lib.add_source_files(memory / "vhdl2008/arch_sim_dp_ram_w_configurable_records.vhd")
lib.add_source_files(memory / "sample_buffer/sample_trigger_generic_pkg.vhd")
lib.add_source_files(ROOT / "signal_scope/signal_scope.vhd")
lib.add_source_files(ROOT / "testbenches/signal_scope/signal_scope_tb.vhd")
VU.set_sim_option("nvc.sim_flags", ["-w", "--dump-arrays"])
# VU.set_sim_option("nvc.sim_flags", [""])
VU.main()
