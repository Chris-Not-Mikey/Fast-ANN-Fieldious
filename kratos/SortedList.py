from kratos import *
from numpy import append

class SortedList(Generator):
    def __init__(self,
                 data_width=25,
                 idx_width=9,
                 leaf_size=8,
                 patch_size=5,
                 num_leaves=64,
                 K = 4,
                 row=30,
                 height=23,
                 channel_num=8):
        super().__init__("SortedList", False)
        self.channel_num = channel_num
        self.data_width = data_width
        self.idx_width = idx_width
        self.leaf_size = leaf_size
        self.patch_size = patch_size
        self.num_leaves = num_leaves
        self.row = row
        self.height = height
        self.K = K

        self.total_patches = (self.row - self.patch_size + 1) * (self.height - self.patch_size + 1) 
        self.leaf_addrw = clog2(self.num_leaves)
        
        self._clk = self.clock("clk")
        self._rst_n = self.reset("rst_n", 1)

        # resets all to infinity
        # and inserts the first if insert is high
        self._restart = self.input("restart", 1)
        self._insert = self.input("insert", 1)
        self._last_in = self.input("last_in", 1)
        self._l2_dist_in = self.input("l2_dist_in", self.data_width)
        self._merged_idx_in = self.input("merged_idx_in", self.leaf_addrw + self.idx_width)

        self._valid_out = self.output("valid_out", 1)
        # self.wire(self._valid_out, self._restart)

        # pipeline registers
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_valid(self):
            if ~self._rst_n:
                self._valid_out = 0
            else:
                self._valid_out = self._last_in
        self.add_code(update_valid)


        # comparison logic
        self._empty_n = self.var("empty_n", K)
        self._smaller = self.var("smaller", K)
        self._same_leafidx = self.var("same_leafidx", K)
        self._l2_dist = []
        self._merged_idx = []
        for i in range(self.K):
            self._l2_dist.append(self.output(f"l2_dist_{i}", self.data_width))
            self._merged_idx.append(self.output(f"merged_idx_{i}", self.idx_width + self.leaf_addrw))

            # can even accept input with 2047 distance
            self.wire(self._smaller[i], self._l2_dist_in <= self._l2_dist[i])
            
            self.wire(self._same_leafidx[i], self._merged_idx[i][self.leaf_addrw + self.idx_width - 1, self.idx_width] == self._merged_idx_in[self.leaf_addrw + self.idx_width - 1, self.idx_width])
        
        @always_ff((posedge, "clk"), (negedge, "rst_n"))
        def update_sorted_list(self):
            if ~self._rst_n:
                self._empty_n = 0
                for i in range(self.K):
                    self._l2_dist[i] = 0
                    self._merged_idx[i] = 0
            else:
                if self._restart:
                    # for i in range(self.K):
                    #     self._l2_dist[i] = const(pow(2, self.data_width) - 1, self.data_width)
                    self._empty_n = 0

                    if self._insert:
                        self._l2_dist[0] = self._l2_dist_in
                        self._merged_idx[0] = self._merged_idx_in
                        self._empty_n[0] = 1
                
                elif self._insert:
                    if (self._same_leafidx & (self._same_leafidx ^ ~self._empty_n)).r_or():
                        if self._same_leafidx[0] & self._smaller[0]:
                            self._l2_dist[0] = self._l2_dist_in
                        elif self._same_leafidx[1] & self._smaller[1]:
                            if self._smaller[0]:
                                self._l2_dist[0] = self._l2_dist_in
                                self._merged_idx[0] = self._merged_idx_in
                                self._l2_dist[1] = self._l2_dist[0]
                                self._merged_idx[1] = self._merged_idx[0]
                            else:
                                self._l2_dist[1] = self._l2_dist_in
                        elif self._same_leafidx[2] & self._smaller[2]:
                            if self._smaller[0]:
                                self._l2_dist[0] = self._l2_dist_in
                                self._merged_idx[0] = self._merged_idx_in
                                self._l2_dist[1] = self._l2_dist[0]
                                self._merged_idx[1] = self._merged_idx[0]
                                self._l2_dist[2] = self._l2_dist[1]
                                self._merged_idx[2] = self._merged_idx[1]
                            elif self._smaller[1]:
                                self._l2_dist[1] = self._l2_dist_in
                                self._merged_idx[1] = self._merged_idx_in
                                self._l2_dist[2] = self._l2_dist[1]
                                self._merged_idx[2] = self._merged_idx[1]
                            else:
                                self._l2_dist[2] = self._l2_dist_in
                        elif self._same_leafidx[3] & self._smaller[3]:
                            if self._smaller[0]:
                                self._l2_dist[0] = self._l2_dist_in
                                self._merged_idx[0] = self._merged_idx_in
                                self._l2_dist[1] = self._l2_dist[0]
                                self._merged_idx[1] = self._merged_idx[0]
                                self._l2_dist[2] = self._l2_dist[1]
                                self._merged_idx[2] = self._merged_idx[1]
                                self._l2_dist[3] = self._l2_dist[2]
                                self._merged_idx[3] = self._merged_idx[2]
                            elif self._smaller[1]:
                                self._l2_dist[1] = self._l2_dist_in
                                self._merged_idx[1] = self._merged_idx_in
                                self._l2_dist[2] = self._l2_dist[1]
                                self._merged_idx[2] = self._merged_idx[1]
                                self._l2_dist[3] = self._l2_dist[2]
                                self._merged_idx[3] = self._merged_idx[2]
                            elif self._smaller[2]:
                                self._l2_dist[2] = self._l2_dist_in
                                self._merged_idx[2] = self._merged_idx_in
                                self._l2_dist[3] = self._l2_dist[2]
                                self._merged_idx[3] = self._merged_idx[2]
                            else:
                                self._l2_dist[3] = self._l2_dist_in
                    else:
                        for x in range(self.K - 1, -1, -1):
                            if (~self._empty_n[x] | (self._smaller[x] & ~self._same_leafidx[x])):
                                self._l2_dist[x] = self._l2_dist_in
                                self._merged_idx[x] = self._merged_idx_in
                                self._empty_n[x] = 1
                                for i in range(x + 1, self.K):
                                    self._l2_dist[i] = self._l2_dist[i-1]
                                    self._merged_idx[i] = self._merged_idx[i-1]
                                    self._empty_n[i] = self._empty_n[i-1]
                    
        self.add_code(update_sorted_list)
    

if __name__ == "__main__":
    db_dut = SortedList()
    verilog(db_dut, filename="rtl/SortedList.sv")
