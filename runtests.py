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

    if "Failed" in process.stdout or "failed" in process.stdout or "Error" in process.stdout or "error" in process.stdout:
        print(CRED + "Test failed\n" + CEND)
        print(process.stdout)
        return 0
    elif "Time: 0 ps" in process.stdout:
        print(CRED + "Test not implemented\n" + CEND)
        return 0
    else:
        print(CGREEN + "Test passed!\n" + CEND)
        return 1
    
    
def run_python_process(call_arr):
    process = subprocess.run(call_arr, 
                         stdout=subprocess.PIPE, 
                         universal_newlines=True)

    if (verbose):
        print(process.stdout)

    if "failed" in process.stdout:
        print(CRED + "Test failed\n" + CEND)
        print(process.stdout)
        return 0
    
    print(CGREEN + "Test passed!\n" + CEND)
    return 1

#     process = subprocess.run(['./simv'], 
#                         stdout=subprocess.PIPE, 
#                         universal_newlines=True)

#     if (verbose):
#         print(process.stdout)

#     if "Failed" in process.stdout or "failed" in process.stdout or "Error" in process.stdout or "error" in process.stdout or "mismatch" in process.stdout:
#         print(CRED + "Test failed\n" + CEND)
#         print(process.stdout)
#         return 0
#     elif "Time: 0 ps" in process.stdout:
#         print(CRED + "Test not implemented\n" + CEND)
#         return 0
#     else:
#         print(CGREEN + "Test passed!\n" + CEND)
#         return 1

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
    
    return 1, run_python_process(['python3', './gold/gold.py', args.images[0], args.images[1], './data/IO_data/']) #/data/IODATA ensures our testbenches read the right file

def test_z_l2_reconstruct_tb():
    print("Running l2 on final results and reconstructing image")
    
    return 1, run_python_process(['python3', './gold/l2.py', args.images[0], args.images[1]])


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
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/query_row_double_buffer_tb.v', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v'])

def test_query_wishbone_tb():
    print("Running query_wishbone_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/query_patch_wishbone_tb.v', 'rtl/QueryPatchMem_2.v', 'rtl/sram_1kbyte_1rw1r_mask.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v'])


def test_sorted_list_tb():
    print("Running sorted_list_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/SortedList_tb.sv', 'rtl/SortedList.sv'])

def test_sorter_tb():
    print("Running sorter_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/Sorter_tb.sv', 'rtl/BitonicSorter.sv'])

def test_l2_kernel_tb():
    print("Running l2_kernel_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/L2Kernel_tb.sv', 'rtl/L2Kernel.sv'])

def test_wbs_ctrl_tb():
    print("Running wbs_ctrl_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/WishBoneCtrl_tb.sv', 'rtl/WishBoneCtrl.sv', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v'])


# def test_search_containing_leaf_tb():
#     print("Running test_search_containing_leaf_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/search_containing_leaf_tb.v', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node.v', 'rtl/internal_node_tree.v'])


def test_internal_node_tree():
    print("Running internal_node_tree_tb (AKA search containing leaf with 2 patches)")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/search_containing_leaf_2_tb.v', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v'])


def test_dffram_tb():
    print("Running dffram_tb (AKA search containing leaf but with DFFRAM instead of SRAM)")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/dffram_tb.sv', 'rtl/QueryPatchDFFRAM.sv',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/dffram_wrapper.v', 'rtl/RAM256x32.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v'])

 


# def test_full_test_tb():
#     print("Running test_full_test_tb")
#     return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/full_test_tb.v', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/SyncFIFO.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node.v', 'rtl/internal_node_tree.v', 'rtl/LeavesMem.sv', 'rtl/sram_1kbyte_1rw1r.v'])

def test_top_tb():
    print("Running test_top_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/top_tb.sv', 'rtl/top.sv', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v', 'rtl/LeavesMem.sv', 'rtl/BitonicSorter.sv', 'rtl/kBestArrays.sv', 'rtl/L2Kernel.sv', 'rtl/MainFSM.sv', 'rtl/RunningMin.sv', 'rtl/SyncFIFO.v', 'rtl/SortedList.sv'])

def test_top_multi_tb():
    print("Running test_top_multi_tb")
    run_python_process(['python3', './gold/gold.py', args.images[0], args.images[1], './data/IO_data/', 'multi'])
    run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/top_multi_tb.sv', 'rtl/top.sv', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v', 'rtl/LeavesMem.sv', 'rtl/BitonicSorter.sv', 'rtl/kBestArrays.sv', 'rtl/L2Kernel.sv', 'rtl/MainFSM.sv', 'rtl/RunningMin.sv', 'rtl/SyncFIFO.v', 'rtl/SortedList.sv'])
    run_python_process(['python3', './gold/l2.py', args.images[0], args.images[1], "0"])
    
    return 1, run_python_process(['python3', './gold/l2.py', "stick1", "stick2", "1"])


