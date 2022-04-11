from kratos import *
'''
8-to-4 Bitonic Sort
The outputs[3:0] are sorted with [3] being the largest and [0] being the smallest
'''

class BitonicSorter(Generator):
    def __init__(self,
                 data_width=11,
                 channel_num=8,
                 patch_size=5,
                 row=30,
                 height=23):
        super().__init__("BitonicSorter", False)
        self.data_width = data_width
        self.channel_num = channel_num
        self.patch_size = patch_size
        self.row = row
        self.height = height

        self.total_patches = (self.row - self.patch_size + 1) * (self.height - self.patch_size + 1)
        self.stages = clog2(self.channel_num)
        self.out_num = 4

        # inputs
        self._clk = self.clock("clk")
        self._rst_n = self.reset("rst_n", 1)

        self._valid_in = self.input("valid_in", 1)
        self._data_in = []
        self._indices_in = []
        for i in range(self.channel_num):
            self._data_in.append(self.input(f"data_in_{i}", self.data_width))
            self._indices_in.append(self.input(f"indices_in_{i}", clog2(self.total_patches)))

        # outputs
        self._valid_out = self.output("valid_out", 1)
        self._data_out = []
        self._indices_out = []
        for i in range(self.out_num):
            self._data_out.append(self.output(f"data_out_{i}", self.data_width))
            self._indices_out.append(self.output(f"indices_out_{i}", clog2(self.total_patches)))
        # self._data_out = self.output("data_out",
        #                              width=self.data_width,
        #                              size=self.out_num,
        #                              explicit_array=True)
        # self._indices_out = self.output("indices_out",
        #                                 width=clog2(self.total_patches),
        #                                 size=self.out_num,
        #                                 explicit_array=True)

        # pipeline stages
        self._stage0_valid = self.var("stage0_valid", 1)
        self._stage0_data = self.var("stage0_data",
                                     width=self.data_width,
                                     size=self.channel_num,
                                     explicit_array=True)
        self._stage0_indices = self.var("stage0_indices",
                                        width=clog2(self.total_patches),
                                        size=self.channel_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage0(self):
            if ~self._rst_n:
                self._stage0_valid = 0
                for p in range(self.channel_num):
                    self._stage0_data[p] = 0
                    self._stage0_indices[p] = 0
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
                    
                    self._stage0_indices[0] = ternary(self._data_in[0] < self._data_in[1], self._indices_in[0], self._indices_in[1])
                    self._stage0_indices[1] = ternary(self._data_in[0] < self._data_in[1], self._indices_in[1], self._indices_in[0])
                    self._stage0_indices[2] = ternary(self._data_in[2] > self._data_in[3], self._indices_in[2], self._indices_in[3])
                    self._stage0_indices[3] = ternary(self._data_in[2] > self._data_in[3], self._indices_in[3], self._indices_in[2])
                    self._stage0_indices[4] = ternary(self._data_in[4] < self._data_in[5], self._indices_in[4], self._indices_in[5])
                    self._stage0_indices[5] = ternary(self._data_in[4] < self._data_in[5], self._indices_in[5], self._indices_in[4])
                    self._stage0_indices[6] = ternary(self._data_in[6] > self._data_in[7], self._indices_in[6], self._indices_in[7])
                    self._stage0_indices[7] = ternary(self._data_in[6] > self._data_in[7], self._indices_in[7], self._indices_in[6])
        self.add_code(sort_stage0)
        
        self._stage1_valid = self.var("stage1_valid", 1)
        self._stage1_data = self.var("stage1_data",
                                     width=self.data_width,
                                     size=self.channel_num,
                                     explicit_array=True)
        self._stage1_indices = self.var("stage1_indices",
                                        width=clog2(self.total_patches),
                                        size=self.channel_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage1(self):
            if ~self._rst_n:
                self._stage1_valid = 0
                for p in range(self.channel_num):
                    self._stage1_data[p] = 0
                    self._stage1_indices[p] = 0
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
                    
                    self._stage1_indices[0] = ternary(self._stage0_data[0] < self._stage0_data[2], self._stage0_indices[0], self._stage0_indices[2])
                    self._stage1_indices[2] = ternary(self._stage0_data[0] < self._stage0_data[2], self._stage0_indices[2], self._stage0_indices[0])
                    self._stage1_indices[1] = ternary(self._stage0_data[1] < self._stage0_data[3], self._stage0_indices[1], self._stage0_indices[3])
                    self._stage1_indices[3] = ternary(self._stage0_data[1] < self._stage0_data[3], self._stage0_indices[3], self._stage0_indices[1])
                    self._stage1_indices[4] = ternary(self._stage0_data[4] > self._stage0_data[6], self._stage0_indices[4], self._stage0_indices[6])
                    self._stage1_indices[6] = ternary(self._stage0_data[4] > self._stage0_data[6], self._stage0_indices[6], self._stage0_indices[4])
                    self._stage1_indices[5] = ternary(self._stage0_data[5] > self._stage0_data[7], self._stage0_indices[5], self._stage0_indices[7])
                    self._stage1_indices[7] = ternary(self._stage0_data[5] > self._stage0_data[7], self._stage0_indices[7], self._stage0_indices[5])
        self.add_code(sort_stage1)

        self._stage2_valid = self.var("stage2_valid", 1)
        self._stage2_data = self.var("stage2_data",
                                     width=self.data_width,
                                     size=self.channel_num,
                                     explicit_array=True)
        self._stage2_indices = self.var("stage2_indices",
                                        width=clog2(self.total_patches),
                                        size=self.channel_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage2(self):
            if ~self._rst_n:
                self._stage2_valid = 0
                for p in range(self.channel_num):
                    self._stage2_data[p] = 0
                    self._stage2_indices[p] = 0
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
                    
                    self._stage2_indices[0] = ternary(self._stage1_data[0] < self._stage1_data[1], self._stage1_indices[0], self._stage1_indices[1])
                    self._stage2_indices[1] = ternary(self._stage1_data[0] < self._stage1_data[1], self._stage1_indices[1], self._stage1_indices[0])
                    self._stage2_indices[2] = ternary(self._stage1_data[2] < self._stage1_data[3], self._stage1_indices[2], self._stage1_indices[3])
                    self._stage2_indices[3] = ternary(self._stage1_data[2] < self._stage1_data[3], self._stage1_indices[3], self._stage1_indices[2])
                    self._stage2_indices[4] = ternary(self._stage1_data[4] > self._stage1_data[5], self._stage1_indices[4], self._stage1_indices[5])
                    self._stage2_indices[5] = ternary(self._stage1_data[4] > self._stage1_data[5], self._stage1_indices[5], self._stage1_indices[4])
                    self._stage2_indices[6] = ternary(self._stage1_data[6] > self._stage1_data[7], self._stage1_indices[6], self._stage1_indices[7])
                    self._stage2_indices[7] = ternary(self._stage1_data[6] > self._stage1_data[7], self._stage1_indices[7], self._stage1_indices[6])
        self.add_code(sort_stage2)

        self._stage3_valid = self.var("stage3_valid", 1)
        self._stage3_data = self.var("stage3_data",
                                     width=self.data_width,
                                     size=self.out_num,
                                     explicit_array=True)
        self._stage3_indices = self.var("stage3_indices",
                                        width=clog2(self.total_patches),
                                        size=self.out_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage3(self):
            if ~self._rst_n:
                self._stage3_valid = 0
                for p in range(self.out_num):
                    self._stage3_data[p] = 0
                    self._stage3_indices[p] = 0
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

                    self._stage3_indices[0] = ternary(self._stage2_data[0] < self._stage2_data[4], self._stage2_indices[0], self._stage2_indices[4])
                    self._stage3_indices[1] = ternary(self._stage2_data[1] < self._stage2_data[5], self._stage2_indices[1], self._stage2_indices[5])
                    self._stage3_indices[2] = ternary(self._stage2_data[2] < self._stage2_data[6], self._stage2_indices[2], self._stage2_indices[6])
                    self._stage3_indices[3] = ternary(self._stage2_data[3] < self._stage2_data[7], self._stage2_indices[3], self._stage2_indices[7])
                    # self._stage3_indices[4] = ternary(self._stage2_data[0] < self._stage2_data[4], self._stage2_indices[4], self._stage2_indices[0])
                    # self._stage3_indices[5] = ternary(self._stage2_data[1] < self._stage2_data[5], self._stage2_indices[5], self._stage2_indices[1])
                    # self._stage3_indices[6] = ternary(self._stage2_data[2] < self._stage2_data[6], self._stage2_indices[6], self._stage2_indices[2])
                    # self._stage3_indices[7] = ternary(self._stage2_data[3] < self._stage2_data[7], self._stage2_indices[7], self._stage2_indices[3])
        self.add_code(sort_stage3)

        self._stage4_valid = self.var("stage4_valid", 1)
        self._stage4_data = self.var("stage4_data",
                                     width=self.data_width,
                                     size=self.out_num,
                                     explicit_array=True)
        self._stage4_indices = self.var("stage4_indices",
                                        width=clog2(self.total_patches),
                                        size=self.out_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage4(self):
            if ~self._rst_n:
                self._stage4_valid = 0
                for p in range(self.out_num):
                    self._stage4_data[p] = 0
                    self._stage4_indices[p] = 0
            else:
                self._stage4_valid = self._stage3_valid
                if self._stage3_valid:
                    self._stage4_data[0] = ternary(self._stage3_data[0] < self._stage3_data[2], self._stage3_data[0], self._stage3_data[2])
                    self._stage4_data[2] = ternary(self._stage3_data[0] < self._stage3_data[2], self._stage3_data[2], self._stage3_data[0])
                    self._stage4_data[1] = ternary(self._stage3_data[1] < self._stage3_data[3], self._stage3_data[1], self._stage3_data[3])
                    self._stage4_data[3] = ternary(self._stage3_data[1] < self._stage3_data[3], self._stage3_data[3], self._stage3_data[1])
                    
                    self._stage4_indices[0] = ternary(self._stage3_data[0] < self._stage3_data[2], self._stage3_indices[0], self._stage3_indices[2])
                    self._stage4_indices[2] = ternary(self._stage3_data[0] < self._stage3_data[2], self._stage3_indices[2], self._stage3_indices[0])
                    self._stage4_indices[1] = ternary(self._stage3_data[1] < self._stage3_data[3], self._stage3_indices[1], self._stage3_indices[3])
                    self._stage4_indices[3] = ternary(self._stage3_data[1] < self._stage3_data[3], self._stage3_indices[3], self._stage3_indices[1])
        self.add_code(sort_stage4)

        self._stage5_valid = self.var("stage5_valid", 1)
        self._stage5_data = self.var("stage5_data",
                                     width=self.data_width,
                                     size=self.out_num,
                                     explicit_array=True)
        self._stage5_indices = self.var("stage5_indices",
                                        width=clog2(self.total_patches),
                                        size=self.out_num,
                                        explicit_array=True)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def sort_stage5(self):
            if ~self._rst_n:
                self._stage5_valid = 0
                for p in range(self.out_num):
                    self._stage5_data[p] = 0
                    self._stage5_indices[p] = 0
            else:
                self._stage5_valid = self._stage4_valid
                if self._stage4_valid:
                    self._stage5_data[0] = ternary(self._stage4_data[0] < self._stage4_data[1], self._stage4_data[0], self._stage4_data[1])
                    self._stage5_data[1] = ternary(self._stage4_data[0] < self._stage4_data[1], self._stage4_data[1], self._stage4_data[0])
                    self._stage5_data[2] = ternary(self._stage4_data[2] < self._stage4_data[3], self._stage4_data[2], self._stage4_data[3])
                    self._stage5_data[3] = ternary(self._stage4_data[2] < self._stage4_data[3], self._stage4_data[3], self._stage4_data[2])
                    
                    self._stage5_indices[0] = ternary(self._stage4_data[0] < self._stage4_data[1], self._stage4_indices[0], self._stage4_indices[1])
                    self._stage5_indices[1] = ternary(self._stage4_data[0] < self._stage4_data[1], self._stage4_indices[1], self._stage4_indices[0])
                    self._stage5_indices[2] = ternary(self._stage4_data[2] < self._stage4_data[3], self._stage4_indices[2], self._stage4_indices[3])
                    self._stage5_indices[3] = ternary(self._stage4_data[2] < self._stage4_data[3], self._stage4_indices[3], self._stage4_indices[2])
        self.add_code(sort_stage5)

        self.wire(self._valid_out, self._stage5_valid)
        # self.wire(self._data_out, self._stage5_data)
        # self.wire(self._indices_out, self._stage5_indices)
        for i in range(self.out_num):
            self.wire(self._data_out[i], self._stage5_data[i])
            self.wire(self._indices_out[i], self._stage5_indices[i])


if __name__ == "__main__":
    db_dut = BitonicSorter()
    verilog(db_dut, filename="rtl/BitonicSorter.sv")
