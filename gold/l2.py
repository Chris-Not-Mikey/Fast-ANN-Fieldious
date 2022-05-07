#####################################################################
#           l2.py                                                   #
#           For computining the l2 score of the HW results          #
#           Also does reconstruction to create visual output        #
#                                                                   #
#           Author: Chris Calloway                                  #
#           email: cmc2374@stanford.edu                             #
#                                                                   #
#####################################################################

import numpy
import cv2
from sklearn.feature_extraction import image
from sklearn.decomposition import PCA
import tensorflow as tf
import sys



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



def _create_patches(img, psize):

    n_channels = img.shape[-1]

    patches = image.extract_patches_2d(img, (psize, psize))

    if True > 0:
        print("Patches for image have shape: {}".format(patches.shape))

    patches = patches.reshape((-1, psize * psize * n_channels))

    if True > 0:
        print("Reshaped patches for image have shape: {}".format(patches.shape))

    return patches





if __name__ == "__main__":
    
    
    if len(sys.argv) < 3:

        print("[ERROR] must supply [image A] [image B]" )
        print("Example: python3 l2.py walking1 walking12")
        exit()
    
    numpy.random.seed(0)
    psize = 5 # Patch size of 5x5 (much better results than 8x8 for minimal memory penalty)
    
    
    file_name_a = sys.argv[1] #Image A
    file_name_b = sys.argv[2] #Image B

    print(file_name_a)
    print(file_name_b)
        

    image_a_str = "./data/gold_data/" + file_name_a + ".png"
    image_a = cv2.imread(image_a_str)

    image_b_str = "./data/gold_data/" + file_name_b + ".png"
    image_b = cv2.imread(image_b_str)
  
      
#     image_a = cv2.imread("./data/gold_data/frame1ball_30.png")
#     image_b = cv2.imread("./data/gold_data/frame2ball_30.png")
    results_file = open('./data/IO_data/received_idx.txt', 'r')
    reconstruct_file_name = "./data/gold_results/l2_" +  file_name_a + "_reconstruct.png"


    im_height = image_a.shape[1]
    im_width = image_a.shape[0]

    #row_size = 56 #Row Size = (h-p+1)


    row_size = image_a.shape[1] - psize + 1
    col_size = image_a.shape[0] - psize + 1

    # create patches

    patches_a = _create_patches(image_a, psize)
    patches_b = _create_patches(image_b, psize)



    # Actual hardware values
    Lines = results_file.readlines()
    
    hw_indices = []
    for line in Lines:
        #print(int(line))
        hw_indices.append(int(line))


    # Compute final HW score 
    patches_a_reconst = patches_b[hw_indices]
    diff = patches_a.astype(numpy.float32) - patches_a_reconst.astype(numpy.float32)
    l2 = numpy.mean(numpy.linalg.norm(diff, axis=1))
    print("Overall Hardware L2 score: {}".format(l2))
    
    #Compare to gold model, and fail test if disparity is too big
    
    gold_l2 = open('./data/IO_data/gold_l2_score.txt', 'r')
    lines = gold_l2.readlines()
    
    gold_l2 = float(lines[0])
    
    if abs(l2 - gold_l2) > 1:
        print("failed")
    else:
        print("Sucess")





    # Reconstruct Image  from HW(For Visual Debugging. The L2 score should effectively describe this same result )
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
    
    
  