def test_top_wrapper_multi_tb():
    print("Running test_top_wrapper_multi_tb")
    run_python_process(['python3', './gold/gold.py', args.images[0], args.images[1], './data/IO_data/', 'multi'])
    run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/top_wrapper_multi_tb.sv', 'rtl/user_proj_example.v', 'rtl/SyncPulse.v', 'rtl/SyncBit.v', 'rtl/ClockMux.v', 'rtl/ResetMux.v', 'rtl/WishBoneCtrl.sv',  'rtl/top.sv', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v', 'rtl/LeavesMem.sv', 'rtl/BitonicSorter.sv', 'rtl/kBestArrays.sv', 'rtl/L2Kernel.sv', 'rtl/MainFSM.sv', 'rtl/RunningMin.sv', 'rtl/SyncFIFO.v', 'rtl/SortedList.sv'])

    
    
    images_a_storage = ['Avatar FULL 1080p 00402', 'Avatar FULL 1080p 00907', 'Avatar FULL 1080p 01223', 'Avatar FULL 1080p 01361', 'Avatar FULL 1080p 01748', 'Avatar FULL 1080p 02162', 'Avatar FULL 1080p 03274', 'Avatar FULL 1080p 03365', 'Avatar FULL 1080p 04250', 'Avatar FULL 1080p 04275', 'Avatar FULL 1080p 04302', 'Avatar FULL 1080p 04414', 'Avatar FULL 1080p 04663', 'Avatar FULL 1080p 04770', 'Avatar FULL 1080p 04884', 'Avatar FULL 1080p 05160', 'Avatar FULL 1080p 05433', 'Avatar FULL 1080p 05446', 'Avatar FULL 1080p 05565', 'Avatar FULL 1080p 05672', 'Avatar FULL 1080p 05745', 'Avatar FULL 1080p 05952', 'Avatar FULL 1080p 06004', 'Jackass 3D 0189', 'Jackass 3D 0415', 'Jackass 3D 0995', 'Jackass 3D 1256', 'Jackass 3D 1736', 'Little Fockers 0885', 'Little Fockers 0933', 'Little Fockers 2675', 'Mortal Combat 0481', 'Mortal Combat 0524', 'Mortal Combat 0663', 'Mortal Combat 0839', 'Mortal Combat 0917', 'Mortal Combat 0943', 'Mortal Combat 0998', 'Mortal Combat 1044', 'Mortal Combat 1059', 'Mortal Combat 1107', 'Mortal Combat 1116', 'Mortal Combat 1310', 'Mortal Combat 1409', 'Mortal Combat 1441', 'Mortal Combat 1452', 'Mortal Combat 1469', 'Mortal Combat 1552', 'Mortal Combat 1607', 'Mortal Combat 1672', 'Never back down 0351', 'Never back down 0382', 'Never back down 0485', 'Never back down 0543', 'Never back down 0581', 'Never back down 0689', 'Never back down 0727', 'Never back down 0798', 'Never back down 0994', 'Never back down 1032', 'Never back down 1413', 'Never back down 1577', 'Never back down 1776', 'Never back down 1979', 'Never back down 2046', 'Never back down 2115', 'Never back down 2829', 'Pressure Cooker 0137', 'Pressure Cooker 0222', 'Pressure Cooker 0363', 'Pressure Cooker 0557', 'Pressure Cooker 1118', 'Pressure Cooker 1233', 'Pressure Cooker 1347', 'Pressure Cooker 1412', 'Pressure Cooker 1494', 'Pressure Cooker 1554', 'Pressure Cooker 1734', 'Pressure Cooker 1864', 'Pressure Cooker 2050', 'Pressure Cooker 2196', 'Pressure Cooker 2410', 'Pressure Cooker 2414', 'Pressure Cooker 2737', 'Prince Of Persia 0580', 'Prince Of Persia 0605', 'Prince Of Persia 0777', 'Prince Of Persia 1280', 'Prince Of Persia 1317', 'Prince Of Persia 1371', 'Prince Of Persia 1523', 'Prince Of Persia 1620', 'Prince Of Persia 1854', 'Prince Of Persia 1935', 'Prince Of Persia 1952', 'Prince Of Persia 1994', 'Prince Of Persia 2209', 'Prince Of Persia 2379', 'Prince Of Persia 2497', 'Prince Of Persia 2552', 'Prince Of Persia 2742', 'Prince Of Persia 2814', 'Prince Of Persia 2846', 'Prince Of Persia 2985', 'Prince Of Persia 2995', 'Prince Of Persia 3041', 'Prince Of Persia 3054', 'Prince Of Persia 3080', 'Prince Of Persia 3180', 'Prince Of Persia 3221', 'Prince Of Persia 3248', 'Prince Of Persia 3793', 'Prince Of Persia 3973', 'Prince Of Persia 3995', 'Prince Of Persia 4120', 'Resident Evil Afterlife 0245', 'Resident Evil Afterlife 0476', 'Resident Evil Afterlife 1001', 'Resident Evil Afterlife 1083', 'Resident Evil Afterlife 1458', 'Resident Evil Afterlife 1709', 'Resident Evil Afterlife 2217', 'Resident Evil Afterlife 2613', 'Resident Evil Afterlife 3060', 'Resident Evil Afterlife 3235', 'Resident Evil Afterlife1785']
    images_b_storage = ['Avatar FULL 1080p 00426', 'Avatar FULL 1080p 00942', 'Avatar FULL 1080p 01264', 'Avatar FULL 1080p 01376', 'Avatar FULL 1080p 01786', 'Avatar FULL 1080p 02200', 'Avatar FULL 1080p 03299', 'Avatar FULL 1080p 03379', 'Avatar FULL 1080p 04269', 'Avatar FULL 1080p 04285', 'Avatar FULL 1080p 04321', 'Avatar FULL 1080p 04422', 'Avatar FULL 1080p 04688', 'Avatar FULL 1080p 04791', 'Avatar FULL 1080p 04887', 'Avatar FULL 1080p 05175', 'Avatar FULL 1080p 05444', 'Avatar FULL 1080p 05459', 'Avatar FULL 1080p 05579', 'Avatar FULL 1080p 05683', 'Avatar FULL 1080p 05755', 'Avatar FULL 1080p 05962', 'Avatar FULL 1080p 06026', 'Jackass 3D 0215', 'Jackass 3D 0437', 'Jackass 3D 1026', 'Jackass 3D 1304', 'Jackass 3D 1778', 'Little Fockers 0902', 'Little Fockers 0965', 'Little Fockers 2810', 'Mortal Combat 0520', 'Mortal Combat 0564', 'Mortal Combat 0687', 'Mortal Combat 0857', 'Mortal Combat 0925', 'Mortal Combat 0959', 'Mortal Combat 1019', 'Mortal Combat 1049', 'Mortal Combat 1069', 'Mortal Combat 1115', 'Mortal Combat 1123', 'Mortal Combat 1315', 'Mortal Combat 1418', 'Mortal Combat 1445', 'Mortal Combat 1464', 'Mortal Combat 1483', 'Mortal Combat 1575', 'Mortal Combat 1614', 'Mortal Combat 1692', 'Never back down 0367', 'Never back down 0398', 'Never back down 0500', 'Never back down 0556', 'Never back down 0604', 'Never back down 0707', 'Never back down 0743', 'Never back down 0820', 'Never back down 0999', 'Never back down 1213', 'Never back down 1432', 'Never back down 1634', 'Never back down 1783', 'Never back down 2040', 'Never back down 2066', 'Never back down 2131', 'Never back down 2846', 'Pressure Cooker 0155', 'Pressure Cooker 0246', 'Pressure Cooker 0416', 'Pressure Cooker 0596', 'Pressure Cooker 1137', 'Pressure Cooker 1254', 'Pressure Cooker 1368', 'Pressure Cooker 1450', 'Pressure Cooker 1527', 'Pressure Cooker 1589', 'Pressure Cooker 1773', 'Pressure Cooker 1922', 'Pressure Cooker 2089', 'Pressure Cooker 2200', 'Pressure Cooker 2411', 'Pressure Cooker 2461', 'Pressure Cooker 2751', 'Prince Of Persia 0598', 'Prince Of Persia 0632', 'Prince Of Persia 0789', 'Prince Of Persia 1287', 'Prince Of Persia 1331', 'Prince Of Persia 1389', 'Prince Of Persia 1573', 'Prince Of Persia 1648', 'Prince Of Persia 1884', 'Prince Of Persia 1951', 'Prince Of Persia 1963', 'Prince Of Persia 2006', 'Prince Of Persia 2214', 'Prince Of Persia 2395', 'Prince Of Persia 2515', 'Prince Of Persia 2571', 'Prince Of Persia 2751', 'Prince Of Persia 2815', 'Prince Of Persia 2854', 'Prince Of Persia 2994', 'Prince Of Persia 3013', 'Prince Of Persia 3053', 'Prince Of Persia 3067', 'Prince Of Persia 3087', 'Prince Of Persia 3204', 'Prince Of Persia 3247', 'Prince Of Persia 3360', 'Prince Of Persia 3808', 'Prince Of Persia 3987', 'Prince Of Persia 4010', 'Prince Of Persia 4133', 'Resident Evil Afterlife 0327', 'Resident Evil Afterlife 0479', 'Resident Evil Afterlife 1006', 'Resident Evil Afterlife 1096', 'Resident Evil Afterlife 1487', 'Resident Evil Afterlife 1719', 'Resident Evil Afterlife 2231', 'Resident Evil Afterlife 2631', 'Resident Evil Afterlife 3085', 'Resident Evil Afterlife 3247', 'Resident Evil Afterlife1797']

    counter = 0
    for img in range(len(images_a_storage)):
        
        gold_idx = counter + 1
        run_python_process(['python3', './gold/l2.py', images_a_storage[counter], images_b_storage[counter] , str(gold_idx)])
        counter = counter + 1
    
    
    #final arg (for example 1, or 4) means which image pair in the list that it is (see goldmodel for list)
    
    return 1, run_python_process(['python3', './gold/l2.py', args.images[0], args.images[1], "0"])


