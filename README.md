# Fast-ANN-Fieldious
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
1. Install/activate vcs (For Stanford users, may require load base, load vcs in Farmshare)
2. git clone https://github.com/Chris-Not-Mikey/Fast-ANN-Fieldious.git

### Running All Tests 

1. cd Fast-ANN-Fieldious
2. python3 runtests.py 

runtests.py is based on the autograder from 272. Thus, the same commands will work.
In particular -v can be specified for verbose mode to show assertion matches


### Running A Specific Test And Viewing Waveform 

A single test can be run (and thus a particular .vcd file can be generated) and viewed with gtkwave as follows:

1. python3 runtests.py [test_name] -v
2. gtkwave dump.vcd &

test_name must be a string that matches part of the test name specified in runtests.py
A list of all test names (and a brief description) is included below

1. "test_top" -- top level test bench for all components 
2. ""
3. ""



### Full Top Level Verification with L2 Score and Image Reconstruction

While the above will show tests passing, to show the full pipeline (including off chip computation of L2 score and image reconstruction)
The following commands must be executed

1.  python3 runtests.py test_tob -v
2.  python3 l2.py 





