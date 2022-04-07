import subprocess
import sys
import inspect 
import argparse
import json

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
        return 0

    process = subprocess.run(['./simv'], 
                        stdout=subprocess.PIPE, 
                        universal_newlines=True)

    if (verbose):
        print(process.stdout)

    if "Failed" in process.stdout or "failed" in process.stdout or "Error" in process.stdout or "error" in process.stdout:
        print(CRED + "Test failed\n" + CEND)
        return 0
    elif "Time: 0 ps" in process.stdout:
        print(CRED + "Test not implemented\n" + CEND)
        return 0
    else:
        print(CGREEN + "Test passed!\n" + CEND)
        return 1

def test_conv_gold_test():
    print("Running conv_gold_test")
    process = subprocess.run(['make', 'compile_c'], 
                         stdout=subprocess.PIPE, 
                         universal_newlines=True)

    if (verbose):
        print(process.stdout)

    if "Error" in process.stdout or process.returncode != 0:
        print(CRED + "Test failed to compile\n" + CEND)
        return 0, 0

    process = subprocess.run(['make', 'run_c'], 
                        stdout=subprocess.PIPE, 
                        universal_newlines=True)

    if (verbose):
        print(process.stdout)

    if "Error! Output does not match gold" in process.stdout:
        print(CRED + "Test failed\n" + CEND)
        return 1, 0
    else:
        print(CGREEN + "Test passed!\n" + CEND)
        return 1, 1

def test_conv_gold_tiled_test():
    print("Running conv_gold_tiled_test")
    process = subprocess.run(['make', 'compile_tiled_c'], 
                         stdout=subprocess.PIPE, 
                         universal_newlines=True)

    if (verbose):
        print(process.stdout)

    if "Error" in process.stdout or process.returncode != 0:
        print(CRED + "Test failed to compile\n" + CEND)
        return 0, 0

    process = subprocess.run(['make', 'run_tiled_c'], 
                        stdout=subprocess.PIPE, 
                        universal_newlines=True)

    if (verbose):
        print(process.stdout)

    if "Error! Output does not match gold" in process.stdout:
        print(CRED + "Test failed\n" + CEND)
        return 1, 0
    else:
        print(CGREEN + "Test passed!\n" + CEND)
        return 1, 1

def test_mac_tb():
    print("Running test_mac_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/mac_tb.v', 'verilog/mac.v'])          

def test_mac_tb_uvm():
    print("Running test_mac_tb_uvm")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'cpp/mac_gold.c', 'tests/mac_tb_uvm.v', 'verilog/mac.v'])          

