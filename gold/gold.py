from cmath import inf
from fileinput import filename
from re import L
from tarfile import LENGTH_PREFIX
import kdtree
import statistics
from matplotlib.pyplot import axes
import numpy
import collections
from sklearn.feature_extraction import image
from sklearn.decomposition import PCA
import cv2
import heapq
import itertools
import tensorflow as tf
import os
import time
import sys
import math

################################################################
#                   GOLD.PY                                    #
################################################################
# A behavior model for Fast ANN Fieldious Hardware accelerator # 
#                                                              #
# Author: Chris Calloway, cmc2734@stanford.edu                 #
# Maintainers: Chris Calloway, cmc2734@stanford.edu            #
#           Jake Ke, jakeke@stanford.edu                       #
################################################################



def top_to_bottom(tree, patch):

    subtree = tree

    #Traverse to the naturally occurring leaf
    while (subtree.left is not None and subtree.right is not None):

        dim_index = subtree.data.idx
    

        if patch[dim_index] < subtree.data.median[dim_index]:
            subtree = subtree.left

        else:
            subtree = subtree.right
          


    # Once at the leaf, find best index

    leaf_index = subtree.data.leaf_count




    smallest_dist = inf
    index = 0

    psize = 5
    best_dists = []



    for candidate in subtree.data.patches:



        dist = numpy.linalg.norm(candidate[0:5] - patch)


        for q in best_dists:
            if int(q[0]) == int(dist): #No duplicates
                continue

        if dist < smallest_dist:
            smallest_dist = dist
            index = candidate[5]



        # We are looking for the 5 best candidates
        if len(best_dists) < 4:  #UPDATE: Changed to 4 per Jake's request

      

            best_dists.append([dist, candidate[5], subtree])
            best_dists.sort(key=lambda x: x[0])

        else:

            found = False
      
            best_dists.sort(key=lambda x: x[0])
            for comp in best_dists:

                # If calcuated distance is better than one of the current candidates
            
                if dist < comp[0] and found == False:

                    best_dists.pop()
                    best_dists.append([dist, candidate[5], subtree])
                    best_dists.sort(key=lambda x: x[0])
                    found = True


    return int(index), best_dists, leaf_index



def create_tree_recurse(patches, idx, depth):

    if len(patches) <= 5:
        # print("here len(patches")
        # print( len(patches))
        return None


    left, right, idx, median = find_dimension_median_max_spread(patches)

    depth = depth + 1
    point1 =  BetterItem(patches, idx, median, depth)

    tree = kdtree.create([point1], sel_axis=select_axis)
    #tree.add(point1)

    
 
    tree.left = create_tree_recurse(left, idx, depth)
    tree.right = create_tree_recurse(right, idx, depth)


    return tree

   



def create_tree(patches):


    # print(patches.shape)
    # print("Now add index")

    counter = 0

    new_patches = []
    for zz in range(patches.shape[0]):


        temp = list(patches[zz])
        temp[0] = round(temp[0])
        temp[1] = round(temp[1])
        temp[2] = round(temp[2])
        temp[3] = round(temp[3])
        temp[4] = round(temp[4])
        

        temp.append(counter)
        new_patches.append(temp)
        
        counter = counter + 1

    patches = numpy.array(new_patches)

  
    count = 0
    depth = 0
    left, right, idx, median = find_dimension_median_max_spread(patches)

    point1 =  BetterItem(patches, idx, median, depth)
 
    tree = kdtree.create([point1], sel_axis=select_axis)
    tree.axis = idx
    

    tree.left = create_tree_recurse(left, idx, depth)
    tree.right = create_tree_recurse(right, idx, depth)


    #kdtree.visualize(tree)
    print("Is Tree Balanced?  (IMPORTANT)")
    print(tree.is_balanced)


    idx = 0
    median = 0




    return tree

def find_dimension_median_max_spread(patches):

    patch_array = numpy.array(patches)

    total_dimensions = patch_array.shape[1] -1 # Subtract one for index dim which DOES NOT COUNT FOR SPREAD CALCULATIONS
  

    smallest = []
    largest = []
    for q in range(total_dimensions):
        smallest.append(inf)
        largest.append(-inf)
   

    # Find the smallest and largest in all patches
    for i in patches:

        counter = 0
        for j in i:

            if counter == (total_dimensions):
                break


            if j < smallest[counter]:
                smallest[counter] = j

            if j > largest[counter]:
                largest[counter] = j


            counter = counter + 1

    #Find max spread

    max_spread = 0
    idx = 0
    for z in range(total_dimensions):

        spread = largest[z] - smallest[z]
        if spread > max_spread:
            max_spread = spread
            idx = z




    # # Compute Median

    patch_array= patch_array[patch_array[:,idx].argsort()]
  
 

    # THE MEDAIN IS NOT A SINGLE NUMBER, IT IS 5

    inf_list = [float(1023),float(1023),float(1023),float(1023),float(1023), -1]
    inf_array = numpy.array([inf_list])



    split = numpy.split(patch_array,2)


    patches_l = numpy.array(split[0])

    final_l_index = patches_l.shape[0] - 1
    median = patches_l[final_l_index]

    # Round median to nearest integer
    for med in range(len(median)):

        #print(median[med])
        median[med] = int(round(median[med]))
        


    patches_r = numpy.array(split[1])


    while (patches_l.shape[0]%2 != 0):

        patches_l = numpy.append(patches_l, inf_array, axis=0 )
        patches_r = numpy.append(patches_r, inf_array, axis=0 )



  
    return patches_l, patches_r, idx, median







# Following two functions  based on https://stackoverflow.com/a/51785735/278836
def custom_extract_patches(images):
    return tf.image.extract_patches(
        images,
        (1, 5, 5, 1),
        (1, 1, 1, 1),
        (1, 1, 1, 1),
        padding="VALID")

@tf.function
def extract_patches_inverse(shape, patches):
    _x = tf.zeros(shape)
    _y = custom_extract_patches(_x)
    grad = tf.gradients(_y, _x)[0]
    return tf.gradients(_y, _x, grad_ys=patches)[0] / grad



def search_knn_custom(point, k, tree, dist=None):
        """ Return the k nearest neighbors of point and their distances
        point must be an actual point, not a node.
        k is the number of results to return. The actual results can be less
        (if there aren't more nodes to return) or more in case of equal
        distances.
        dist is a distance function, expecting two points and returning a
        distance value. Distance values can be any comparable type.
        The result is an ordered list of (node, distance) tuples.
        """

        if k < 1:
            raise ValueError("k must be greater than 0.")

        if dist is None:
            get_dist = lambda n: n.dist(point)
        else:
            get_dist = lambda n: dist(n.data, point)

        results = []

        _search_node(point, k, results, get_dist, itertools.count(), tree)

        # We sort the final result by the distance in the tuple
        # (<KdNode>, distance).
        return [(node, -d) for d, _, node in sorted(results, reverse=True)]


