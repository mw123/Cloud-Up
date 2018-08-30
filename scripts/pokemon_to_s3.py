import boto3
import os

s3 = boto3.resource("s3")
mybucket = s3.Bucket("test-bucket-ly")

class_list = []
train_list = []
for (root, dirnames, filenames) in os.walk("/path/to/pokemon-tcg-images"):
	for file in filenames:
		train_list.append(os.path.join(root, file))
		if os.path.splitext(file)[0].split('-')[0] not in class_list:
			class_list.append(os.path.splitext(file)[0].split('-')[0])

test_list = []
for (root, dirnames, filenames) in os.walk("/path/to/pokemon-a"):
	for file in filenames:
		if os.path.splitext(file)[0].split('-')[0] in class_list:
			test_list.append(os.path.join(root, file))
for (root, dirnames, filenames) in os.walk("/path/to/pokemon-b"):
	for file in filenames:
		if os.path.splitext(file)[0].split('-')[0] in class_list:
			test_list.append(os.path.join(root, file))


for class_ in class_list:
	for file in train_list:
		if os.path.splitext(os.path.basename(file))[0].split('-')[0] == class_:
			mybucket.upload_file(file, 'models/pokemon/train/'+class_+'/'+os.path.basename(file))

for class_ in class_list:
	for file in test_list:
		if os.path.splitext(os.path.basename(file))[0].split('-')[0] == class_:
			mybucket.upload_file(file, 'models/pokemon/val/'+class_+'/'+os.path.basename(file))
