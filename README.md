# Stereo 

Stereo matching is an important topic in Computer Vision, with wide applications in robotics, autonomous vehicles, object recognition and 3D mapping. When using two calibrated stereo cameras, the objects in the field of view will appear at different locations because of camera
perspective. Measuring the distance by which objects appear differently on each horizontal scan line  allow us to use basic triangulation to infer depth.

Block matching was achieved by creating and comparing the shifted **Disparity Space Image** of the left and right images. This algorithm runs in **O(n log n)**, and was tested against the [Middlebury 2003 Dataset](http://vision.middlebury.edu/stereo/data/scenes2003/).

![Right image](https://i.imgur.com/akZK918.png)
![Left image](https://i.imgur.com/W8MlfMO.png)

## Algorithm

The final stereo algorithm created uses gradient-based features, a block size of 3, a disparity range of 64 and an occlusion filling algorithm. Gradient-based features have been used as they demonstrated similar results to regular pixel intensity matching, however are invariant against illumination and thus more flexible with other images. A disparity range of 64 was chosen as covers the disparity of any object in the Middlebury data-set [1], and any lower disparity was found to introduce noise in
foreground objects. Experimentation before showed a smaller block size introduced noise, however a size of 3 was chosen due to the ability to remove this noise with occlusion filling, allowing for more detailed boundary disparity of objects. The base algorithm runs in O(n log n), calculating a disparity map on an i3 computer in 2 seconds. This would be advantageous for use in video sequences where the disparity can be calculated efficiently in real time. The occlusion filling algorithm runs in O(n 2 ), however this was due to time constraints and with more time algorithm efficiency could be improved. The results evaluated against the ground truth are shown below.

## Results

|Error Function| Final Algorithm | Pixel Intensities | +Occlusion Filling | Edges
|--|--|--|--|--|
|IMSE|504|1008|648|681|
|SSI|0.74|0.45|0.56|681|
|IMSE|21.09|18.09|20|19.75|

