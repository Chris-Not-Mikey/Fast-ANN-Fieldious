from cmath import inf
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


################################################################
#                   GOLD.PY
################################################################
# A behavior model for Fast ANN Fieldious Hardware accelerator
#
# Author: Chris Calloway, cmc2734@stanford.edu
# Mainters: Chris Calloway, cmc2734@stanford.edu
#           Jake Ke, jakeke@stanford.edu
################################################################



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



def compute_distance(data, point):
    dist = 0

    data_list = []

    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    #dist2 = numpy.linalg.norm(point1 - point2)
    dist = numpy.linalg.norm(data.best_dim - point2)

    return dist

def compute_distance_non_median(data, point):
    dist = 0

    data_list = []

    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    #dist2 = numpy.linalg.norm(point1 - point2)
    dist = 0
    for i in data.data:
        dist =  dist + numpy.linalg.norm(i - point2)

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
        for i in data.data:
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


def compute_all_distances_find_best_new(candidate, point):
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


def writeLeaf(tree, f):


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
  
    f.write("#Median\n")
    median_str = str(tree.data.median_max_spread) + "\n"
    f.write(median_str)

    f.write("#Index\n")
    median_str = str(5*tree.data.count) + "\n"
    f.write(median_str)


    f.write("#Dimension_Index\n")
    dim_idx_str = str(tree.data.best_dim_idx) + "\n"
    f.write(dim_idx_str)

    f.write(end_str)
    f.write("#End_Node\n")

 

def preorderFile(tree):
    """ iterator for nodes: root, left, right """

    result = []
    f = open("myfileRaw.txt", "w")

    if not tree:
        return

    #yield tree
    #result.append([tree.data.data, tree.data.median_max_spread, tree.data.best_dim_idx])
    writeLeaf(tree, f)



    if tree.left:
        for x in tree.left.preorder():
            #yield x
            #result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])
            writeLeaf(x, f)

    if tree.right:
        for x in tree.right.preorder():
            #yield x
            #result.append([x.data.data, x.data.median_max_spread, x.data.best_dim_idx])
            writeLeaf(x, f)

    return result


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

    patches_reduced = _pca_model.transform(patches).astype(numpy.float32)

    if True > 0:
        print("Patches reduced for image: {}".format(patches_reduced.shape))

    return patches_reduced


def _apply_inverse_pca(patches_reduced, _pca_model):

    patches = _pca_model.inverse_transform(patches_reduced)

    #patches_reduced = _pca_model.transform(patches).astype(numpy.float32)

    if True > 0:
        print("Patches for un-reduced image: {}".format(patches.shape))

    return patches




