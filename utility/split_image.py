import os
from sklearn.feature_extraction import image
import cv2
import sys

################################################################
#                   split_image.py                             #
################################################################
# Splits images into sets of 32x(?) to read into   # 
#                                                              #
# Author: Chris Calloway, cmc2734@stanford.edu                 #
# Maintainers: Chris Calloway, cmc2734@stanford.edu            #
#           Jake Ke, jakeke@stanford.edu                       #
################################################################


if __name__ == "__main__":

    if len(sys.argv) < 4:

        print("[ERROR] must supply [image A] [image B] [destination_folder] " )
        print("Example: python3 split_image.py avatar1 avatar2 ./ ")
        exit()


    destination_folder = sys.argv[3] #It would be best if but things in their proper folder. However, I don't know how to pass filenames with vcs ~Chris

    file_name_a = sys.argv[1] #Image A
    file_name_b = sys.argv[2] #Image B

    image_a_str = "/Volumes/Seagate Por/VidPairs_DataSet/" + file_name_a + ".jpg"
    image_b_str = "/Volumes/Seagate Por/VidPairs_DataSet/" + file_name_b + ".jpg"

    im =  cv2.imread(image_a_str)
    imb =  cv2.imread(image_b_str)
    #im = cv2.resize(im,(1000,500))

    imgheight=im.shape[0]
    imgwidth=im.shape[1]
   

    y1 = 0
    M = imgheight//60
    N = imgwidth//60

    print("Image height and M")
    print(imgheight)
    print(M)
    print("Image Width and N")
    print(imgwidth)
    print(N)



    for y in range(0,imgheight,M):

        for x in range(0, imgwidth, N):

            y1 = y + M
            x1 = x + N
            tiles = im[y:y+M,x:x+N]
            tilesb = imb[y:y+M,x:x+N]

            #cv2.rectangle(im, (x, y), (x1, y1), (0, 255, 0))
            cv2.imwrite("save/" + str(x) + '_' + str(y)+"_a.png",tiles)
            cv2.imwrite("save/" + str(x) + '_' + str(y)+"_b.png",tilesb)

    print("Do we make it to the end?")
