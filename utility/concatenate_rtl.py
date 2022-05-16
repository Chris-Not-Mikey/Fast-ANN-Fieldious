import os


################################################################
#                   concatenate_rtl.PY                         #
################################################################
# Concatenates all relevant rtl code together for synthesis    # 
#                                                              #
# Author: Chris Calloway, cmc2734@stanford.edu                 #
# Maintainers: Chris Calloway, cmc2734@stanford.edu            #
#           Jake Ke, jakeke@stanford.edu                       #
################################################################

# Files that WILL NOT be synthesized 
# Anything else in rtl direcotrt will be synthesized
#skip_files = ["dual_clock_async_fifo_design.v", "internal_node.v", "fifo.v", "deaggregator.v", "async_fifo.v", "rtl_all.v", "QueryPatchMem_2.v",  ]


#Take from runtests.py for top level
allow_files = ['top.sv', 'ClockMux.v', 'ResetMux.v', 'SyncPulse.v', 'WishBoneCtrl.sv', 'QueryPatchMem.v',  'aggregator.v', 'sram_1kbyte_1rw1r.v', 'sky130_sram_1kbyte_1rw1r_32x256_8.v', 'internal_node_2.v', 'internal_node_tree_2.v', 'LeavesMem.sv', 'BitonicSorter.sv', 'kBestArrays.sv', 'L2Kernel.sv', 'MainFSM.sv', 'RunningMin.sv', 'SyncFIFO.v', 'SortedList.sv']


if __name__ == "__main__":

    directory = "../rtl"

    f_rtl_str = "rtl_all.v"

    f_rtl = open(f_rtl_str, "w")

    for filename in os.listdir(directory):
        f = os.path.join(directory, filename)
        # checking if it is a file
        

        if os.path.isfile(f) and filename in allow_files:
            print(f)

            with open(f, "r") as copy_file:

                for line in copy_file:
                    f_rtl.write(line)

                #Add a newline at the end incase it wasn't already there
                f_rtl.write("\n")
                f_rtl.write("\n")


            copy_file.close()



    f_rtl.close()
