import os
import redis
from envparse import env

# settings_for_MNIST
MNIST_IMAGE_QUEUE = env.str('MNIST_IMAGE_QUEUE', default='mnist_image_queue')
CLIENT_SLEEP = env.str('CLIENT_SLEEP', default=0.5)

# settings for InceptionV3
INCEPTIONV3_TOPLESS_MODEL_PATH = env.str('INCEPTIONV3_TOPLESS_MODEL_PATH', default=os.path.join("app", "models", "InceptionV3", "topless",'topless.h5'))
INCEPTIONV3_IMAGE_QUEUE = env.str('INCEPTIONV3_IMAGE_QUEUE', default='inceptionV3_image_queue')
INV3_TRANSFER_NB_EPOCH = env.str('INV3_TRANSFER_NB_EPOCH', default=3)
INV3_TRANSFER_BATCH_SIZE = env.str('INV3_TRANSFER_BATCH_SIZE', default=2)

# setting for mysql db
# parsed from environment variables
MYSQL_HOST = env.str('DB_HOST', default='db.cloud-up-insight.com')
MYSQL_USER = env.str('DB_USER', default='root')
MYSQL_PASSWORD = env.str('DB_PASSWORD', default='cloudupusers')
MYSQL_DB = env.str('DB_NAME', default='cloudupdb')
MYSQL_CURSORCLASS = 'DictCursor'

# redis url for celery
BROKER_URL = env.str('BROKER_URL', default='redis://redis:6379/0')
BACKEND_URL = env.str('BACKEND_URL', default='redis://redis:6379/0')