#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv(compile_builtins=True, vhdl_standard="2008")

lib = VU.add_library("lib")
lib.add_source_files(ROOT / "testbenches/uart_communication/uart_communication_pkg.vhd")
VU.set_sim_option("nvc.sim_flags", ["-w"])
VU.main()
