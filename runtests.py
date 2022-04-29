import subprocess
import sys
import inspect 
import argparse
import json
import os

CRED = '\033[91m'
CGREEN  = '\33[32m'
CEND = '\033[0m'

def run_process(call_arr):
    process = subprocess.run(call_arr, 
                         stdout=subprocess.PIPE, 
                         universal_newlines=True)

    if (verbose):
        print(process.stdout)

    if "Error" in process.stdout or process.returncode != 0:
        print(CRED + "Test failed to compile\n" + CEND)
        print(process.stdout)
        return 0

    process = subprocess.run(['./simv'], 
                        stdout=subprocess.PIPE, 
                        universal_newlines=True)

    if (verbose):
        print(process.stdout)

    if "Failed" in process.stdout or "failed" in process.stdout or "Error" in process.stdout or "error" in process.stdout or "mismatch" in process.stdout:
        print(CRED + "Test failed\n" + CEND)
        print(process.stdout)
        return 0
    elif "Time: 0 ps" in process.stdout:
        print(CRED + "Test not implemented\n" + CEND)
        return 0
    else:
        print(CGREEN + "Test passed!\n" + CEND)
        return 1

# def test_conv_gold_test():
#     print("Running conv_gold_test")
#     process = subprocess.run(['make', 'compile_c'], 
#                          stdout=subprocess.PIPE, 
#                          universal_newlines=True)

#     if (verbose):
#         print(process.stdout)

#     if "Error" in process.stdout or process.returncode != 0:
#         print(CRED + "Test failed to compile\n" + CEND)
#         return 0, 0

#     process = subprocess.run(['make', 'run_c'], 
#                         stdout=subprocess.PIPE, 
#                         universal_newlines=True)

#     if (verbose):
#         print(process.stdout)

#     if "Error! Output does not match gold" in process.stdout:
#         print(CRED + "Test failed\n" + CEND)
#         return 1, 0
#     else:
#         print(CGREEN + "Test passed!\n" + CEND)
#         return 1, 1

# def test_conv_gold_tiled_test():
#     print("Running conv_gold_tiled_test")
#     process = subprocess.run(['make', 'compile_tiled_c'], 
#                          stdout=subprocess.PIPE, 
#                          universal_newlines=True)

#     if (verbose):
#         print(process.stdout)

#     if "Error" in process.stdout or process.returncode != 0:
#         print(CRED + "Test failed to compile\n" + CEND)
#         return 0, 0

#     process = subprocess.run(['make', 'run_tiled_c'], 
#                         stdout=subprocess.PIPE, 
#                         universal_newlines=True)

#     if (verbose):
#         print(process.stdout)

#     if "Error! Output does not match gold" in process.stdout:
#         print(CRED + "Test failed\n" + CEND)
#         return 1, 0
#     else:
#         print(CGREEN + "Test passed!\n" + CEND)
#         return 1, 1

# def test_mac_tb():
#     print("Running test_mac_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/mac_tb.v', 'rtl/mac.v'])          

# def test_mac_tb_uvm():
#     print("Running test_mac_tb_uvm")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'cpp/mac_gold.c', 'tests/mac_tb_uvm.v', 'rtl/mac.v'])          

# def test_skew_registers_tb():
#     print("Running test_skew_registers_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/skew_registers_tb.v', 'rtl/skew_registers.v'])

# def test_fifo_tb_uvm():
#     print("Running test_fifo_tb_uvm")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/fifo_tb_uvm.v', 'rtl/fifo.v', 'rtl/SizedFIFO.v'])

# def test_fifo_tb():
#     print("Running test_fifo_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/fifo_tb.v', 'rtl/fifo.v', 'rtl/SizedFIFO.v'])

# def test_async_fifo_tb():
#     print("Running test_fifo_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/async_fifo_tb.v', 'rtl/async_fifo.v'])

def test__gold_tb():
    print("Running gold model + generating files")
    
    return 1, run_process(['python3', './gold/gold.py', 'frame1ball_30', 'frame2ball_30', './'])


