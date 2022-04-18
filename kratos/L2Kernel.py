from kratos import *

class L2Kernel(Generator):
    def __init__(self,
                 data_width=11,
                 idx_width=9,
                 pca_size=5,
                 leaf_size=8,
                 patch_size=5,
                 row=30,
                 height=23):
        super().__init__("L2Kernel", False)
        self.data_width = data_width
        self.idx_width = idx_width
        self.pca_size = pca_size
        self.leaf_size = leaf_size
        self.patch_size = patch_size
        self.row = row
        self.height = height

        self.total_patches = (self.row - self.patch_size + 1) * (self.height - self.patch_size + 1) 
        
        self._clk = self.clock("clk")
        self._rst_n = self.reset("rst_n", 1)
    
        self._query_first_in = self.input("query_first_in", 1)
        self._query_last_in = self.input("query_last_in", 1)
        self._query_valid = self.input("query_valid", 1)
        self._query_patch = self.input("query_patch",
                                       width=self.data_width,
                                       size=self.pca_size,
                                       is_signed=True,
                                       packed=True,
                                       explicit_array=True)        

        self._query_first_out = self.output("query_first_out", 1)
        self._query_last_out = self.output("query_last_out", 1)
        self._dist_valid = self.output("dist_valid", 1)

        self._query_first_shft = self.var(f"query_first_shft", 5)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_query_first_out(self):
            if ~self._rst_n:
                self._query_first_shft = 0
            else:
                self._query_first_shft = concat(self._query_first_shft[self._query_first_shft.width - 2, 0], self._query_first_in)
        self.add_code(update_query_first_out)
        self.wire(self._query_first_out, self._query_first_shft[self._query_first_shft.width - 1])

        self._query_last_shft = self.var(f"query_last_shft", 5)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_query_last_out(self):
            if ~self._rst_n:
                self._query_last_shft = 0
            else:
                self._query_last_shft = concat(self._query_last_shft[self._query_last_shft.width - 2, 0], self._query_last_in)
        self.add_code(update_query_last_out)
        self.wire(self._query_last_out, self._query_last_shft[self._query_last_shft.width - 1])

        self._valid_shft = self.var(f"valid_shft", 5)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_valid(self):
            if ~self._rst_n:
                self._valid_shft = 0
            else:
                self._valid_shft = concat(self._valid_shft[self._valid_shft.width - 2, 0], self._query_valid)
        self.add_code(update_valid)
        self.wire(self._dist_valid, self._valid_shft[self._valid_shft.width - 1])

        for i in range(leaf_size):
            self._leaf_data = self.input(f"p{i}_leaf_data",
                                        width=self.data_width,
                                        size=self.pca_size,
                                        is_signed=True,
                                        packed=True,
                                        explicit_array=True)
            self._leaf_idx = self.input(f"p{i}_leaf_idx", self.idx_width)
            self._l2_dist = self.output(f"p{i}_l2_dist", self.data_width)
            self._idx = self.output(f"p{i}_idx", self.idx_width)

            self._leaf_idx_r0 = self.var(f"p{i}_leaf_idx_r0", self.idx_width)
            self._leaf_idx_r1 = self.var(f"p{i}_leaf_idx_r1", self.idx_width)
            self._leaf_idx_r2 = self.var(f"p{i}_leaf_idx_r2", self.idx_width)
            self._leaf_idx_r3 = self.var(f"p{i}_leaf_idx_r3", self.idx_width)
            @always_ff((posedge, "clk"), (negedge, "rst_n"))
            def update_idx(self):
                if ~self._rst_n:
                    self._leaf_idx_r0 = 0
                    self._leaf_idx_r1 = 0
                    self._leaf_idx_r2 = 0
                    self._leaf_idx_r3 = 0
                    self._idx = 0
                else:
                    self._leaf_idx_r0 = self._leaf_idx
                    self._leaf_idx_r1 = self._leaf_idx_r0
                    self._leaf_idx_r2 = self._leaf_idx_r1
                    self._leaf_idx_r3 = self._leaf_idx_r2
                    self._idx = self._leaf_idx_r3
            self.add_code(update_idx)

            self._patch_diff = self.var(f"p{i}_patch_diff",
                                        width=self.data_width,
                                        size=self.pca_size,
                                        is_signed=True,
                                        explicit_array=True)
            @always_ff((posedge, "clk"), (negedge, "rst_n"))
            def update_patch_diff(self):
                if ~self._rst_n:
                    for p in range(self.pca_size):
                        self._patch_diff[p] = 0
                elif self._query_valid:
                    for p in range(self.pca_size):
                        self._patch_diff[p] = self._query_patch[p] - self._leaf_data[p]
            self.add_code(update_patch_diff)

            self._diff2 = self.var(f"p{i}_diff2", 
                                   width=self.data_width,
                                   size=self.pca_size,
                                   is_signed=True,
                                   explicit_array=True)
            self._diff2_unsigned = self.var(f"p{i}_diff2_unsigned", 
                                            width=self.data_width,
                                            size=self.pca_size,
                                            is_signed=False,
                                            explicit_array=True)
            @always_comb
            def update_diff2(self):
                for p in range(self.pca_size):
                    self._diff2[p] = self._patch_diff[p] * self._patch_diff[p]
            
            @always_ff((posedge, "clk"), (negedge, "rst_n"))
            def update_diff2_unsigned(self):
                if ~self._rst_n:
                    for p in range(self.pca_size):
                        self._diff2_unsigned[p] = 0
                elif self._valid_shft[0]:
                    for p in range(self.pca_size):
                        # remove the sign bit
                        self._diff2_unsigned[p] = unsigned(self._diff2[p])
            self.add_code(update_diff2)
            self.add_code(update_diff2_unsigned)
        
            self._add_tree0 = self.var(f"p{i}_add_tree0",
                                       width=self.data_width,
                                       size=3,
                                       explicit_array=True)
            self._add_tree1 = self.var(f"p{i}_add_tree1",
                                       width=self.data_width,
                                       size=2,
                                       explicit_array=True)
            @always_ff((posedge, "clk"), (negedge, "rst_n"))
            def update_add_tree(self):
                if ~self._rst_n:
                    self._add_tree0[0] = 0
                    self._add_tree0[1] = 0
                    self._add_tree0[2] = 0
                    self._add_tree1[0] = 0
                    self._add_tree1[1] = 0
                    self._l2_dist = 0
                else:
                    if self._valid_shft[1]:
                        self._add_tree0[0] = self._diff2_unsigned[0] + self._diff2_unsigned[1]
                        self._add_tree0[1] = self._diff2_unsigned[2] + self._diff2_unsigned[3]
                        self._add_tree0[2] = self._diff2_unsigned[4]
                    
                    if self._valid_shft[2]:
                        self._add_tree1[0] = self._add_tree0[0] + self._add_tree0[1]
                        self._add_tree1[1] = self._add_tree0[2]
                    
                    if self._valid_shft[3]:
                        self._l2_dist = self._add_tree1[0] + self._add_tree1[1]
            self.add_code(update_add_tree)
            
            
            '''
            # back up code if we want to use the correct mult bitwidth and then trunction, then correct add tree bitwidth
            @always_comb
            def update_diff2(self):
                for p in range(self.pca_size):
                    self._diff2[p] = self._patch_diff[p].extend(self.data_width * 2) * self._patch_diff[p].extend(self.data_width * 2)
            @always_ff((posedge, "clk"), (negedge, "rst_n"))
            def trunc_diff2_unsigned(self):
                if ~self._rst_n:
                    for p in range(self.pca_size):
                        self._diff2[p] = 0
                else:
                    for p in range(self.pca_size):
                        # remove the sign bit
                        self._diff2[p] = unsigned(self._diff2[p][self.data_width * 2 - 2, self.data_width - 1])
            self.add_code(update_diff2)
            self.add_code(trunc_diff2_unsigned)
        
            self._add_tree0 = self.var(f"p{i}_add_tree0",
                                       width=self.data_width + 1,
                                       size=3,
                                       explicit_array=True)
            self._add_tree1 = self.var(f"p{i}_add_tree1",
                                       width=self.data_width + 2,
                                       size=2,
                                       explicit_array=True)
            self._add_tree2 = self.var(f"p{i}_add_tree2", self.data_width + 3)
            self.wire(self._add_tree2, 
                      self._add_tree1[0].extend(self.data_width + 3) 
                      + self._add_tree1[1].extend(self.data_width + 3))
            @always_ff((posedge, "clk"), (negedge, "rst_n"))
            def update_add_tree(self):
                if ~self._rst_n:
                    self._add_tree0[0] = 0
                    self._add_tree0[1] = 0
                    self._add_tree0[2] = 0
                    self._add_tree1[0] = 0
                    self._add_tree1[1] = 0
                else:
                    self._add_tree0[0] = self._diff2[0].extend(self.data_width + 1) + self._diff2[1].extend(self.data_width + 1)
                    self._add_tree0[1] = self._diff2[2].extend(self.data_width + 1) + self._diff2[3].extend(self.data_width + 1)
                    self._add_tree0[2] = self._diff2[4].extend(self.data_width + 1)
                    
                    self._add_tree1[0] = self._add_tree0[0].extend(self.data_width + 2) + self._add_tree0[1].extend(self.data_width + 2)
                    self._add_tree1[1] = self._add_tree0[2].extend(self.data_width + 2)
                    
                    self._l2_dist = self._add_tree2[self.data_width + 3 - 1, 3]
            self.add_code(update_add_tree)
            '''
        

if __name__ == "__main__":
    db_dut = L2Kernel()
    verilog(db_dut, filename="rtl/L2Kernel.sv")
