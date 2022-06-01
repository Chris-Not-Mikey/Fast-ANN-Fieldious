from kratos import *
'''
8-to-4 Bitonic Sort
The outputs[3:0] are sorted with [3] being the largest and [0] being the smallest
'''

class BitonicSorter(Generator):
    def __init__(self,
                 data_width=25,
                 idx_width=9,
                 channel_num=8,
                 patch_size=5,
                 num_leaves=64,
                 row=30,
                 height=23):
        super().__init__("BitonicSorter", False)
        self.data_width = data_width
        self.idx_width = idx_width
        self.channel_num = channel_num
        self.patch_size = patch_size
        self.num_leaves = num_leaves
        self.row = row
        self.height = height

        self.total_patches = (self.row - self.patch_size + 1) * (self.height - self.patch_size + 1)
        self.stages = clog2(self.channel_num)
        self.out_num = 4
        self.leaf_addrw = clog2(self.num_leaves)

        # inputs
        self._clk = self.clock("clk")
        self._rst_n = self.reset("rst_n", 1)

        self._valid_in = self.input("valid_in", 1)
        self._data_in = []
        self._idx_in = []
        for i in range(self.channel_num):
            self._data_in.append(self.input(f"data_in_{i}", self.data_width))
            self._idx_in.append(self.input(f"idx_in_{i}", self.idx_width))
        self._query_first_in = self.input("query_first_in", 1)
        self._query_last_in = self.input("query_last_in", 1)
        self._leaf_idx_in = self.input("leaf_idx_in", clog2(self.num_leaves))

        # outputs
        self._valid_out = self.output("valid_out", 1)
        self._leaf_idx_out = self.output("leaf_idx_out", clog2(self.num_leaves))
        self._data_out = []
        self._idx_out = []
        for i in range(self.out_num):
            self._data_out.append(self.output(f"data_out_{i}", self.data_width))
            self._idx_out.append(self.output(f"idx_out_{i}", self.idx_width))
        self._query_first_out = self.output("query_first_out", 1)
        self._query_last_out = self.output("query_last_out", 1)

        # output pipeline registers
        self._query_first_shft = self.var(f"query_first_shft", 6)
        self._query_last_shft = self.var(f"query_last_shft", 6)

        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_pipeline_shift(self):
            if ~self._rst_n:
                self._query_first_shft = 0
                self._query_last_shft = 0
            else:
                self._query_first_shft = concat(self._query_first_shft[self._query_first_shft.width - 2, 0], self._query_first_in)
                self._query_last_shft = concat(self._query_last_shft[self._query_last_shft.width - 2, 0], self._query_last_in)
        
        self.add_code(update_pipeline_shift)
        self.wire(self._query_first_out, self._query_first_shft[self._query_first_shft.width - 1])
        self.wire(self._query_last_out, self._query_last_shft[self._query_last_shft.width - 1])


        # pipeline stages
        self._stage0_valid = self.var("stage0_valid", 1)
        self._stage0_data = self.var("stage0_data",
                                     width=self.data_width,
                                     size=self.channel_num,
                                     explicit_array=True)
        self._stage0_idx = self.var("stage0_idx",
                                        width=self.idx_width,
                                        size=self.channel_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage0(self):
            if ~self._rst_n:
                self._stage0_valid = 0
                for p in range(self.channel_num):
                    self._stage0_data[p] = 0
                    self._stage0_idx[p] = 0
            else:
                self._stage0_valid = self._valid_in
                if self._valid_in:
                    self._stage0_data[0] = ternary(self._data_in[0] < self._data_in[1], self._data_in[0], self._data_in[1])
                    self._stage0_data[1] = ternary(self._data_in[0] < self._data_in[1], self._data_in[1], self._data_in[0])
                    self._stage0_data[2] = ternary(self._data_in[2] > self._data_in[3], self._data_in[2], self._data_in[3])
                    self._stage0_data[3] = ternary(self._data_in[2] > self._data_in[3], self._data_in[3], self._data_in[2])
                    self._stage0_data[4] = ternary(self._data_in[4] < self._data_in[5], self._data_in[4], self._data_in[5])
                    self._stage0_data[5] = ternary(self._data_in[4] < self._data_in[5], self._data_in[5], self._data_in[4])
                    self._stage0_data[6] = ternary(self._data_in[6] > self._data_in[7], self._data_in[6], self._data_in[7])
                    self._stage0_data[7] = ternary(self._data_in[6] > self._data_in[7], self._data_in[7], self._data_in[6])
                    
                    self._stage0_idx[0] = ternary(self._data_in[0] < self._data_in[1], self._idx_in[0], self._idx_in[1])
                    self._stage0_idx[1] = ternary(self._data_in[0] < self._data_in[1], self._idx_in[1], self._idx_in[0])
                    self._stage0_idx[2] = ternary(self._data_in[2] > self._data_in[3], self._idx_in[2], self._idx_in[3])
                    self._stage0_idx[3] = ternary(self._data_in[2] > self._data_in[3], self._idx_in[3], self._idx_in[2])
                    self._stage0_idx[4] = ternary(self._data_in[4] < self._data_in[5], self._idx_in[4], self._idx_in[5])
                    self._stage0_idx[5] = ternary(self._data_in[4] < self._data_in[5], self._idx_in[5], self._idx_in[4])
                    self._stage0_idx[6] = ternary(self._data_in[6] > self._data_in[7], self._idx_in[6], self._idx_in[7])
                    self._stage0_idx[7] = ternary(self._data_in[6] > self._data_in[7], self._idx_in[7], self._idx_in[6])
        self.add_code(sort_stage0)
        
        self._stage1_valid = self.var("stage1_valid", 1)
        self._stage1_data = self.var("stage1_data",
                                     width=self.data_width,
                                     size=self.channel_num,
                                     explicit_array=True)
        self._stage1_idx = self.var("stage1_idx",
                                        width=self.idx_width,
                                        size=self.channel_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage1(self):
            if ~self._rst_n:
                self._stage1_valid = 0
                for p in range(self.channel_num):
                    self._stage1_data[p] = 0
                    self._stage1_idx[p] = 0
            else:
                self._stage1_valid = self._stage0_valid
                if self._stage0_valid:
                    self._stage1_data[0] = ternary(self._stage0_data[0] < self._stage0_data[2], self._stage0_data[0], self._stage0_data[2])
                    self._stage1_data[2] = ternary(self._stage0_data[0] < self._stage0_data[2], self._stage0_data[2], self._stage0_data[0])
                    self._stage1_data[1] = ternary(self._stage0_data[1] < self._stage0_data[3], self._stage0_data[1], self._stage0_data[3])
                    self._stage1_data[3] = ternary(self._stage0_data[1] < self._stage0_data[3], self._stage0_data[3], self._stage0_data[1])
                    self._stage1_data[4] = ternary(self._stage0_data[4] > self._stage0_data[6], self._stage0_data[4], self._stage0_data[6])
                    self._stage1_data[6] = ternary(self._stage0_data[4] > self._stage0_data[6], self._stage0_data[6], self._stage0_data[4])
                    self._stage1_data[5] = ternary(self._stage0_data[5] > self._stage0_data[7], self._stage0_data[5], self._stage0_data[7])
                    self._stage1_data[7] = ternary(self._stage0_data[5] > self._stage0_data[7], self._stage0_data[7], self._stage0_data[5])
                    
                    self._stage1_idx[0] = ternary(self._stage0_data[0] < self._stage0_data[2], self._stage0_idx[0], self._stage0_idx[2])
                    self._stage1_idx[2] = ternary(self._stage0_data[0] < self._stage0_data[2], self._stage0_idx[2], self._stage0_idx[0])
                    self._stage1_idx[1] = ternary(self._stage0_data[1] < self._stage0_data[3], self._stage0_idx[1], self._stage0_idx[3])
                    self._stage1_idx[3] = ternary(self._stage0_data[1] < self._stage0_data[3], self._stage0_idx[3], self._stage0_idx[1])
                    self._stage1_idx[4] = ternary(self._stage0_data[4] > self._stage0_data[6], self._stage0_idx[4], self._stage0_idx[6])
                    self._stage1_idx[6] = ternary(self._stage0_data[4] > self._stage0_data[6], self._stage0_idx[6], self._stage0_idx[4])
                    self._stage1_idx[5] = ternary(self._stage0_data[5] > self._stage0_data[7], self._stage0_idx[5], self._stage0_idx[7])
                    self._stage1_idx[7] = ternary(self._stage0_data[5] > self._stage0_data[7], self._stage0_idx[7], self._stage0_idx[5])
        self.add_code(sort_stage1)

        self._stage2_valid = self.var("stage2_valid", 1)
        self._stage2_data = self.var("stage2_data",
                                     width=self.data_width,
                                     size=self.channel_num,
                                     explicit_array=True)
        self._stage2_idx = self.var("stage2_idx",
                                        width=self.idx_width,
                                        size=self.channel_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage2(self):
            if ~self._rst_n:
                self._stage2_valid = 0
                for p in range(self.channel_num):
                    self._stage2_data[p] = 0
                    self._stage2_idx[p] = 0
            else:
                self._stage2_valid = self._stage1_valid
                if self._stage1_valid:
                    self._stage2_data[0] = ternary(self._stage1_data[0] < self._stage1_data[1], self._stage1_data[0], self._stage1_data[1])
                    self._stage2_data[1] = ternary(self._stage1_data[0] < self._stage1_data[1], self._stage1_data[1], self._stage1_data[0])
                    self._stage2_data[2] = ternary(self._stage1_data[2] < self._stage1_data[3], self._stage1_data[2], self._stage1_data[3])
                    self._stage2_data[3] = ternary(self._stage1_data[2] < self._stage1_data[3], self._stage1_data[3], self._stage1_data[2])
                    self._stage2_data[4] = ternary(self._stage1_data[4] > self._stage1_data[5], self._stage1_data[4], self._stage1_data[5])
                    self._stage2_data[5] = ternary(self._stage1_data[4] > self._stage1_data[5], self._stage1_data[5], self._stage1_data[4])
                    self._stage2_data[6] = ternary(self._stage1_data[6] > self._stage1_data[7], self._stage1_data[6], self._stage1_data[7])
                    self._stage2_data[7] = ternary(self._stage1_data[6] > self._stage1_data[7], self._stage1_data[7], self._stage1_data[6])
                    
                    self._stage2_idx[0] = ternary(self._stage1_data[0] < self._stage1_data[1], self._stage1_idx[0], self._stage1_idx[1])
                    self._stage2_idx[1] = ternary(self._stage1_data[0] < self._stage1_data[1], self._stage1_idx[1], self._stage1_idx[0])
                    self._stage2_idx[2] = ternary(self._stage1_data[2] < self._stage1_data[3], self._stage1_idx[2], self._stage1_idx[3])
                    self._stage2_idx[3] = ternary(self._stage1_data[2] < self._stage1_data[3], self._stage1_idx[3], self._stage1_idx[2])
                    self._stage2_idx[4] = ternary(self._stage1_data[4] > self._stage1_data[5], self._stage1_idx[4], self._stage1_idx[5])
                    self._stage2_idx[5] = ternary(self._stage1_data[4] > self._stage1_data[5], self._stage1_idx[5], self._stage1_idx[4])
                    self._stage2_idx[6] = ternary(self._stage1_data[6] > self._stage1_data[7], self._stage1_idx[6], self._stage1_idx[7])
                    self._stage2_idx[7] = ternary(self._stage1_data[6] > self._stage1_data[7], self._stage1_idx[7], self._stage1_idx[6])
        self.add_code(sort_stage2)

        self._stage3_valid = self.var("stage3_valid", 1)
        self._stage3_data = self.var("stage3_data",
                                     width=self.data_width,
                                     size=self.out_num,
                                     explicit_array=True)
        self._stage3_idx = self.var("stage3_idx",
                                        width=self.idx_width,
                                        size=self.out_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage3(self):
            if ~self._rst_n:
                self._stage3_valid = 0
                for p in range(self.out_num):
                    self._stage3_data[p] = 0
                    self._stage3_idx[p] = 0
            else:
                self._stage3_valid = self._stage2_valid
                if self._stage2_valid:
                    self._stage3_data[0] = ternary(self._stage2_data[0] < self._stage2_data[4], self._stage2_data[0], self._stage2_data[4])
                    self._stage3_data[1] = ternary(self._stage2_data[1] < self._stage2_data[5], self._stage2_data[1], self._stage2_data[5])
                    self._stage3_data[2] = ternary(self._stage2_data[2] < self._stage2_data[6], self._stage2_data[2], self._stage2_data[6])
                    self._stage3_data[3] = ternary(self._stage2_data[3] < self._stage2_data[7], self._stage2_data[3], self._stage2_data[7])
                    # self._stage3_data[4] = ternary(self._stage2_data[0] < self._stage2_data[4], self._stage2_data[4], self._stage2_data[0])
                    # self._stage3_data[5] = ternary(self._stage2_data[1] < self._stage2_data[5], self._stage2_data[5], self._stage2_data[1])
                    # self._stage3_data[6] = ternary(self._stage2_data[2] < self._stage2_data[6], self._stage2_data[6], self._stage2_data[2])
                    # self._stage3_data[7] = ternary(self._stage2_data[3] < self._stage2_data[7], self._stage2_data[7], self._stage2_data[3])

                    self._stage3_idx[0] = ternary(self._stage2_data[0] < self._stage2_data[4], self._stage2_idx[0], self._stage2_idx[4])
                    self._stage3_idx[1] = ternary(self._stage2_data[1] < self._stage2_data[5], self._stage2_idx[1], self._stage2_idx[5])
                    self._stage3_idx[2] = ternary(self._stage2_data[2] < self._stage2_data[6], self._stage2_idx[2], self._stage2_idx[6])
                    self._stage3_idx[3] = ternary(self._stage2_data[3] < self._stage2_data[7], self._stage2_idx[3], self._stage2_idx[7])
                    # self._stage3_idx[4] = ternary(self._stage2_data[0] < self._stage2_data[4], self._stage2_idx[4], self._stage2_idx[0])
                    # self._stage3_idx[5] = ternary(self._stage2_data[1] < self._stage2_data[5], self._stage2_idx[5], self._stage2_idx[1])
                    # self._stage3_idx[6] = ternary(self._stage2_data[2] < self._stage2_data[6], self._stage2_idx[6], self._stage2_idx[2])
                    # self._stage3_idx[7] = ternary(self._stage2_data[3] < self._stage2_data[7], self._stage2_idx[7], self._stage2_idx[3])
        self.add_code(sort_stage3)

        self._stage4_valid = self.var("stage4_valid", 1)
        self._stage4_data = self.var("stage4_data",
                                     width=self.data_width,
                                     size=self.out_num,
                                     explicit_array=True)
        self._stage4_idx = self.var("stage4_idx",
                                        width=self.idx_width,
                                        size=self.out_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage4(self):
            if ~self._rst_n:
                self._stage4_valid = 0
                for p in range(self.out_num):
                    self._stage4_data[p] = 0
                    self._stage4_idx[p] = 0
            else:
                self._stage4_valid = self._stage3_valid
                if self._stage3_valid:
                    self._stage4_data[0] = ternary(self._stage3_data[0] < self._stage3_data[2], self._stage3_data[0], self._stage3_data[2])
                    self._stage4_data[2] = ternary(self._stage3_data[0] < self._stage3_data[2], self._stage3_data[2], self._stage3_data[0])
                    self._stage4_data[1] = ternary(self._stage3_data[1] < self._stage3_data[3], self._stage3_data[1], self._stage3_data[3])
                    self._stage4_data[3] = ternary(self._stage3_data[1] < self._stage3_data[3], self._stage3_data[3], self._stage3_data[1])
                    
                    self._stage4_idx[0] = ternary(self._stage3_data[0] < self._stage3_data[2], self._stage3_idx[0], self._stage3_idx[2])
                    self._stage4_idx[2] = ternary(self._stage3_data[0] < self._stage3_data[2], self._stage3_idx[2], self._stage3_idx[0])
                    self._stage4_idx[1] = ternary(self._stage3_data[1] < self._stage3_data[3], self._stage3_idx[1], self._stage3_idx[3])
                    self._stage4_idx[3] = ternary(self._stage3_data[1] < self._stage3_data[3], self._stage3_idx[3], self._stage3_idx[1])
        self.add_code(sort_stage4)

        self._stage5_valid = self.var("stage5_valid", 1)
        self._stage5_data = self.var("stage5_data",
                                     width=self.data_width,
                                     size=self.out_num,
                                     explicit_array=True)
        self._stage5_idx = self.var("stage5_idx",
                                    width=self.idx_width,
                                    size=self.out_num,
                                    explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage5(self):
            if ~self._rst_n:
                self._stage5_valid = 0
                for p in range(self.out_num):
                    self._stage5_data[p] = 0
                    self._stage5_idx[p] = 0
            else:
                self._stage5_valid = self._stage4_valid
                if self._stage4_valid:
                    self._stage5_data[0] = ternary(self._stage4_data[0] < self._stage4_data[1], self._stage4_data[0], self._stage4_data[1])
                    self._stage5_data[1] = ternary(self._stage4_data[0] < self._stage4_data[1], self._stage4_data[1], self._stage4_data[0])
                    self._stage5_data[2] = ternary(self._stage4_data[2] < self._stage4_data[3], self._stage4_data[2], self._stage4_data[3])
                    self._stage5_data[3] = ternary(self._stage4_data[2] < self._stage4_data[3], self._stage4_data[3], self._stage4_data[2])
                    
                    self._stage5_idx[0] = ternary(self._stage4_data[0] < self._stage4_data[1], self._stage4_idx[0], self._stage4_idx[1])
                    self._stage5_idx[1] = ternary(self._stage4_data[0] < self._stage4_data[1], self._stage4_idx[1], self._stage4_idx[0])
                    self._stage5_idx[2] = ternary(self._stage4_data[2] < self._stage4_data[3], self._stage4_idx[2], self._stage4_idx[3])
                    self._stage5_idx[3] = ternary(self._stage4_data[2] < self._stage4_data[3], self._stage4_idx[3], self._stage4_idx[2])
        self.add_code(sort_stage5)

        self.wire(self._valid_out, self._stage5_valid)
        # self.wire(self._data_out, self._stage5_dacta)
        # self.wire(self._idx_out, self._stage5_idx)
        for i in range(self.out_num):
            self.wire(self._data_out[i], self._stage5_data[i])
            self.wire(self._idx_out[i], self._stage5_idx[i])


        # leaf pipeline registers
        self._leaf_idx_r0 = self.var("leaf_idx_r0", clog2(self.num_leaves))
        self._leaf_idx_r1 = self.var("leaf_idx_r1", clog2(self.num_leaves))
        self._leaf_idx_r2 = self.var("leaf_idx_r2", clog2(self.num_leaves))
        self._leaf_idx_r3 = self.var("leaf_idx_r3", clog2(self.num_leaves))
        self._leaf_idx_r4 = self.var("leaf_idx_r4", clog2(self.num_leaves))
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_leaf_idx(self):
            if ~self._rst_n:
                self._leaf_idx_r0 = 0
                self._leaf_idx_r1 = 0
                self._leaf_idx_r2 = 0
                self._leaf_idx_r3 = 0
                self._leaf_idx_r4 = 0
                self._leaf_idx_out = 0
            else:
                if self._valid_in:
                    self._leaf_idx_r0 = self._leaf_idx_in
                if self._stage0_valid:
                    self._leaf_idx_r1 = self._leaf_idx_r0
                if self._stage1_valid:
                    self._leaf_idx_r2 = self._leaf_idx_r1
                if self._stage2_valid:
                    self._leaf_idx_r3 = self._leaf_idx_r2
                if self._stage3_valid:
                    self._leaf_idx_r4 = self._leaf_idx_r3
                if self._stage4_valid:
                    self._leaf_idx_out = self._leaf_idx_r4
        self.add_code(update_leaf_idx)



if __name__ == "__main__":
    db_dut = BitonicSorter()
    verilog(db_dut, filename="rtl/BitonicSorter.sv")
