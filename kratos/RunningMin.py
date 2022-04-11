from kratos import *

class RunningMin(Generator):
    def __init__(self,
                 data_width=11,
                 leaf_size=8,
                 patch_size=5,
                 row=30,
                 height=23,
                 channel_num=8):
        super().__init__("RunningMin", False)
        self.channel_num = channel_num
        self.data_width = data_width
        self.leaf_size = leaf_size
        self.patch_size = patch_size
        self.row = row
        self.height = height

        self.total_patches = (self.row - self.patch_size + 1) * (self.height - self.patch_size + 1) 
        
        self._clk = self.clock("clk")
        self._rst_n = self.reset("rst_n", 1)

        self._restart = self.input("restart", 1)
        self._valid_in = self.input("valid_in", 1)
        self._valid_out = self.output("valid_out", 1)
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_valid(self):
            if ~self._rst_n:
                self._valid_out = 0
            else:
                self._valid_out = self._valid_in
        self.add_code(update_valid)

        for i in range(self.channel_num):
            self._l2_dist = self.input(f"p{i}_l2_dist", self.data_width)
            self._indices = self.input(f"p{i}_indices", clog2(self.total_patches))

            self._l2_dist_min = self.output(f"p{i}_l2_dist_min", self.data_width)
            self._indices_min = self.output(f"p{i}_indices_min", clog2(self.total_patches))
            @always_ff((posedge, "clk"), (negedge, "rst_n"))
            def update_min(self):
                if ~self._rst_n:
                    self._l2_dist_min = 0
                    self._indices_min = 0
                elif self._valid_in:
                    if (self._l2_dist < self._l2_dist_min) | self._restart:
                        self._l2_dist_min = self._l2_dist
                        self._indices_min = self._indices
            self.add_code(update_min)
    

if __name__ == "__main__":
    db_dut = RunningMin()
    verilog(db_dut, filename="rtl/RunningMin.sv")