def test_top_wrapper_tb():
    print("Running test_wrapper_top_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/top_wrapper_tb.sv', 'rtl/user_proj_example.v', 'rtl/SyncPulse.v', 'rtl/SyncBit.v', 'rtl/ClockMux.v', 'rtl/ResetMux.v', 'rtl/WishBoneCtrl.sv',  'rtl/top.sv', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v', 'rtl/LeavesMem.sv', 'rtl/BitonicSorter.sv', 'rtl/kBestArrays.sv', 'rtl/L2Kernel.sv', 'rtl/MainFSM.sv', 'rtl/RunningMin.sv', 'rtl/SyncFIFO.v', 'rtl/SortedList.sv'])

def test_top_wbs_wrapper_tb():
    print("Running test_wbs_wrapper_top_tb")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/top_wbs_wrapper_tb.sv', 'rtl/user_proj_example.v', 'rtl/SyncPulse.v', 'rtl/SyncBit.v', 'rtl/ClockMux.v', 'rtl/ResetMux.v', 'rtl/WishBoneCtrl.sv',  'rtl/top.sv', 'rtl/QueryPatchMem.v',  'rtl/aggregator.v', 'rtl/sram_1kbyte_1rw1r.v', 'rtl/sky130_sram_1kbyte_1rw1r_32x256_8.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v', 'rtl/LeavesMem.sv', 'rtl/BitonicSorter.sv', 'rtl/kBestArrays.sv', 'rtl/L2Kernel.sv', 'rtl/MainFSM.sv', 'rtl/RunningMin.sv', 'rtl/SyncFIFO.v', 'rtl/SortedList.sv'])



def test_top_dffram_tb():
    print("Running test_top_tb but with DFFRAM instead of SRAM")
    return 1, run_process(['vcs', '-full64', '-sverilog', '-timescale=1ns/1ps', '-debug_access+pp', 'tests/top_tb.sv', 'rtl/top_dffram.sv', 'rtl/QueryPatchDFFRAM.sv',  'rtl/aggregator.v', 'rtl/dffram_wrapper.v',  'rtl/RAM256x32.v', 'rtl/internal_node_2.v', 'rtl/internal_node_tree_2.v', 'rtl/LeavesMemDFFRAM.sv', 'rtl/BitonicSorter.sv', 'rtl/kBestArraysDFFRAM.sv', 'rtl/L2Kernel.sv', 'rtl/MainFSM.sv', 'rtl/RunningMin.sv', 'rtl/SyncFIFO.v', 'rtl/SortedList.sv'])





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


parser = argparse.ArgumentParser(description='Fast ANN Fieldious Test Suite (Based on Autograder for EE272 HW3)')
parser.add_argument('tests', type=str, nargs='*', default=['all'],
                    help='list of tests you would like to run')
parser.add_argument("-l", "--layers", type=str, nargs='*', help='Layer specification files to run', default=["./layers/resnet_conv2_x_params.json"])
parser.add_argument("-i", "--images", type=str, nargs='*', help='Images A and B (respectively)', default=["frame1ball_30", "frame2ball_30"])


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
