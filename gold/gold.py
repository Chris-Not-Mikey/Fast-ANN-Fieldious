from cmath import inf
import kdtree
import statistics
from matplotlib.pyplot import axes
import numpy
import collections
from sklearn.feature_extraction import image
from sklearn.decomposition import PCA
import cv2


def max_spread_median(axis):


    return 

def compute_distance(data, point):
    dist = 0

    data_list = []

    # print("Split dimension")
    #print(data.best_dim_idx)
    #print(data.best_dim)

    # for i in data:
    #     data_list.append(i)

    point1 = numpy.array(data_list)
    point2 = numpy.array(point)

    #dist2 = numpy.linalg.norm(point1 - point2)
    dist = numpy.linalg.norm(data.best_dim - point2)
    # print("here")
    # print(dist)
    # print(dist2)

    return dist


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
    #f.write(start_str)
    counter =0
    for patch in tree.data.data:
        #patch_str = "#Patch: " + str(counter) + "\n"
        #f.write(patch_str)

        counter = counter + 1
        for dim in patch:
            
            dim_str = str(dim) + "\n"
            f.write(dim_str)
  
    #f.write("#Median\n")
    median_str = str(tree.data.median_max_spread) + "\n"
    f.write(median_str)
    #f.write("#Dimension_Index\n")
    dim_idx_str = str(tree.data.best_dim_idx) + "\n"
    f.write(dim_idx_str)

    #f.write(end_str)
    #f.write("#End_Node\n")

 

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

# # Now we can add Items to the tree, which look like tuples to it
# point1 = [0,4,3,1,7]
# point2 =  [3,4,4,1,7]
# point3 =  [2,4,5,1,4]
# point4 =  [4,4,1,1,7]
# point5 =  [8,4,9,1,2]

# patch1 = [point1,point2,point3, point4,point5]
# patch2 = [point2,point2,point1, point5,point4]
# patch3 = [point5,point2,point3, point5,point4]

# first = Item(patch1)
# second = Item(patch2)
# third = Item(patch3)

# # Again, from a list of points
# tree = kdtree.create([first, second, third])

# #  The root node
# print(tree)

# # ...contains "data" field with an Item, which contains the payload in "data" field
# #print(tree.data.data)

# # All functions work as intended, a payload is never lost
# print(tree.search_nn([1, 2,4,5,3]))
# print(kdtree.visualize(tree))

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