def _search_node(point, k, results, get_dist, counter, tree):

    if not tree:
        return
    
    nodeDist = get_dist(tree)

    # Add current node to the priority queue if it closer than
    # at least one point in the queue.
    #
    # If the heap is at its capacity, we need to check if the
    # current node is closer than the current farthest node, and if
    # so, replace it.
    item = (-nodeDist, next(counter), tree)
    if len(results) >= k:
        if -nodeDist > results[0][0]:
            heapq.heapreplace(results, item)
    else:
        heapq.heappush(results, item)
    # get the splitting plane
    split_plane = tree.data[tree.axis]
    # get the squared distance between the point and the splitting plane
    # (squared since all distances are squared).
    plane_dist = point[tree.axis] - split_plane
    plane_dist2 = plane_dist * plane_dist

    # Search the side of the splitting plane that the point is in
    if point[tree.axis] < split_plane:
        if tree.left is not None:
           _search_node(point, k, results, get_dist, counter,  tree.left)
    else:
        if tree.right is not None:
            _search_node(point, k, results, get_dist, counter,tree.right)


    # REMOVED: We will not implment the following in RTL (it slightly improves results, but is not in the original paper, and will complicate implementation)
    # Search the other side of the splitting plane if it may contain
    # # points closer than the farthest point in the current results.
    # if -plane_dist2 > results[0][0] or len(results) < k:
    #     if point[tree.axis] < tree.data[tree.axis]:
    #         if tree.right is not None:
    #             _search_node(point, k, results, get_dist,
    #                                     counter, tree.right)
    #     else:
    #         if tree.left is not None:
    #             _search_node(point, k, results, get_dist,
    #                                     counter, tree.left)




def select_axis(axis):

    new_axis = axis

    return new_axis



def compute_distance(data, point):
    dist = 0

    data_list = []

    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    smallest_dist = inf
    index = 0
    for candidate in data.patches:
        dist = numpy.linalg.norm(candidate[0:5] - point2)

        if dist < smallest_dist:
            smallest_dist = dist
            index = candidate[5]

    return smallest_dist,  int(index)


# Unused: Can be used to test if RERANKING, per the papers, is actually effective
# Empirically, we found this NOT to be effective
def compute_distance_rerank(data, point, _pca_model):
    dist = 0

    data_list = []


    point = _apply_inverse_pca(point, _pca_model)

    point1 = numpy.array(data_list)
    point2 = numpy.array(point)


    smallest_dist = inf
    index = 0
    for candidate in data.patches:

        point1 = _apply_inverse_pca(candidate[0:5], _pca_model)


        dist = numpy.linalg.norm(point1 - point2)
        # print("rerank dist")
        # print(dist)

        if dist < smallest_dist:
            smallest_dist = dist
            index = candidate[5]

    return smallest_dist,  int(index)






def compute_distance_non_median(data, point):


    dist = 0

    data_list = []

    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    #dist2 = numpy.linalg.norm(point1 - point2)
    dist = 0
    count = 0
    for i in data.patches:
        # print(i)
        # print(i[0:4])
        dist =  dist + (numpy.linalg.norm(i[0:4] - point2))

    if (len(data.patches) > 8):
        # print("Length of Patches")
        # print(len(data.patches))
        dist = dist + 1000000

    # else:
    #     print("No penalty")
    #     print(len(data.patches))



    return dist

def compute_all_distances_median(candidate, point):

    dist = 0

    data_list = []

 
    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    #dist2 = numpy.linalg.norm(point1 - point2)
    dist = inf
    best_node = None
    best_five = []
    for cand in candidate:

        current_dist = numpy.linalg.norm(cand[2].data.best_dim - point2)
     
        best_five = sorted(best_five)

        if len(best_five) < 5:
        
            best_five.append([current_dist, cand[2].data.count, cand[2]])
            best_five = sorted(best_five)

        else:
            for comp in best_five:

                # If calcuated distance is better than one of the current candidates
                if current_dist < comp[0]:
                    best_five = sorted(best_five)
                    best_five.pop()
                    best_five.append([current_dist, cand[2].data.count, cand[2]])
                    best_five = sorted(best_five)
                    break

        if current_dist < dist:
            dist = current_dist
            best_node = cand[2]

    
    return dist, best_node, best_five





def compute_all_distances_non_median(candidate, point):
    dist = 0

    data_list = []

 
    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    #dist2 = numpy.linalg.norm(point1 - point2)
    dist = inf
    best_node = None
    best_five = []
    for cand in candidate:

     
        best_five = sorted(best_five)


        current_dist = 0
        count = 0
        for i in data.data:

            if count == 5:
                current_dist =  current_dist + numpy.linalg.norm(i - point2)

        current_dist = compute_distance_non_median(cand[2], point)


        if len(best_five) < 5:
        
            best_five.append([dist, cand[2].data.count, cand[2]])
            best_five = sorted(best_five)

        else:
            for comp in best_five:

                # If calcuated distance is better than one of the current candidates
                if current_dist < comp[0]:
                    best_five = sorted(best_five)
                    best_five.pop()
                    best_five.append([current_dist, cand[2].data.count, cand[2]])
                    best_five = sorted(best_five)
                    break

        if current_dist < dist:
            dist = current_dist
            best_node = cand[2]

    
    return dist, best_node, best_five




def compute_all_distances_find_best(candidate, point):
    dist = 0

    data_list = []

 
    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    #dist2 = numpy.linalg.norm(point1 - point2)
    dist = inf
    best_node = None
    best_five = []
    for cand in candidate:

      
     
        best_five = sorted(best_five)
        for node in cand[2].data:

            current_dist = numpy.linalg.norm(numpy.array(node) - point2)

            if len(best_five) < 5:
            
                best_five.append([dist, cand[2].data.count, cand[2]])
                best_five = sorted(best_five)

            else:
                for comp in best_five:

                    # If calcuated distance is better than one of the current candidates
                    if current_dist < comp[0]:
                        best_five = sorted(best_five)
                        best_five.pop()
                        best_five.append([current_dist, cand[2].data.count, cand[2]])
                        best_five = sorted(best_five)
                        break

            if current_dist < dist:
                dist = current_dist
                best_node = cand[2]

    
    return dist, best_node, best_five