def test_skew_registers_tb():
    print("Running test_skew_registers_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/skew_registers_tb.v', 'verilog/skew_registers.v'])

def test_fifo_tb_uvm():
    print("Running test_fifo_tb_uvm")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/fifo_tb_uvm.v', 'verilog/fifo.v', 'verilog/SizedFIFO.v'])

def test_fifo_tb():
    print("Running test_fifo_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/fifo_tb.v', 'verilog/fifo.v', 'verilog/SizedFIFO.v'])

def test_ram_sync_1r1w_tb_uvm():
    print("Running test_ram_sync_1r1w_tb_uvm")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/ram_sync_1r1w_tb_uvm.v', 'verilog/ram_sync_1r1w.v'])

def test_aggregator_tb():
    print("Running test_aggregator_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/aggregator_tb.v', 'verilog/aggregator.v', 'verilog/fifo.v', 'verilog/SizedFIFO.v'])

def test_adr_gen_sequential_tb():
    print("Running test_adr_gen_sequential_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/adr_gen_sequential_tb.v', 'verilog/adr_gen_sequential.v'])

def test_adr_gen_sequential_tb_uvm():
    print("Running test_adr_gen_sequential_tb_uvm")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/adr_gen_sequential_tb_uvm.v', 'verilog/adr_gen_sequential.v'])

def test_ifmap_radr_gen_tb():
    print("Running test_ifmap_radr_gen_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/ifmap_radr_gen_tb.v', 'verilog/ifmap_radr_gen.v'])

def test_systolic_array_with_skew_tb():
    print("Running test_systolic_array_with_skew_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/systolic_array_with_skew_tb.v', 'verilog/systolic_array_with_skew.v', 'verilog/skew_registers.v', 'verilog/systolic_array.v', 'verilog/mac.v'])

def test_deaggregator_tb():
    print("Running test_deaggregator_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/deaggregator_tb.v', 'verilog/deaggregator.v', 'verilog/fifo.v', 'verilog/SizedFIFO.v'])

def test_double_buffer_tb():
    print("Running test_double_buffer_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/double_buffer_tb.v', 'verilog/double_buffer.v', 'verilog/ram_sync_1r1w.v'])

def test_accumulation_buffer_tb():
    print("Running test_accumulation_buffer_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/accumulation_buffer_tb.v', 'verilog/accumulation_buffer.v', 'verilog/ram_sync_1r1w.v'])


def test_conv_tb():
    if "all" in args.layers:
        args.layers = ["./layers/resnet_conv1_params.json", "./layers/resnet_conv2_x_params.json", "./layers/resnet_conv3_1_params.json", "./layers/resnet_conv3_x_params.json", "./layers/resnet_conv4_1_params.json", "./layers/resnet_conv4_x_params.json", "./layers/resnet_conv5_1_params.json", "./layers/resnet_conv5_x_params.json"]

    run = 0
    passed = 0
    for layer in args.layers:
        print("Running test_conv_tb with layer params:", layer)

        with open(layer) as f:
            data = json.load(f)

        param_str_c = f'''const int IC0 = {data["IC0"]};
const int OC0 = {data["OC0"]};
const int IC1 = {data["IC1"]};
const int OC1 = {data["OC1"]};
const int FX = {data["FX"]};
const int FY = {data["FY"]};
const int OX0 = {data["OX0"]};
const int OY0 = {data["OY0"]};
const int OX1 = {data["OX1"]};
const int OY1 = {data["OY1"]};
const int STRIDE = {data["STRIDE"]}; 
'''

        param_str_v = f'''`define IC0 {data["IC0"]}
`define OC0 {data["OC0"]}
`define IC1 {data["IC1"]}
`define OC1 {data["OC1"]}
`define FX {data["FX"]}
`define FY {data["FY"]}
`define OX0 {data["OX0"]}
`define OY0 {data["OY0"]}
`define OX1 {data["OX1"]}
`define OY1 {data["OY1"]}
`define STRIDE {data["STRIDE"]}
'''
    
        with open("./cpp/conv_tb_params.h", "w") as output:
            output.write(param_str_c)

        with open("./tests/layer_params.v", "w") as output:
            output.write(param_str_v)
                    
        process = subprocess.run(['make', 'generate_layer'], 
                            stdout=subprocess.PIPE, 
                            universal_newlines=True)
        if (verbose):
            print(f'Layer params: IC0={data["IC0"]} OC0={data["OC0"]} IC1={data["IC1"]} OC1={data["OC1"]} FX={data["FX"]} FY={data["FY"]} OX0={data["OX0"]} OY0={data["OY0"]} OX1={data["OX1"]} OY1={data["OY1"]} STRIDE={data["STRIDE"]}')
            print(process.stdout)

        run += 1
        passed += run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/conv_tb.v', 'verilog/conv.v', 'verilog/systolic_array_with_skew.v', 'verilog/skew_registers.v', 'verilog/systolic_array.v', 'verilog/mac.v', 'verilog/adr_gen_sequential.v', 'verilog/deaggregator.v', 'verilog/aggregator.v', 'verilog/fifo.v', 'verilog/SizedFIFO.v', 'verilog/conv_controller.v', 'verilog/accumulation_buffer.v', 'verilog/ram_sync_1r1w.v', 'verilog/ifmap_radr_gen.v', 'verilog/double_buffer.v'])
    return run, passed


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
