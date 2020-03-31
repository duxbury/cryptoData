from time import sleep
from pytz import timezone
from datetime import *
import datetime
import time
import sys
import requests.packages.urllib3
import json 
import requests
from urlparse import urljoin
from urllib import urlencode
requests.packages.urllib3.disable_warnings()
import sys
import hmac
import hashlib
import config

API_KEY = config.apiKey
SECRET_KEY = config.apiSecret
BASE_URL = 'https://api.binance.com'

headers = {
    'X-MBX-APIKEY': API_KEY
}


class BinanceException(Exception):
    def __init__(self, status_code, data):

        self.status_code = status_code
        if data:
            self.code = data['code']
            self.msg = data['msg']
        else:
            self.code = None
            self.msg = None
        message = "{"+str(status_code)+"} [{"+str(self.code)+"}] {"+str(self.msg)+"}"
	super(BinanceException, self).__init__(message)


def error_message(status_code, data):

        if data:
            code = data['code']
            msg = data['msg']
        else:
            code = None
            msg = None
        message = "{"+str(status_code)+"} [{"+str(code)+"}] {"+str(msg)+"}"
	return message


def test_connectivity():
	PATH =  '/api/v3/ping'
	params = None
	url = urljoin(BASE_URL, PATH)
	r = requests.get(url, params=params)
	return r.json()

def kline(symbol,interval,limit):
	PATH = '/api/v3/klines'
	params = {
	    'symbol': symbol,
	    'interval': interval,
	    'limit':limit}
	query_string = urlencode(params)
	url = urljoin(BASE_URL, PATH)
	r = requests.get(url, params=params)
	if r.status_code == 200:
		data = r.json()
	    	return data
	else:
		message = error_message(r.status_code, r.json())
		print message

def exchangeInfo():
	PATH = '/api/v3/exchangeInfo'
	params = {}
	query_string = urlencode(params)
	url = urljoin(BASE_URL, PATH)
	r = requests.get(url, params=params)
	if r.status_code == 200:
		data = r.json()
	    	return data
	else:
		message = error_message(r.status_code, r.json())
		print message


