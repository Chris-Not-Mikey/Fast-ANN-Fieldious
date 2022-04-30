# Fast-ANN-Fieldious

![image](https://user-images.githubusercontent.com/54165966/165867879-52a9eb76-753d-4341-ba2a-b99ad0ebb708.png)


For EE 372 @ Stanford


## Team
1. Chris Calloway 
2. Jake Ke

## Overview

Fast ANN Fieldious is a hardware accelerator for approximate nearest neighbor fields (ANN). The following repository is our Verilog design and verification files for this accelerator.


Our goal is to find nearest neighbors in image B for a given image A
This is a very important task for computer vision, optical flow, video compression, etc.
However, it is a very computationally expensive alogorithm, but the most popular algorithm (propagation assited K-Tree) lends itself well to hardware acceleration since it can be pipelined and executed in parallel. More details can be found in the links below.



## Useful Links

### Project Proposal

https://docs.google.com/presentation/d/1eATEbHkYKuJgkEudkhe2r2xmGzlnZk65wf9D-JNxt4s/edit?usp=sharing

### Project Design Review

https://docs.google.com/presentation/d/1Ie0uCnQg5wL7kaqn-tUW8gMvX_XnOqE4hdrijEjCLVE/edit?usp=sharing


## Intstallation and Viewing Waveforms

### Installation
1. Install/Activatve vcs
2. git clone https://github.com/Chris-Not-Mikey/Fast-ANN-Fieldious.git


#### Farmshare Specific Instructions for Installing vcs (may differ for non-Stanford users)
1. /farmshare/home/classes/ee/admin/software/bin/centos.sh
2. module load base
3. module load vcs

#### Python Packages Needed for gold model 
0. (Optional: creeate venv for python packages)
1. pip install kdtree
2. pip install matplotlib
3. pip install scikit-learn
4. pip install opencv-python
5. pip install tensorflow




### Running All Tests 

1. cd Fast-ANN-Fieldious
2. python3 runtests.py 

runtests.py is based on the autograder from 272. Thus, the same commands will work.
In particular -v can be specified for verbose mode to show assertion matches

Now however to specify which test vectors (images) to run, to run something other than default you must do:
-i "imageA" "imageB

Example:
1. python3 runtests.py -i "stick1" "stick2"

All image names can be found in "data/gold_data"
Note: do NOT include .png in filename



### Running A Specific Test And Viewing Waveform 

A single test can be run (and thus a particular .vcd file can be generated) and viewed with gtkwave as follows:

1. python3 runtests.py [test_name] -v 
2. gtkwave dump.vcd &

Example:

1. python3 runtests.py agg -v
2. gtkwave dump.vcd &

![image](https://user-images.githubusercontent.com/54165966/165996749-ff3fa46b-96c2-44ea-9b0f-8baa945aaeec.png)





test_name must be a string that matches part of the test name specified in runtests.py
A list of all test names (and a brief description) is included below

1. "gold" -- runs Gold Model which also generates test vectors for particular image pair (necessary if testing new test vectors)
2. "test_top" -- top level test bench for all components 
3. "internal_node" -- internal node unit test
4. "internal_node_tree" -- internal node tree unit test (search containing leaf algo)
5. "query_row_double_buffer" -- unit test for patch SRAM
6. "wishbone" -- unit test for wishbone interface
7. "bluespec" -- unit test for blue spec async fifo (IP)
8. "agg" -- unit test for aggregator (IP)
9. "l2" -- WIP (runs l2 score + image reconstruciton and compares to gold results)









