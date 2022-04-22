from kratos import *

class RunningMin(Generator):
    def __init__(self,
                 data_width=11,
                 idx_width=9,
                 leaf_size=8,
                 patch_size=5,
                 num_leaves=64,
                 row=30,
                 height=23,
                 channel_num=8):
        super().__init__("RunningMin", False)
        self.channel_num = channel_num
        self.data_width = data_width
        self.idx_width = idx_width
        self.leaf_size = leaf_size
        self.patch_size = patch_size
        self.num_leaves = num_leaves
        self.row = row
        self.height = height

        self.total_patches = (self.row - self.patch_size + 1) * (self.height - self.patch_size + 1) 
        self.leaf_addrw = clog2(self.num_leaves)
        
        self._clk = self.clock("clk")
        self._rst_n = self.reset("rst_n", 1)

        self._restart = self.input("restart", 1)
        self._valid_in = self.input("valid_in", 1)
        self._query_last_in = self.input("query_last_in", 1)
        self._leaf_idx_in = self.input("leaf_idx_in", self.leaf_addrw)
        self._query_last_out = self.output("query_last_out", 1)
        self._valid_out = self.output("valid_out", 1)

        # pipeline registers
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_valid(self):
            if ~self._rst_n:
                self._valid_out = 0
            else:
                self._valid_out = self._valid_in
        self.add_code(update_valid)

        self._query_last_r = self.var(f"query_last_r", 1)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_query_last_out(self):
            if ~self._rst_n:
                self._query_last_r = 0
            else:
                self._query_last_r = self._query_last_in
        self.add_code(update_query_last_out)
        self.wire(self._query_last_out, self._query_last_r)

        # comparison logic
        for i in range(self.channel_num):
            self._l2_dist = self.input(f"p{i}_l2_dist", self.data_width)
            self._idx = self.input(f"p{i}_idx", self.idx_width)

            self._l2_dist_min = self.output(f"p{i}_l2_dist_min", self.data_width)
            self._idx_min = self.output(f"p{i}_idx_min", self.idx_width + self.leaf_addrw)
            @always_ff((posedge, "clk"), (negedge, "rst_n"))
            def update_min(self):
                if ~self._rst_n:
                    self._l2_dist_min = 0
                    self._idx_min = 0
                elif self._valid_in:
                    if (self._l2_dist < self._l2_dist_min) | self._restart:
                        self._l2_dist_min = self._l2_dist
                        self._idx_min = concat(self._leaf_idx_in, self._idx)
            self.add_code(update_min)
    

if __name__ == "__main__":
    db_dut = RunningMin()
    verilog(db_dut, filename="rtl/RunningMin.sv")
