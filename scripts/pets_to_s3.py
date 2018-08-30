import boto3
import os
from random import shuffle

s3 = boto3.resource("s3")
mybucket = s3.Bucket("test-bucket-ly")

def get_breed(filename):
	split_name = os.path.splitext(filename)[0].split('_')
	del split_name[-1]
	breed = "_".join(split_name)
	return breed

class_list = []
file_list = []
for (root, dirnames, filenames) in os.walk("/path/to/images"):
	for file in filenames:
		if os.path.splitext(file)[1] == ".jpg":
			file_list.append(os.path.join(root, file))
			breed = get_breed(file)
			if breed not in class_list:
				class_list.append(breed)
shuffle(file_list)

num_train = int(0.9*len(file_list))
train_list = file_list[:num_train]
test_list = file_list[num_train:]

for class_ in class_list:
	for file in train_list:
		if get_breed(os.path.basename(file)) == class_:
			print "train: " + class_
			mybucket.upload_file(file, 'pets/train/'+class_+'/'+os.path.basename(file))

for class_ in class_list:
	for file in test_list:
		if get_breed(os.path.basename(file)) == class_:
			print "val: " + class_
			mybucket.upload_file(file, 'pets/val/'+class_+'/'+os.path.basename(file))