def compute_all_distances_find_best_new(candidate, point, _pca_model):
    dist = 0

    data_list = []

 
    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    #dist2 = numpy.linalg.norm(point1 - point2)
    dist = inf
    best_node = None
    best_five = []
    # print(candidate)
    # print("entering loop")

    current_idx = []
    
    for cand in candidate:

       # current_dist = numpy.linalg.norm(cand[2].data.best_dim - point2)

        current_dist, idx = compute_distance(cand[2].data, point2)
        # print(current_dist)
        # print(idx)
        #best_five = sorted(best_five)

        if len(best_five) < 4 and idx not in current_idx: #change to 4
 
       
            best_five.append([current_dist, idx, cand[2]])
            #best_five = sorted(best_five)
            best_five.sort(key=lambda x: x[0])
            current_idx.append(idx)

        else:
            for comp in best_five:

                # If calcuated distance is better than one of the current candidates
                if current_dist < comp[0]:

                    #print("Inner loop start")
                    add = True
                    for qqq in best_five:

                        if idx == qqq[1]:
                            add = False
                   

                 

                    if add:
                        #best_five = sorted(best_five)
                        best_five.sort(key=lambda x: x[0])
                        best_five.pop()
                        best_five.append([current_dist, idx, cand[2]])
                        #best_five = sorted(best_five)
                        best_five.sort(key=lambda x: x[0])
                    break
                    

        if current_dist < dist:
            dist = current_dist
            best_node = cand[2]

    
    return dist, best_node, best_five


#Source: https://www.geeksforgeeks.org/breadth-first-search-or-bfs-for-a-graph/
# Function to print a BFS of graph
def BFS(tree, file):

    leaf_counter = 0 #Corresponds to Leaf index in memory
  
    #Open Two Files
    f_int_str = file + "/internalNodes.txt"
    f_leaf_str = file + "/leafNodes.txt"

    f_int = open(f_int_str, "a")
    f_leaf = open(f_leaf_str, "a")


    # Create a queue for BFS
    queue = []

    # Mark the source node as
    # visited and enqueue it
    queue.append(tree)
    tree.data.visited = True

  

    while queue:

        # Dequeue a vertex from
        # queue and print it
        s = queue.pop(0)

        is_leaf = False
        if s.left is None and s.right is None:
            is_leaf = True

        # print(s)
        # print(is_leaf)

        if is_leaf:
            patch_str = "#Starting Leaf \n"
            #f_leaf.write(patch_str)
            s.data.leaf_count = leaf_counter
            # print("Here Leaf Counter")
            # print(leaf_counter)
            leaf_counter = leaf_counter + 1
            for data in s.data.patches:

                patch_str = "#Starting Patch \n"
                #f_leaf.write(patch_str)
                ct = 0
                for dim in data:
                    dim_str = str(int(dim)) + "\n"
                    if ct == 5:
                        dim_str = str(int(dim)) + "\n"

                    f_leaf.write(dim_str)
                    ct = ct +1

        else:
            
            #Axis 
            axis_str = str(s.data.axis) + "\n"
            median_str = str(int(s.data.median[s.data.axis])) + "\n"
            f_int.write(axis_str)
            f_int.write(median_str)

        # Get all adjacent vertices of the
        # dequeued vertex s. If a adjacent
        # has not been visited, then mark it
        # visited and enqueue it
        
        if s.left is not None:
            if s.left.data.visited == False:
                queue.append(s.left)
                s.left.data.visited = True


        if s.right is not None:
            if s.right.data.visited == False:
                queue.append(s.right)
                s.right.data.visited = True


    f_int.close()
    f_leaf.close()

def preorder(tree):
    """ iterator for nodes: root, left, right """

    if not tree:
        return

    yield tree

    if tree.left:
        for x in tree.left.preorder():
            yield x

    if tree.right:
        for x in tree.right.preorder():
            yield x




def preorderLeaves(tree):
    """ iterator for nodes: root, left, right """

    result = []

    leaves = []

    if not tree:
        return

    #yield tree
    #Root of tree is not a leaf (will fail in a very degenerate case of tree of size 1)
    #result.append([tree.data.data, tree.data.median_max_spread, tree.data.best_dim_idx])

    if tree.left:
        for x in tree.left.preorder():
            #yield x
            #result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])

            if (x.left is None and x.right is None):
                leaves.append(x)

            

    if tree.right:
        for x in tree.right.preorder():
            #yield x
            #result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])

            if (x.left is None and x.right is None):
                leaves.append(x)

    return leaves



def preorderMedian(tree):
    """ iterator for nodes: root, left, right """

    result = []

    leaves = []

    if not tree:
        return

    #yield tree
    result.append([tree.data.data, tree.data.median_max_spread, tree.data.best_dim_idx])

    if tree.left:
        for x in tree.left.preorder():
            #yield x
            result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])


    if tree.right:
        for x in tree.right.preorder():
            #yield x
            result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])

    return result




def preorderMedian(tree):
    """ iterator for nodes: root, left, right """

    result = []

    if not tree:
        return

    #yield tree
    result.append([tree.data.data, tree.data.median_max_spread, tree.data.best_dim_idx])

    if tree.left:
        for x in tree.left.preorder():
            #yield x
            result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])

    if tree.right:
        for x in tree.right.preorder():
            #yield x
            result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])

    return result


def writeLeaf(tree, f, result):

    left_address = inf
    right_address = inf
    current_address = inf


    if tree.data is not None:
        current_address = 0
        for x in result:
                
            one = numpy.array(x[0])
            two = numpy.array(tree.data.data)
            comparison = one == two
            equal_arrays = comparison.all()
            if equal_arrays:
                break
            current_address = current_address + 1


    if tree.left.data is not None:
        left_address = 0
       
        for x in result:
                
            one = numpy.array(x[0])
            two = numpy.array(tree.left.data.data)
            comparison = one == two
            equal_arrays = comparison.all()
            if equal_arrays:
                break
            left_address = left_address + 1


    if tree.right.data is not None:
        right_address = 0
        
        for x in result:
                
            one = numpy.array(x[0])
            two = numpy.array(tree.right.data.data)
            comparison = one == two
            equal_arrays = comparison.all()
            if equal_arrays:
                break
            right_address = right_address + 1
                
               

 

    start_str = "#Start_Node: " + str(tree.data.count) + "\n" 
    end_str = "#End_Node: " + str(tree.data.count) + "\n" 
    f.write(start_str)
    counter =0
    for patch in tree.data.data:
        patch_str = "#Patch: " + str(counter) + "\n"
        f.write(patch_str)

        counter = counter + 1
        for dim in patch:
            
            dim_str = str(dim) + "\n"
            f.write(dim_str)


    f.write("#Address\n")
    median_str = str(current_address) + "\n"
    f.write(median_str)

    f.write("#Left_Address\n")
    median_str = str(left_address) + "\n"
    f.write(median_str)

    f.write("#Right_Address\n")
    median_str = str(right_address) + "\n"
    f.write(median_str)
  
    f.write("#Median\n")
    median_str = str(tree.data.median_max_spread) + "\n"
    f.write(median_str)

    f.write("#Dimension_Index\n")
    dim_idx_str = str(tree.data.best_dim_idx) + "\n"
    f.write(dim_idx_str)

    f.write(end_str)
    f.write("#End_Node\n")

 

