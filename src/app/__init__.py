import os, errno
import redis
from flask import Flask

import logging
from logging.handlers import RotatingFileHandler
import traceback
from time import strftime

app = Flask(__name__)

pool = redis.ConnectionPool(host='redis', port=6379, db=0)
db = redis.Redis(connection_pool=pool)

app.config.from_object('config')

log_path = os.path.join("./logs")
try:
    os.makedirs(log_path)
except OSError as e:
    if e.errno != errno.EEXIST:
        raise

handler = RotatingFileHandler(os.path.join(log_path, 'cloudup.log'), maxBytes=10000, backupCount=1)
logger = app.logger
logger.setLevel(logging.INFO)
logger.addHandler(handler)

@app.after_request
def after_request(response):
    """ Logging after every request. """
    # This avoids the duplication of registry in the log,
    # since that 500 is already logged via @app.errorhandler.
    if response.status_code != 500:
        ts = strftime('[%Y-%b-%d %H:%M]')
        logger.info('%s %s %s %s %s %s',
                      ts,
                      request.remote_addr,
                      request.method,
                      request.scheme,
                      request.full_path,
                      response.status)
    return response


@app.errorhandler(Exception)
def exceptions(e):
    """ Logging after every Exception. """
    ts = strftime('[%Y-%b-%d %H:%M]')
    tb = traceback.format_exc()
    logger.error('%s %s %s %s %s 5xx INTERNAL SERVER ERROR\n%s',
                  ts,
                  request.remote_addr,
                  request.method,
                  request.scheme,
                  request.full_path,
                  tb)
    return "Internal Server Error", 500

from apis import *