def test_internal_node_tb():
    print("Running test_internal_node_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/internal_node_tb.v', 'rtl/internal_node_2.v'])



# def test_new_async_fifo_tb():
#     print("Running test_fifo_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/new_async_fifo_tb.v', 'rtl/dual_clock_async_fifo_design.v'])

def test_bluespec_async_fifo_tb():
    print("Running bluespec_fifo_tb [IP BLOCK]")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/bluespec_async_fifo_tb.v', 'rtl/SyncFIFO.v'])

def test_aggregator_tb():
    print("Running test_aggregator_tb [IP BLOCK] ")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/aggregator_tb.v', 'rtl/aggregator.v', 'rtl/SyncFIFO.v'])


def test_query_sram_tb():
    print("Running query_row_double_buffer_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/search_containing_leaf_2_tb.v', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v'])

def test_query_wishbone_tb():
    print("Running query_wishbone_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/query_patch_wishbone_tb.v', 'rtl/QueryPatchMem_2.v', 'rtl/sram_1kbyte_1rw1r_mask.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v'])


# def test_search_containing_leaf_tb():
#     print("Running test_search_containing_leaf_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/search_containing_leaf_tb.v', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node.v', 'rtl/internal_node_tree.v'])


def test_internal_node_tree():
    print("Running internal_node_tree_tb (AKA search containing leaf with 2 patches)")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/search_containing_leaf_2_tb.v', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v'])


# def test_full_test_tb():
#     print("Running test_full_test_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/full_test_tb.v', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node.v', 'rtl/internal_node_tree.v', 'rtl/LeavesMem.sv', 'rtl/sram_1kbyte_1rw1r.v'])

def test_top_tb():
    print("Running test_top_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/top_tb.sv', 'rtl/top.sv', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v', 'rtl/LeavesMem.sv', 'rtl/BitonicSorter.sv', 'rtl/kBestArrays.sv', 'rtl/L2Kernel.sv', 'rtl/MainFSM.sv', 'rtl/RunningMin.sv', 'rtl/SyncFIFO.v', 'rtl/SortedList.sv'])





# def test_adr_gen_sequential_tb():
#     print("Running test_adr_gen_sequential_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/adr_gen_sequential_tb.v', 'rtl/adr_gen_sequential.v'])

# def test_adr_gen_sequential_tb_uvm():
#     print("Running test_adr_gen_sequential_tb_uvm")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/adr_gen_sequential_tb_uvm.v', 'rtl/adr_gen_sequential.v'])

# def test_ifmap_radr_gen_tb():
#     print("Running test_ifmap_radr_gen_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/ifmap_radr_gen_tb.v', 'rtl/ifmap_radr_gen.v'])

# def test_systolic_array_with_skew_tb():
#     print("Running test_systolic_array_with_skew_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/systolic_array_with_skew_tb.v', 'rtl/systolic_array_with_skew.v', 'rtl/skew_registers.v', 'rtl/systolic_array.v', 'rtl/mac.v'])

# def test_deaggregator_tb():
#     print("Running test_deaggregator_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/deaggregator_tb.v', 'rtl/deaggregator.v', 'rtl/dual_clock_async_fifo_design.v', 'rtl/fifo.v', 'rtl/SizedFIFO.v'])

# def test_double_buffer_tb():
#     print("Running test_double_buffer_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/double_buffer_tb.v', 'rtl/double_buffer.v', 'rtl/ram_sync_1r1w.v'])

# def test_accumulation_buffer_tb():
#     print("Running test_accumulation_buffer_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/accumulation_buffer_tb.v', 'rtl/accumulation_buffer.v', 'rtl/ram_sync_1r1w.v'])


# def test_conv_tb():
#     if "all" in args.layers:
#         args.layers = ["./layers/resnet_conv1_params.json", "./layers/resnet_conv2_x_params.json", "./layers/resnet_conv3_1_params.json", "./layers/resnet_conv3_x_params.json", "./layers/resnet_conv4_1_params.json", "./layers/resnet_conv4_x_params.json", "./layers/resnet_conv5_1_params.json", "./layers/resnet_conv5_x_params.json"]

#     run = 0
#     passed = 0
#     for layer in args.layers:
#         print("Running test_conv_tb with layer params:", layer)

#         with open(layer) as f:
#             data = json.load(f)

#         param_str_c = f'''const int IC0 = {data["IC0"]};
# const int OC0 = {data["OC0"]};
# const int IC1 = {data["IC1"]};
# const int OC1 = {data["OC1"]};
# const int FX = {data["FX"]};
# const int FY = {data["FY"]};
# const int OX0 = {data["OX0"]};
# const int OY0 = {data["OY0"]};
# const int OX1 = {data["OX1"]};
# const int OY1 = {data["OY1"]};
# const int STRIDE = {data["STRIDE"]}; 
# '''

#         param_str_v = f'''`define IC0 {data["IC0"]}
# `define OC0 {data["OC0"]}
# `define IC1 {data["IC1"]}
# `define OC1 {data["OC1"]}
# `define FX {data["FX"]}
# `define FY {data["FY"]}
# `define OX0 {data["OX0"]}
# `define OY0 {data["OY0"]}
# `define OX1 {data["OX1"]}
# `define OY1 {data["OY1"]}
# `define STRIDE {data["STRIDE"]}
# '''
    
#         with open("./cpp/conv_tb_params.h", "w") as output:
#             output.write(param_str_c)

#         with open("./tests/layer_params.v", "w") as output:
#             output.write(param_str_v)
                    
#         process = subprocess.run(['make', 'generate_layer'], 
#                             stdout=subprocess.PIPE, 
#                             universal_newlines=True)
#         if (verbose):
#             print(f'Layer params: IC0={data["IC0"]} OC0={data["OC0"]} IC1={data["IC1"]} OC1={data["OC1"]} FX={data["FX"]} FY={data["FY"]} OX0={data["OX0"]} OY0={data["OY0"]} OX1={data["OX1"]} OY1={data["OY1"]} STRIDE={data["STRIDE"]}')
#             print(process.stdout)

#         run += 1
#         passed += run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/conv_tb.v', 'rtl/conv.v', 'rtl/systolic_array_with_skew.v', 'rtl/skew_registers.v', 'rtl/systolic_array.v', 'rtl/mac.v', 'rtl/adr_gen_sequential.v', 'rtl/deaggregator.v', 'rtl/aggregator.v', 'rtl/fifo.v', 'rtl/SizedFIFO.v', 'rtl/conv_controller.v', 'rtl/accumulation_buffer.v', 'rtl/ram_sync_1r1w.v', 'rtl/ifmap_radr_gen.v', 'rtl/double_buffer.v'])
#     return run, passed


parser = argparse.ArgumentParser(description='Autograder for EE272 HW3')
parser.add_argument('tests', type=str, nargs='*', default=['all'],
                    help='list of tests you would like to run')
parser.add_argument("-l", "--layers", type=str, nargs='*', help='Layer specification files to run', default=["./layers/resnet_conv2_x_params.json"])
parser.add_argument("--list", action="store_true", help='List all tests')
parser.add_argument("-v", "--verbose", action="store_true", help='Verbose option for printing test output')

args = parser.parse_args()


verbose = args.verbose

all_tests = [obj for name,obj in inspect.getmembers(sys.modules[__name__]) 
                        if (inspect.isfunction(obj) and 
                            name.startswith('test') and
                            obj.__module__ == __name__)]


tests = []

if args.list:
    tests_names = [test.__name__ for test in all_tests]
    print(tests_names)
    exit()


if len(args.tests) == 0 or "all" in args.tests:
    tests = all_tests
else:
    for arg in args.tests:
        for test in all_tests:
            if arg in test.__name__:
                tests.append(test)

tests_names = [test.__name__ for test in tests]

print("Tests being run: ", tests_names)

tests_run = 0
tests_passed = 0

for test in tests:
    run, passed = test()
    tests_run += run
    tests_passed += passed

print("Tests passed:", tests_passed)
print("Tests run:", tests_run)