def preorderFile(tree):
    """ iterator for nodes: root, left, right """


    result = preorderMedian(tree)

    f = open("myfile.txt", "w")

    if not tree:
        return

    #yield tree
    #result.append([tree.data.data, tree.data.median_max_spread, tree.data.best_dim_idx])
    address = 0
    writeLeaf(tree, f, result)



    if tree.left:
        for x in tree.left.preorder():
            #yield x
            #result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])
            writeLeaf(x, f,result)

    if tree.right:
        for x in tree.right.preorder():
            #yield x
            #result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])
            writeLeaf(x, f,result)

    return result



def preorderNewFile(tree, f, address):
    """ iterator for nodes: root, left, right """

    if not tree:
        return

    if tree.left:
        preorderNewFile(tree.left, address+1)
        
    if tree.right:
        preorderNewFile(tree.right, address+1)
        



   
class BetterItem(object):
    def __init__(self, patches, idx, median, depth):
     

        self.patches = patches
        self.data = median
        self.idx = idx
        self.median = median
        self.depth = depth

        self.axis = idx

        self.visited = False

        self.leaf_count = 0
 


    def __eq__(self, other):
        if(self.patches == other.patches):
            return True
        else:
            return False  
       

    def __len__(self):
        return len(self.data)

    def __getitem__(self, i):

        return self.data[i]

    def __repr__(self):
        return 'Item({}, {})'.format(self.idx, self.depth)
        #return 'Item({}, {}, {})'.format(self.count, self.idx, self.median )







class Item(object):
    def __init__(self, patches, count):
     
        self.data = patches
        self.max_spread = 0
        self.median_max_spread = 0
        self.best_dim = patches[0]
        self.best_dim_idx = 0
        self.count = count

    def __len__(self):
        return len(self.data)

    def __getitem__(self, i):
      
    
        #print(self.count)

        # if i >=5:
        #     print(i)
        #     print(self.data[0])
        #     i = 4

        counter = 0
        for q in self.data:

           
            min_val = min(q[0], q[1], q[2], q[3], q[4])
            max_val = max(q[0], q[1], q[2], q[3], q[4])
            spread = abs(max_val - min_val)
       
            if spread > self.max_spread:
            
                self.max_spread = spread
                self.median_max_spread = statistics.median(q)
                self.best_dim = q
                self.best_dim_idx = counter
            
            counter = counter + 1
        
        return self.best_dim[i]

    def __repr__(self):
        return 'Item({}, {}, {}, {},{})'.format(self.data[0], self.data[1], self.data[2],self.data[3],self.data[4] )



def _create_patches(img, psize):

    n_channels = img.shape[-1]

    patches = image.extract_patches_2d(img, (psize, psize))

    if True > 0:
        print("Patches for image have shape: {}".format(patches.shape))

    patches = patches.reshape((-1, psize * psize * n_channels))

    if True > 0:
        print("Reshaped patches for image have shape: {}".format(patches.shape))

    return patches

def _fit_pca_model(image_a, image_b, psize, dim_reduced):

    subset_a = image.extract_patches_2d(
        image_a,
        (psize, psize),
        max_patches=int(1000 / 2),
        random_state=0,
    )

    subset_b = image.extract_patches_2d(
        image_b,
        (psize, psize),
        max_patches=int(1000 / 2),
        random_state=0 + 1,
    )

    subset_a = subset_a.reshape((subset_a.shape[0], -1))
    subset_b = subset_b.reshape((subset_b.shape[0], -1))
    both_subsets = numpy.concatenate((subset_a, subset_b), axis=0)

    model = PCA(n_components=dim_reduced)
    model.fit(both_subsets)

    return model

def _apply_pca(patches, _pca_model):

    patches_reduced = _pca_model.transform(patches).astype(numpy.int16)

#     for i in patches_reduced:
#         if i[0] > 1023:
#             print('bad')

    if True > 0:
        print("Patches reduced for image: {}".format(patches_reduced.shape))

    return patches_reduced


def _apply_inverse_pca(patches_reduced, _pca_model):

    patches = _pca_model.inverse_transform(patches_reduced)

    #patches_reduced = _pca_model.transform(patches).astype(numpy.float32)

    # if True > 0:
    #     print("Patches for un-reduced image: {}".format(patches.shape))

    return patches