if __name__ == "__main__":
    numpy.random.seed(0)
    psize = 5 # Patch size of 5x5 (much better results than 8x8 for minimal memory penalty)
    dim_reduced = 5
        
    image_a = cv2.imread("flow1smallest.png")
    image_b = cv2.imread("flow6smallest.png")



    _n_cols = image_a.shape[1] - psize + 1
    _n_rows = image_a.shape[0] - psize + 1

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

    inf_list = [float("inf"),float("inf"),float("inf"),float("inf"),float("inf")]
    inf_array = numpy.array([inf_list])
    print(inf_array.shape)

    patches_b_reduced = numpy.append(patches_b_reduced, inf_array, axis=0 )
    patches_b_reduced = numpy.append(patches_b_reduced, inf_array, axis=0 )
    patches_b_reduced = numpy.append(patches_b_reduced, inf_array, axis=0 )
    patches_b_reduced = numpy.append(patches_b_reduced, inf_array, axis=0 )
    

    print(patches_b_reduced.shape)

    #460 is 
    split = numpy.split(patches_b_reduced, 460)
    #print(split)
    print(numpy.array(split).shape)
    print(numpy.array(split[0]).shape)
    print(split[0])


    item_list = []
    for patchk in range(460):

        item_list.append(Item(split[patchk], patchk))


    # item_list = []
    # for patcha in range(2296):

    #     item_list.append(Item(split[patcha], patcha))


    # Again, from a list of points
    tree = kdtree.create(item_list, dimensions=5)

    #  The root node
    #print(tree)
    # ...contains "data" field with an Item, which contains the payload in "data" field
    #print(tree.data.median_max_spread)
    #print(list(tree.preorder()))
    #print(list(preorder(tree)))
    #print(preorderMedian(tree))
    preorderFile(tree)



    # All functions work as intended, a payload is never lost
    result = tree.search_knn([ 193.19313049,   -1.66310644, -201.89816284,  -29.54750443,   42.18569565], k=1, dist=compute_distance)
    print(result[0]) #Result Node + Distance
    print(result[0][0])  # Node
    print(result[0][1]) #Distance
    print(result[0][0].data.count) #Index/5 
    print(result[0][0].data.best_dim_idx) #Patch in thr Leaf
    index = 5*(result[0][0].data.count) + result[0][0].data.best_dim_idx
    distance = result[0][1]
    print(patches_b_reduced[index]) 
    #print(kdtree.visualize(tree))


    #Image Dimensions
    im_height = 60
    im_width = 45

    row_size = 56 #int(im_height/dim_reduced)


    nn_indices = []
    nn_distances = []
    nn_nodes = []
    nn_best_dists = []
    nn_row_storage = []

    # Top to Bottom Traversal
    for patchA in patches_a_reduced:

        nn_best_dists = []

        result = tree.search_knn(patchA, k=5, dist=compute_distance)
        index = 5*(result[0][0].data.count) + result[0][0].data.best_dim_idx
        distance = result[0][1]

        nn_indices.append(index)
        nn_distances.append(distance)
        nn_nodes.append(result[0][0])

        for j in range(5):
            
            nn_best_dists.append([result[j][1], result[j][0].data.count, result[j][0]])
          

        

        nn_best_dists = sorted(nn_best_dists)
       
        nn_row_storage.append(nn_best_dists)


    patches_a_reconst = patches_b[nn_indices]
    diff = patches_a.astype(numpy.float32) - patches_a_reconst.astype(numpy.float32)
    l2 = numpy.mean(numpy.linalg.norm(diff, axis=1))
    print("Overall Top to Bottom L2 score: {}".format(l2))
        


    # #2 If a new leaf was found in step 1, then a brute-force search is performed on that leaf to improve the k candidates. The implementation of this step is similar to the one used for PROCESSROWS, which will be explained in detail next.
    # #NOT FUNCTIONAL YET
    # # TODO: The below needs to be fixed so that it can store the best leaves encountered

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

        for j in range(5):
            best_dists.append(nn_row_storage[row_idx_counter][j])
            #print(nn_row_storage[row_idx_counter][j])
        

        #Determine the best 5 among all the nodes
        for nodeB in preorderNodes:

            dist = compute_distance(nodeB.data, patchA2)

            # We are looking for the 5 best candidates
            if len(best_dists) < 5:
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
                        print("here")
                        print(comp[0])
                        best_dists.pop()
                        best_dists.append([dist, nodeB.data.count, nodeB])
                        best_dists = sorted(best_dists)
                        found = True
                        
       
        row_idx_counter = row_idx_counter + 1

        best_dists = sorted(best_dists)
        #print(best_dists)
        row_storage.append(best_dists)

      
        nn_full_indices.append(best_idx)
        print(best_idx)
        nn_full_distances.append(best_dist)
     


    # # Process Rows on remaning rows (Main Algo)
    #row_idx_counter = 0
    # here_count = 0
    print("START ROW INDEX")
    print(row_idx_counter)
    print(len(row_storage))
    for patchA3 in patches_a_reduced:

        if row_idx_counter >= 2296:
            break


        #Look at candidates in the row above
        #print(row_idx_counter%56)
        candidates = row_storage[(row_idx_counter%56)]
        for t in range(5):
            candidates.append(nn_row_storage[row_idx_counter][t])

        # print(nn_row_storage[row_idx_counter])
       
        
    
        dist, best_node, best_five = compute_all_distances_find_best(candidates, patchA3)


        new_cands = []
        # print('best 5')
        # print(best_five)
        # print("gap")
        # print(nn_row_storage[row_idx_counter])
        
        for j in range(5):
            
            new_cands.append(nn_row_storage[row_idx_counter][j])
            new_cands.append(best_five[j])
        
        
        # print(row_idx_counter)
        # print(len(nn_row_storage))
        # print(nn_row_storage[row_idx_counter][0])


        best_dist = dist
        best_idx = 5*(best_node.data.count) + best_node.data.best_dim_idx
        nn_full_indices.append(best_idx)
        #print(best_idx)
        nn_full_distances.append(best_dist)

        row_storage[(row_idx_counter%56)] = new_cands
        
        row_idx_counter = row_idx_counter + 1
       


        


    patches_a_reconst = patches_b[nn_full_indices]
    diff = patches_a.astype(numpy.float32) - patches_a_reconst.astype(numpy.float32)
    l2 = numpy.mean(numpy.linalg.norm(diff, axis=1))
    print("Overall Full Traversal + Process Rows L2 score: {}".format(l2))
        
        
    


    

    


    


  