if __name__ == "__main__":
    numpy.random.seed(0)
    psize = 5 # Patch size of 5x5 (much better results than 8x8 for minimal memory penalty)
    dim_reduced = 5
        
    image_a = cv2.imread("flow1smallest.png")
    image_b = cv2.imread("flow6smallest.png")

    reconstruct_file_name = "flow1smallest_recontruct.png"


    #Image Dimensions
    im_height = image_a.shape[1]
    im_width = image_a.shape[0]
    print(im_height)

    #row_size = 56 #Row Size = (h-p+1)


    row_size = image_a.shape[1] - psize + 1
 
    col_size = image_a.shape[0] - psize + 1

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

    print(patches_b_reduced.shape)

    max_patches = patches_b_reduced.shape[0]

    inf_list = [float("inf"),float("inf"),float("inf"),float("inf"),float("inf")]
    inf_array = numpy.array([inf_list])
    print(inf_array.shape)


    while (patches_b_reduced.shape[0]%5 != 0):

        patches_b_reduced = numpy.append(patches_b_reduced, inf_array, axis=0 )

    #Split into groups of 5 to create the KD Tree
    split_num = patches_b_reduced.shape[0]/psize
    split = numpy.split(patches_b_reduced, split_num)

    print(numpy.array(split).shape)
   

    #Create an Item Class for each node
    item_list = []
    for nodek in range(int(split_num)):

        item_list.append(Item(split[nodek], nodek))


    # Again, from a list of points
    tree = kdtree.create(item_list, dimensions=5)

    #  The root node
    #print(tree)
    # ...contains "data" field with an Item, which contains the payload in "data" field

    # Create File For Verification
    preorderFile(tree)


    # All functions work as intended, a payload is never lost
    result = tree.search_knn([ 193.19313049,   -1.66310644, -201.89816284,  -29.54750443,   42.18569565], k=1, dist=compute_distance_non_median)
    # result[0] #Result Node + Distance
    # result[0][0] # Node
    # result[0][1] #Distance
    # result[0][0].data.count #Index/5 
    # result[0][0].data.best_dim_idx #Best Dimension
    index = psize*(result[0][0].data.count) + result[0][0].data.best_dim_idx
    distance = result[0][1]



    nn_indices = []
    nn_distances = []
    nn_nodes = []
    nn_best_dists = []
    nn_row_storage = []

    # Top to Bottom Traversal
    # TODO: Make query from scratch
    for patchA in patches_a_reduced:

        nn_best_dists = []

        result = search_knn_custom(patchA, 5, tree, dist=compute_distance) #TODO: use custom search knn instead
        index = psize*(result[0][0].data.count) + result[0][0].data.best_dim_idx
        distance = result[0][1]

        nn_indices.append(index)
        nn_distances.append(distance)
        nn_nodes.append(result[0][0])


        # Add to a list that will later be used in process rows as an intial guess
        for j in range(5):
            
            nn_best_dists.append([result[j][1], result[j][0].data.count, result[j][0]])
          

        

        nn_best_dists = sorted(nn_best_dists)
        nn_row_storage.append(nn_best_dists)


    patches_a_reconst = patches_b[nn_indices]
    diff = patches_a.astype(numpy.float32) - patches_a_reconst.astype(numpy.float32)
    l2 = numpy.mean(numpy.linalg.norm(diff, axis=1))
    print("Overall Top to Bottom L2 score: {}".format(l2))
        


    # If a new leaf was found in step 1, then a brute-force search is performed on that leaf to improve the k candidates. 


    # # Full (Pre-Order) Traversal of first Row
    preorderNodes = list(preorder(tree))
    row_idx_counter = 0

    nn_full_indices = []
    nn_full_distances = []
    row_storage = []


    for patchA2 in patches_a_reduced:

        # Only do full traversal on first row (of patch dimensions)
        if row_idx_counter >= row_size:
            break
        
        best_dist = inf
        best_idx = 0
        best_dists = []
        best_idxs = []
        best_leaves = []

        for j in range(psize):
            best_dists.append(nn_row_storage[row_idx_counter][j])
            #print(nn_row_storage[row_idx_counter][j])
        

        #Determine the best 5 among all the nodes
        for nodeB in preorderNodes:

            dist = compute_distance(nodeB.data, patchA2)

            # We are looking for the 5 best candidates
            if len(best_dists) < psize:
                best_dists.append([dist, nodeB.data.count, nodeB])
                best_dists = sorted(best_dists)

            else:

                found = False
                best_dists = sorted(best_dists)
                for comp in best_dists:

                    # If calcuated distance is better than one of the current candidates

                    if dist < best_dist:
                        best_dist = dist
                        best_idx = 5*(nodeB.data.count) + nodeB.data.best_dim_idx
                        #best_leaf = nodeB
              
                    if dist < comp[0] and found == False:
                       
                        best_dists.pop()
                        best_dists.append([dist, nodeB.data.count, nodeB])
                        best_dists = sorted(best_dists)
                        found = True
                        
       
        row_idx_counter = row_idx_counter + 1

        # These resutls are stored in rows to be later used as an intial guess for process rows
        best_dists = sorted(best_dists)
        row_storage.append(best_dists)

      
        # These are the guesses that will actually count toward the score
        nn_full_indices.append(best_idx)
        nn_full_distances.append(best_dist)
     


    # # Process Rows on remaning rows (Main Algo)
   
    for patchA3 in patches_a_reduced:

        if row_idx_counter >= max_patches:
            break


        # Look at candidates in the row above
        candidates = row_storage[(row_idx_counter%row_size)]

        # Add candidates from top to bottom traversal  on current row/index
        for t in range(psize):
            candidates.append(nn_row_storage[row_idx_counter][t])
         
 
        # Find the best 5 of these reuslts   
        dist, best_node, best_five = compute_all_distances_find_best_new(candidates, patchA3)


        #TODO: REMOVE
        # new_cands = []
        # for j in range(5):
        #     new_cands.append(nn_row_storage[row_idx_counter][j])
            
    
        best_dist = dist
        best_idx = psize*(best_node.data.count) + best_node.data.best_dim_idx
        nn_full_indices.append(best_idx)
        nn_full_distances.append(best_dist)

        # Put best 5 as intial guess for the next time
        row_storage[(row_idx_counter%row_size)] = best_five
        
        row_idx_counter = row_idx_counter + 1
       


        
    # Compute final score
    patches_a_reconst = patches_b[nn_full_indices]
    diff = patches_a.astype(numpy.float32) - patches_a_reconst.astype(numpy.float32)
    l2 = numpy.mean(numpy.linalg.norm(diff, axis=1))
    print("Overall Full Traversal + Process Rows L2 score: {}".format(l2))


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

    


  