if __name__ == "__main__":


    images_a_storage = ['Avatar FULL 1080p 00402', 'Avatar FULL 1080p 00907', 'Avatar FULL 1080p 01223', 'Avatar FULL 1080p 01361', 'Avatar FULL 1080p 01748', 'Avatar FULL 1080p 02162', 'Avatar FULL 1080p 03274', 'Avatar FULL 1080p 03365', 'Avatar FULL 1080p 04250', 'Avatar FULL 1080p 04275', 'Avatar FULL 1080p 04302', 'Avatar FULL 1080p 04414', 'Avatar FULL 1080p 04663', 'Avatar FULL 1080p 04770', 'Avatar FULL 1080p 04884', 'Avatar FULL 1080p 05160', 'Avatar FULL 1080p 05433', 'Avatar FULL 1080p 05446', 'Avatar FULL 1080p 05565', 'Avatar FULL 1080p 05672', 'Avatar FULL 1080p 05745', 'Avatar FULL 1080p 05952', 'Avatar FULL 1080p 06004', 'Jackass 3D 0189', 'Jackass 3D 0415', 'Jackass 3D 0995', 'Jackass 3D 1256', 'Jackass 3D 1736', 'Little Fockers 0885', 'Little Fockers 0933', 'Little Fockers 2675', 'Mortal Combat 0481', 'Mortal Combat 0524', 'Mortal Combat 0663', 'Mortal Combat 0839', 'Mortal Combat 0917', 'Mortal Combat 0943', 'Mortal Combat 0998', 'Mortal Combat 1044', 'Mortal Combat 1059', 'Mortal Combat 1107', 'Mortal Combat 1116', 'Mortal Combat 1310', 'Mortal Combat 1409', 'Mortal Combat 1441', 'Mortal Combat 1452', 'Mortal Combat 1469', 'Mortal Combat 1552', 'Mortal Combat 1607', 'Mortal Combat 1672', 'Never back down 0351', 'Never back down 0382', 'Never back down 0485', 'Never back down 0543', 'Never back down 0581', 'Never back down 0689', 'Never back down 0727', 'Never back down 0798', 'Never back down 0994', 'Never back down 1032', 'Never back down 1413', 'Never back down 1577', 'Never back down 1776', 'Never back down 1979', 'Never back down 2046', 'Never back down 2115', 'Never back down 2829', 'Pressure Cooker 0137', 'Pressure Cooker 0222', 'Pressure Cooker 0363', 'Pressure Cooker 0557', 'Pressure Cooker 1118', 'Pressure Cooker 1233', 'Pressure Cooker 1347', 'Pressure Cooker 1412', 'Pressure Cooker 1494', 'Pressure Cooker 1554', 'Pressure Cooker 1734', 'Pressure Cooker 1864', 'Pressure Cooker 2050', 'Pressure Cooker 2196', 'Pressure Cooker 2410', 'Pressure Cooker 2414', 'Pressure Cooker 2737', 'Prince Of Persia 0580', 'Prince Of Persia 0605', 'Prince Of Persia 0777', 'Prince Of Persia 1280', 'Prince Of Persia 1317', 'Prince Of Persia 1371', 'Prince Of Persia 1523', 'Prince Of Persia 1620', 'Prince Of Persia 1854', 'Prince Of Persia 1935', 'Prince Of Persia 1952', 'Prince Of Persia 1994', 'Prince Of Persia 2209', 'Prince Of Persia 2379', 'Prince Of Persia 2497', 'Prince Of Persia 2552', 'Prince Of Persia 2742', 'Prince Of Persia 2814', 'Prince Of Persia 2846', 'Prince Of Persia 2985', 'Prince Of Persia 2995', 'Prince Of Persia 3041', 'Prince Of Persia 3054', 'Prince Of Persia 3080', 'Prince Of Persia 3180', 'Prince Of Persia 3221', 'Prince Of Persia 3248', 'Prince Of Persia 3793', 'Prince Of Persia 3973', 'Prince Of Persia 3995', 'Prince Of Persia 4120', 'Resident Evil Afterlife 0245', 'Resident Evil Afterlife 0476', 'Resident Evil Afterlife 1001', 'Resident Evil Afterlife 1083', 'Resident Evil Afterlife 1458', 'Resident Evil Afterlife 1709', 'Resident Evil Afterlife 2217', 'Resident Evil Afterlife 2613', 'Resident Evil Afterlife 3060', 'Resident Evil Afterlife 3235', 'Resident Evil Afterlife1785']
    images_b_storage = ['Avatar FULL 1080p 00426', 'Avatar FULL 1080p 00942', 'Avatar FULL 1080p 01264', 'Avatar FULL 1080p 01376', 'Avatar FULL 1080p 01786', 'Avatar FULL 1080p 02200', 'Avatar FULL 1080p 03299', 'Avatar FULL 1080p 03379', 'Avatar FULL 1080p 04269', 'Avatar FULL 1080p 04285', 'Avatar FULL 1080p 04321', 'Avatar FULL 1080p 04422', 'Avatar FULL 1080p 04688', 'Avatar FULL 1080p 04791', 'Avatar FULL 1080p 04887', 'Avatar FULL 1080p 05175', 'Avatar FULL 1080p 05444', 'Avatar FULL 1080p 05459', 'Avatar FULL 1080p 05579', 'Avatar FULL 1080p 05683', 'Avatar FULL 1080p 05755', 'Avatar FULL 1080p 05962', 'Avatar FULL 1080p 06026', 'Jackass 3D 0215', 'Jackass 3D 0437', 'Jackass 3D 1026', 'Jackass 3D 1304', 'Jackass 3D 1778', 'Little Fockers 0902', 'Little Fockers 0965', 'Little Fockers 2810', 'Mortal Combat 0520', 'Mortal Combat 0564', 'Mortal Combat 0687', 'Mortal Combat 0857', 'Mortal Combat 0925', 'Mortal Combat 0959', 'Mortal Combat 1019', 'Mortal Combat 1049', 'Mortal Combat 1069', 'Mortal Combat 1115', 'Mortal Combat 1123', 'Mortal Combat 1315', 'Mortal Combat 1418', 'Mortal Combat 1445', 'Mortal Combat 1464', 'Mortal Combat 1483', 'Mortal Combat 1575', 'Mortal Combat 1614', 'Mortal Combat 1692', 'Never back down 0367', 'Never back down 0398', 'Never back down 0500', 'Never back down 0556', 'Never back down 0604', 'Never back down 0707', 'Never back down 0743', 'Never back down 0820', 'Never back down 0999', 'Never back down 1213', 'Never back down 1432', 'Never back down 1634', 'Never back down 1783', 'Never back down 2040', 'Never back down 2066', 'Never back down 2131', 'Never back down 2846', 'Pressure Cooker 0155', 'Pressure Cooker 0246', 'Pressure Cooker 0416', 'Pressure Cooker 0596', 'Pressure Cooker 1137', 'Pressure Cooker 1254', 'Pressure Cooker 1368', 'Pressure Cooker 1450', 'Pressure Cooker 1527', 'Pressure Cooker 1589', 'Pressure Cooker 1773', 'Pressure Cooker 1922', 'Pressure Cooker 2089', 'Pressure Cooker 2200', 'Pressure Cooker 2411', 'Pressure Cooker 2461', 'Pressure Cooker 2751', 'Prince Of Persia 0598', 'Prince Of Persia 0632', 'Prince Of Persia 0789', 'Prince Of Persia 1287', 'Prince Of Persia 1331', 'Prince Of Persia 1389', 'Prince Of Persia 1573', 'Prince Of Persia 1648', 'Prince Of Persia 1884', 'Prince Of Persia 1951', 'Prince Of Persia 1963', 'Prince Of Persia 2006', 'Prince Of Persia 2214', 'Prince Of Persia 2395', 'Prince Of Persia 2515', 'Prince Of Persia 2571', 'Prince Of Persia 2751', 'Prince Of Persia 2815', 'Prince Of Persia 2854', 'Prince Of Persia 2994', 'Prince Of Persia 3013', 'Prince Of Persia 3053', 'Prince Of Persia 3067', 'Prince Of Persia 3087', 'Prince Of Persia 3204', 'Prince Of Persia 3247', 'Prince Of Persia 3360', 'Prince Of Persia 3808', 'Prince Of Persia 3987', 'Prince Of Persia 4010', 'Prince Of Persia 4133', 'Resident Evil Afterlife 0327', 'Resident Evil Afterlife 0479', 'Resident Evil Afterlife 1006', 'Resident Evil Afterlife 1096', 'Resident Evil Afterlife 1487', 'Resident Evil Afterlife 1719', 'Resident Evil Afterlife 2231', 'Resident Evil Afterlife 2631', 'Resident Evil Afterlife 3085', 'Resident Evil Afterlife 3247', 'Resident Evil Afterlife1797']



    multi_images = False
    #our max l2 distance truncates at 23 bits
    MAX_DIST = (2**23) - 1 

    if len(sys.argv) < 4:

        print("[ERROR] must supply [image A] [image B] [destination_folder] " )
        print("Example: python3 gold.py walking1 walking12 ./ ")
        exit()

    if len(sys.argv) >= 5:
        if sys.argv[4] == "multi":
            multi_images = True
        else:
            multi_images = False

  


    # starting time
    start = time.time()


    numpy.random.seed(0)
    psize = 5 # Patch size of 5x5 (much better results than 8x8 for minimal memory penalty)
    dim_reduced = 5


    destination_folder = sys.argv[3] #It would be best if but things in their proper folder. However, I don't know how to pass filenames with vcs ~Chris

    file_name_a = sys.argv[1] #Image A
    file_name_b = sys.argv[2] #Image B


    print("Deleting .txt files that will be recreated in this run")

    if os.path.exists(destination_folder + "gold_l2_score.txt"):
        os.remove(destination_folder + "gold_l2_score.txt")

    if os.path.exists(destination_folder + "internalNodes.txt"):
        os.remove(destination_folder + "internalNodes.txt")

    if os.path.exists(destination_folder + "leafNodes.txt"):
        os.remove(destination_folder + "leafNodes.txt")

    if os.path.exists(destination_folder + "patches.txt"):
        os.remove(destination_folder + "patches.txt")

    if os.path.exists(destination_folder + "expectedIndex.txt"):
        os.remove(destination_folder + "expectedIndex.txt")
        
    if os.path.exists(destination_folder + "expectedDistance.txt"):
        os.remove(destination_folder + "expectedDistance.txt")


  
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)


    image_names_a = [file_name_a]
    image_names_b = [file_name_b]

    if multi_images:
        for name in images_a_storage:
            image_names_a.append(name)

        for nameb in images_b_storage:
            image_names_b.append(nameb)
        

    for file_name_a, file_name_b in zip(image_names_a, image_names_b):
        

        #TODO parameterize folder to find data (make default what is in most recent commit for legacy purposes)
        image_a_str = "./data/gold_data/" + file_name_a + ".png" 
        image_a = cv2.imread(image_a_str)

        image_b_str = "./data/gold_data/" + file_name_b + ".png"
        image_b = cv2.imread(image_b_str)

        img2 = cv2.imread(image_b_str)

        img_test_str = "./data/gold_data/" + file_name_a + "_copy.png" 
        image_test = cv2.imread(img_test_str)
        # image_b = cv2.cvtColor(image_b, cv2.COLOR_BGR2GRAY)
        # image_b = cv2.cvtColor(image_b,cv2.COLOR_GRAY2RGB)

        reconstruct_file_name = "./data/gold_results/" + file_name_a + "_reconstruct.png"
        reconstruct_file_name_2 = "./data/gold_results/" + file_name_a + "_reconstruct_temp.png"


        #Image Dimensions
        print(image_a.shape)

        im_height = image_a.shape[1]
        im_width = image_a.shape[0]
        print(im_height)

        #row_size = 56 #Row Size = (h-p+1)


        row_size = image_a.shape[1] - psize + 1
    
        col_size = image_a.shape[0] - psize + 1

        print(row_size)

        # (1) fit pca model (on subset of the data)

        _pca_model = _fit_pca_model(image_a, image_b, psize, dim_reduced)
    

        # (2) create patches

        patches_a = _create_patches(image_a, psize)
        patches_b = _create_patches(image_b, psize)
    

        # (3) apply pca model
        # FIXME: patches are converted to float32/float64 here; can
        # be handled with less memory via C function
        patches_a_reduced = _apply_pca(patches_a, _pca_model)
        patches_b_reduced = _apply_pca(patches_b, _pca_model)


        tree = create_tree(patches_b_reduced)
    
        print(patches_b_reduced.shape)

        max_patches = patches_b_reduced.shape[0]

        inf_list = [float(1023),float(1023),float(1023),float(1023),float(1023)]
        inf_array = numpy.array([inf_list])
        print(inf_array.shape)


        while (patches_b_reduced.shape[0]%5 != 0):

            patches_b_reduced = numpy.append(patches_b_reduced, inf_array, axis=0 )

        #Split into groups of 5 to create the KD Tree
        split_num = patches_b_reduced.shape[0]/psize
        split = numpy.split(patches_b_reduced, split_num)
    

        #Create an Item Class for each node
        item_list = []
        for nodek in range(int(split_num)):

            item_list.append(Item(split[nodek], nodek))


        #  The root node
        #print(tree)
        # ...contains "data" field with an Item, which contains the payload in "data" field

        # Create File For Verification
        #TODO: FIX
        #preorderFile(tree)


        # All functions work as intended, a payload is never lost
        # result = tree.search_knn([ 193.19313049,   -1.66310644, -201.89816284,  -29.54750443,   42.18569565], k=1, dist=compute_distance_non_median)
        # # result[0] #Result Node + Distance
        # # result[0][0] # Node
        # # result[0][1] #Distance
        # # result[0][0].data.count #Index/5 
        # # result[0][0].data.best_dim_idx #Best Dimension
        # index = psize*(result[0][0].data.count) + result[0][0].data.best_dim_idx
        # distance = result[0][1]


        # print(len(patches_a_reduced))
        # asf()


        #Experiment with using ints instead

        file_patches_str = destination_folder + "/patches.txt"    
        f_patches = open(file_patches_str, "a")

        for patchRound in patches_a_reduced:

            patchRound[0] = round(patchRound[0])
            if (patchRound[0] > 1023):
                #print(patchRound[0])
                patchRound[0] = 1023

            if (patchRound[0] < -1023):
                print(patchRound[0])
                patchRound[0] = -1023
            

            patch_str = str(int(patchRound[0])) + "\n"
            f_patches.write(patch_str)
            patchRound[1] = round(patchRound[1])
            if (patchRound[1] > 1023):
                #print(patchRound[1])
                patchRound[1] = 1023

            if (patchRound[1] < -1023):
                print(patchRound[1])
                patchRound[1] = -1023
                
            

            patch_str = str(int(patchRound[1])) + "\n"
            f_patches.write(patch_str)
            patchRound[2] = round(patchRound[2])

            if (patchRound[2] > 1023):
                #print(patchRound[2])
                patchRound[2] = 1023


            if (patchRound[2] < -1023):
                print(patchRound[2])
                patchRound[2] = -1023

            patch_str = str(int(patchRound[2])) + "\n"
            f_patches.write(patch_str)
            patchRound[3] = round(patchRound[3])

            if (patchRound[3] > 1023):
                #print(patchRound[3])
                patchRound[3] = 1023


            if (patchRound[3] < -1023):
                print(patchRound[3])
                patchRound[3] = -1023


            patch_str = str(int(patchRound[3])) + "\n"
            f_patches.write(patch_str)
            patchRound[4] = round(patchRound[4])

            if (patchRound[4] > 1023):
                #print(patchRound[4])
                patchRound[4] = 1023

            if (patchRound[4] < -1023):
                print(patchRound[4])
                patchRound[4] = -1023

            patch_str = str(int(patchRound[4])) + "\n"
            f_patches.write(patch_str)


        f_patches.close()

        nn_indices = []
        nn_distances = []
        nn_nodes = []
        nn_best_dists = []
        nn_row_storage = []

        BFS(tree,destination_folder )
        
        
        nodes_str = destination_folder + "/internalNodes.txt"
        nodes_patchs_str = destination_folder + "/nodes_patches.txt"
        nodes_patchs_2_str = destination_folder + "/nodes_patches_2.txt"
        exp_patchs_str = destination_folder + "/expected_patches.txt"
        
        gold_buffer_str_1 = "./data/gold_data/buffer_1.txt" #Files that hold a few 0's for padding 
        gold_buffer_str_2 = "./data/gold_data/buffer_2.txt"
        
        cat_nodes_patchs_str =  "cat " + gold_buffer_str_1 + " " + nodes_str + " " + gold_buffer_str_2 + " " + file_patches_str + " > " + nodes_patchs_str
        
        cat_nodes_patchs_2_str =  "cat " + gold_buffer_str_1 + " " + nodes_str + " " + gold_buffer_str_1 + " " + gold_buffer_str_2 + " " + file_patches_str + " > " + nodes_patchs_2_str
        
        cat_exp_patchs_str =  "cat " + file_patches_str + " > " + exp_patchs_str
        os.system(cat_nodes_patchs_str)
        os.system(cat_nodes_patchs_2_str)
        os.system(cat_exp_patchs_str)


    

        # Top to Bottom Traversal
        # TODO: Make query from scratch
        count = 0

        f_top_bottom_leaf_str = destination_folder + "/topToBottomLeafIndex.txt"
        f_top_bottom_leaf_idx = open(f_top_bottom_leaf_str, "w")
        for patchA in patches_a_reduced:

            nn_best_dists = []

            # TODO: Report best 5 (k) results
            index, nn_best_dists, leaf_index  = top_to_bottom(tree, patchA)

            leaf_index_str = str(int(leaf_index)) + "\n"
            f_top_bottom_leaf_idx.write(leaf_index_str)



            # print(index)
            # print(leaf_index)
            # print(patchA)
    

            nn_indices.append(index)
        

            # nn_best_dists = sorted(nn_best_dists)
            nn_row_storage.append(nn_best_dists)

        f_top_bottom_leaf_idx.close()


        patches_a_reconst = patches_b[nn_indices]
        diff = patches_a.astype(numpy.float32) - patches_a_reconst.astype(numpy.float32)
        l2 = numpy.mean(numpy.linalg.norm(diff, axis=1))
        print("Overall Top to Bottom L2 score: {}".format(l2))
            


        # If a new leaf was found in step 1, then a brute-force search is performed on that leaf to improve the k candidates. 


        # # Full (Pre-Order) Traversal of first Row
        #TODO: Remove internal nodes
        preorderNodes = preorderLeaves(tree)

    
    


        row_idx_counter = 0

        nn_full_indices = []
        nn_full_distances = []
        row_storage = []


    
        f_exact_row_str = destination_folder + "/exactFirstRowBestIndex.txt"
        f_exact_row = open(f_exact_row_str, "w")
        for patchA2 in patches_a_reduced:

            # Only do full traversal on first row (of patch dimensions)
            if row_idx_counter >= row_size:
                break
            
            best_dist = inf
            best_idx = 0
            best_dists = []
            best_idxs = []
            best_leaves = []

            #TODO: Add in to bring in top to bottom results
            # for j in range(4): #Changed to 4

            #     best_dists.append(nn_row_storage[row_idx_counter][j])
                #print(nn_row_storage[row_idx_counter][j])
            

            #Determine the best 5 among all the nodes
            for nodeB in preorderNodes:

                dist, idx = compute_distance(nodeB.data, patchA2)


                for q in best_dists:
                        if int(q[0]) == int(dist): #No duplicates
                            continue
        
            

                # We are looking for the 4 best candidates
                if len(best_dists) < 4: #Update 4

                
                    best_dists.append([dist, idx, nodeB])
                    #best_dists = sorted(best_dists)
                    best_dists.sort(key=lambda x: x[0])

                    if dist < best_dist:
                        best_dist = dist
                        best_idx = idx

                else:

                    found = False
                    #best_dists = sorted(best_dists)
                    best_dists.sort(key=lambda x: x[0])
                    for comp in best_dists:

                        # If calcuated distance is better than one of the current candidates

                        if dist < best_dist:
                            best_dist = dist
                            best_idx = idx
                            #best_leaf = nodeB
                
                        if dist < comp[0] and found == False:
                        
                            best_dists.pop()
                            best_dists.append([dist, idx, nodeB])
                            best_dists.sort(key=lambda x: x[0])
                            #best_dists = sorted(best_dists)
                            found = True
                            
        
            row_idx_counter = row_idx_counter + 1

            # These resutls are stored in rows to be later used as an intial guess for process rows
            #best_dists = sorted(best_dists)
            best_dists.sort(key=lambda x: x[0])
            row_storage.append(best_dists)


        
            # These are the guesses that will actually count toward the score
            nn_full_indices.append(best_idx)


            best_index_str = str(best_idx) + "\n"
            f_exact_row.write(best_index_str)


            nn_full_distances.append(best_dist)
        
        f_exact_row.close()



        # # # Process Rows on remaning rows (Main Algo)
    
        f_process_row_str = destination_folder + "/processRowBestIndex.txt"
        f_process_row = open(f_process_row_str, "w")
        f_propgationLeafIndex_str = destination_folder + "/propagationLeafIndex.txt"
        f_propgationLeafIndex = open(f_propgationLeafIndex_str, "w")
        for patchA3 in patches_a_reduced[row_size:]:



            if row_idx_counter >= max_patches:
                break


            # Look at candidates in the row above
            candidates = row_storage[(row_idx_counter%row_size)]    #these are leaves we use to find the propagation leaves


            #Write leaf indices
            leaf_index_str = str(candidates[0][2].data.leaf_count) + "\n"
            f_propgationLeafIndex.write(leaf_index_str)
            leaf_index_str = str(candidates[1][2].data.leaf_count) + "\n"
            f_propgationLeafIndex.write(leaf_index_str)
            leaf_index_str = str(candidates[2][2].data.leaf_count) + "\n"
            f_propgationLeafIndex.write(leaf_index_str)
            leaf_index_str = str(candidates[3][2].data.leaf_count) + "\n"
            f_propgationLeafIndex.write(leaf_index_str)
        
        


            # Better Propagation (Doesn't actually help)
            better = []
            # for prop in range(1):

            #     prop_index = int(candidates[prop][1] + row_size)


            #     if prop_index >= 494:
            #         continue

            #     for tt in range(4):
        
            #        add = True
            #        for q in candidates:
            #            if int(q[0]) == int(nn_row_storage[prop_index][tt][0]):
            #                add = False
                            
            #        if add:
            #         better.append(nn_row_storage[prop_index][tt])

            

            # Add candidates from top to bottom traversal  on current row/index
            # TODO: Add back in
            for t in range(4):  #Change to 4
            
                # for qq in candidates:
                #     if int(qq[0]) == int(nn_row_storage[row_idx_counter][t][0]):
                #         add = False

                vals = []
                for d_test in candidates:
                    vals.append(d_test[1])
                            
                #print(nn_row_storage[row_idx_counter][t][1] )
                if nn_row_storage[row_idx_counter][t][1] not in vals:
                
                    #print(vals)
                    candidates.append(nn_row_storage[row_idx_counter][t])

                
                

            # Find the best 5 of these reuslts   

            #Best 5 is a misnomer, it is actually best 4 now (My fault for the poor variable name ~Chris)
            dist, best_node, best_five = compute_all_distances_find_best_new(candidates, patchA3, _pca_model)


            #print("best 4")
        
        
            best_indexes = []
            for ix in best_five:
                
                best_indexes.append(ix[1])
                
        


            dist, idx = compute_distance(best_node.data, patchA3)

        
        
            best_dist = dist
            best_idx = idx
            best_index_str = str(best_idx) + "\n"
            f_process_row.write(best_index_str)
            nn_full_indices.append(best_idx)
            nn_full_distances.append(best_dist)

            # Put best 5 as initial guess for the next time
            row_storage[(row_idx_counter%row_size)] = best_five
            
            row_idx_counter = row_idx_counter + 1
        



        # end time
        end = time.time()

        # total time taken
        print(f"Runtime of the program is {end - start}")


        f_propgationLeafIndex.close()
        f_process_row.close()


        #Write Expected Indices
        f_expected_idx_str = destination_folder + "/expectedIndex.txt"
        f_expected_idx = open(f_expected_idx_str, "a")

        for best_idx in nn_full_indices:
            idx_str = str(best_idx) + "\n"
        
            f_expected_idx.write(idx_str)

        f_expected_idx.close()
        
        
        #Write Expected Distance
        f_expected_dst_str = destination_folder + "/expectedDistance.txt"
        f_expected_dst = open(f_expected_dst_str, "a")

        for best_dst in nn_full_distances:

            #The RTL model does not take sqrt
            #That is the RTL provides the SQUARED L2 score
            #Thus to match, we square our results
            temp_dst = (int(best_dst))**2
     
            if temp_dst > MAX_DIST:
                temp_dst = MAX_DIST
                
            dst_str = str(temp_dst) + "\n"
        
            f_expected_dst.write(dst_str)

        f_expected_dst.close()



        # # Compute final score
        patches_a_reconst = patches_b[nn_full_indices]
        diff = patches_a.astype(numpy.float32) - patches_a_reconst.astype(numpy.float32)
        l2 = numpy.mean(numpy.linalg.norm(diff, axis=1))
        print("Overall Full Traversal + Process Rows L2 score: {}".format(l2))
        
        
        #write gold l2 to .txt file the l2.py can read
        f_l2_str = destination_folder + "/gold_l2_score.txt"
        f_l2 = open(f_l2_str, "a")
        f_l2.write(str(l2) + "\n")
        f_l2.close()
        



        # #Actuall hardware values
        # file1 = open('receiveIndex.txt', 'r')
        # Lines = file1.readlines()
        
        # # Strips the newline character
        # hw_indices = []
        # for line in Lines:
        #     #print(int(line))
        #     hw_indices.append(int(line))


        # # # Compute final HW score 
        # patches_a_reconst = patches_b[hw_indices]
        # diff = patches_a.astype(numpy.float32) - patches_a_reconst.astype(numpy.float32)
        # l2 = numpy.mean(numpy.linalg.norm(diff, axis=1))
        # print("Overall Hardware L2 score: {}".format(l2))

        





        # Reconstruct Image (For Visual Debugging. The L2 score should effectively describe this same result )
        # Note since patches_a_reconst was made by index, inverse PCA is NOT required 

        recontruct_shape = (1, im_width, im_height, 3)

        patches_a_reconst_format = [patches_a_reconst]

        patches_a_reconst_format = tf.cast(patches_a_reconst_format, tf.float32)
        images_reconstructed = extract_patches_inverse(recontruct_shape, patches_a_reconst_format)
        #error = tf.reduce_mean(tf.math.squared_difference(images_reconstructed, images))
        #print(error)

        #Write the reconstructed image
        print("Writing reconstructed image to")
        print(reconstruct_file_name)
        cv2.imwrite(reconstruct_file_name, numpy.array(images_reconstructed[0]))







