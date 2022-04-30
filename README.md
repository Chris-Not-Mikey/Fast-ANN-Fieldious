# Fast-ANN-Fieldious

![image](https://user-images.githubusercontent.com/54165966/165867879-52a9eb76-753d-4341-ba2a-b99ad0ebb708.png)


For EE 372 @ Stanford




## Overview

Fast ANN Fieldious is a hardware accelerator for approximate nearest neighbor fields (ANN). The following repository is our Verilog design and verification files for this accelerator.

<img width="899" alt="image" src="https://user-images.githubusercontent.com/54165966/166093855-555c4de2-8ea2-4fbe-929c-e81455e49181.png">



Our goal is to find nearest neighbors in Image B for a given Image A.
This is a very important task for computer vision, optical flow, video compression, etc.
However, it is a very computationally expensive algorithm. Interestingly, the most popular algorithm (propagation assisted kd-tree) lends itself well to hardware acceleration since it can be pipelined and executed in parallel. Thus the idea for Fast-ANN-Fieldious was born. 

More details of this problem statement and its implementation can be found in the links below.
Schematics for each block can be found in the Design Review link. A top level diagram of all blocks can be seen below:

![image](https://user-images.githubusercontent.com/54165966/166120157-2986be25-6eac-4444-ad91-6d91395445e2.png)



## Team
1. Chris Calloway 
2. Jake Ke


## Useful Links

### Project Proposal

https://docs.google.com/presentation/d/1eATEbHkYKuJgkEudkhe2r2xmGzlnZk65wf9D-JNxt4s/edit?usp=sharing

### Project Design Review

https://docs.google.com/presentation/d/1Ie0uCnQg5wL7kaqn-tUW8gMvX_XnOqE4hdrijEjCLVE/edit?usp=sharing


## Intstallation and Viewing Waveforms

### Installation
1. Install/Activatve vcs (Farmshare Specific Instructions below)
2. git clone https://github.com/Chris-Not-Mikey/Fast-ANN-Fieldious.git
3. Install Packages needed for gold model (see below)


#### Farmshare Specific Instructions for Installing vcs (May Differ for Non-Stanford Users)
1. /farmshare/home/classes/ee/admin/software/bin/centos.sh
2. module load base
3. module load vcs

#### Python Packages Needed for Gold Model 


The first two steps are optional but highly recommended

1. python3 -m venv venv
2. source venv/bin/activate.csh
3. pip install --upgrade pip (may be needed for matplotlib)
4. pip install kdtree
5. pip install matplotlib
6. pip install scikit-learn
7. pip install opencv-python
8. pip install tensorflow




### Running All Tests 

1. cd Fast-ANN-Fieldious
2. python3 runtests.py 

runtests.py is based on the autograder from 272. Thus, the same commands will work.
In particular -v can be specified for verbose mode to show assertion matches

Now however to specify which test vectors (images) to run, to run something other than default you must do:
-i "imageA" "imageB"

Example:
1. python3 runtests.py -i "stick1" "stick2"

All images can be found in "data/gold_data"
For ease of use, each image pair (test vector image A and image B pair) is reproduced below:

1. basketball1, basketball6
2. basketball_far1, basketball_far250
3. flow1smallest, flow6smallest
4. frame1ball_30, frame2ball_30
5. simple1, simple2
6. stick1, stick2
7. walking1, walking12
8. walking_far1, walking_far74


Note: do NOT include .png in filename



### Running A Specific Test And Viewing Waveform 

A single test can be run (and thus a particular .vcd file can be generated) and viewed with gtkwave as follows:

1. python3 runtests.py [test_name] -v 
2. gtkwave dump.vcd &

Example:

1. python3 runtests.py agg -v
2. gtkwave dump.vcd &

![image](https://user-images.githubusercontent.com/54165966/165996749-ff3fa46b-96c2-44ea-9b0f-8baa945aaeec.png)





test_name must be a string that matches part of the test name specified in runtests.py.
A list of all test names (and a brief description) is included below

1. "gold" -- runs Gold Model which also generates test vectors for particular image pair (necessary to run first if testing new test vectors)
2. "test_top" -- top level and FSM unit test (full pipeline test)
3. "internal_node" -- internal node unit test
4. "internal_node_tree" -- internal node tree unit test (search containing leaf algo)
5. "sorted_list" -- sorted list unit test
6. "sorter" -- Bitonic sorter unit test
7. "l2_kernel" -- l2 kernel unit test
8. "query_row_double_buffer" -- SRAM unit test 
9. "wishbone" -- wishbone interface unit test
10. "bluespec" -- blue spec async fifo (IP) unit test 
11. "agg" -- aggregator (IP) unit test
12. "l2_reconstruct" -- runs final l2 score + image reconstruction and compares to gold results (necessary to run after test_top so that correct results are compared)