#Unused
def template_match():

    src_pts_temp = []
    dst_pts_temp = []
    patch_a_idx = 0

    print(len(nn_full_distances))
    print(len(nn_full_indices))


    a_y = 0

    for q in nn_full_distances:

        a_x = patch_a_idx % 28 +2
        a_y = math.floor(patch_a_idx/28) +2
        print(q)

        print([a_x,a_y])

        if q < 100:  


            raw_best = nn_full_indices[patch_a_idx]

            b_x = raw_best % 28 + 2
            b_y = math.floor(raw_best/28) + 2

        
            src_pts_temp.append([a_x, a_y]) #TODO: convert patch index picture index
            dst_pts_temp.append([b_x, b_y]) #Use NNF


        patch_a_idx = patch_a_idx + 1


    src_pts = numpy.float32([src_pts_temp]).reshape(-1,1,2)
    dst_pts = numpy.float32([dst_pts_temp ]).reshape(-1,1,2)

    print(src_pts.shape)
    print(dst_pts.shape)
    print("Error after thsi")
    M, mask = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC,5.0)
    matchesMask = mask.ravel().tolist()


    print(image_test.shape)
    print(patches_a.shape)
    h,w,_ = image_test.shape
    print(h)
    print(w)
    print(M.shape)
    pts = numpy.float32([ [0,0],[0,h-1],[w-1,h-1],[w-1,0] ]).reshape(-1,1,2)
    dst = cv2.perspectiveTransform(pts,M)

    img2 = cv2.polylines(img2,[numpy.int32(dst)],True,(255,255,0),1, cv2.LINE_AA)
    cv2.imwrite(reconstruct_file_name_2,img2)

    # patches_a_reconst_format = [dst]

    # patches_a_reconst_format = tf.cast(patches_a_reconst_format, tf.float32)
    # images_reconstructed = extract_patches_inverse(recontruct_shape, patches_a_reconst_format)
    # cv2.imwrite(reconstruct_file_name, numpy.array(images_reconstructed[0]))


    
    # img2 = cv2.polylines(reconstruct_file_name,[numpy.int32(dst)],True,255,3, cv2.LINE_AA)




  


  
