from time import sleep
from pytz import timezone
from datetime import *
import MySQLdb
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
import numpy as np
import config
import binanceFuturesAPIImplementation as binanceFutures

def fetchBinanceSymbols():
	exchangeInformation = binanceFutures.exchangeInfo()
	for key in exchangeInformation:
		print key
		if key == 'serverTime':
			print datetime.datetime.fromtimestamp(int(exchangeInformation[key])/1000)			
		if key == 'symbols':
			for symbols in exchangeInformation[key]:
				print symbols['symbol'],symbols['pricePrecision'],symbols['quantityPrecision']
				query = "insert into binanceFuturesSymbols values ('"+str(symbols['symbol'])+"','"+str(symbols['baseAsset'])+"','"+str(symbols['quoteAsset'])+"',"+str(symbols['pricePrecision'])+","+str(symbols['quantityPrecision'])+")"
				print query	
				
				dataDbConnection = MySQLdb.connect(config.dataIp,config.dbUserName,config.dbPassword,config.dataDb)			
				dataCursor = dataDbConnection.cursor()
				dataCursor.execute(query)
				dataDbConnection.commit()
				dataCursor.close()
				dataDbConnection.close()

def getFuturesSymbolList():
	dataDbConnection = MySQLdb.connect(config.dataIp,config.dbUserName,config.dbPassword,config.dataDb)			
	dataCursor = dataDbConnection.cursor()
	
	query = "select symbol from binanceFuturesSymbols order by symbol asc"
	dataCursor.execute(query)
	symbolList = []
	for symbol in dataCursor:
		symbolList.append(str(symbol[0]))
	dataCursor.close()
	dataDbConnection.close()
	return symbolList


def insertIntoDataDb(query):

	dataDbConnection = MySQLdb.connect(config.dataIp,config.dbUserName,config.dbPassword,config.dataDb)			
	dataCursor = dataDbConnection.cursor()
	dataCursor.execute(query)
	dataDbConnection.commit()
	dataCursor.close()
	dataDbConnection.close()


def storeMinuteLevelCandles():
	symbolList = getFuturesSymbolList()
	for symbol in symbolList:
		data = binanceFutures.kline(symbol,'1m',2)
		data = data[0]

		openTime = datetime.datetime.fromtimestamp(int(data[0])/1000)
		closeTime = datetime.datetime.fromtimestamp(int(data[6])/1000)
		open = data[1]
		high = data[2]
		low = data[3]
		close = data[4]
		volume = data[5]

		# convert time from server time to utc time	
	
		openTime = timezone(config.serverTimezone).localize(openTime)
		closeTime = timezone(config.serverTimezone).localize(closeTime)
	    	convertedOpenTime = openTime.astimezone(timezone(config.tradingTimezone))
		convertedCloseTime = closeTime.astimezone(timezone(config.tradingTimezone))
		openDateStamp  = convertedOpenTime.strftime('%Y-%m-%d')
		openTimeStamp  = convertedOpenTime.strftime('%H:%M:%S')
		closeDateStamp = convertedCloseTime.strftime('%Y-%m-%d')
		closeTimeStamp = convertedCloseTime.strftime('%H:%M:%S')


		query = "insert into binanceFutures1MinuteCandles values ('"+symbol+"','"+openDateStamp+"','"+openTimeStamp+"',"+open+","+high+","+low+","+close+","+volume+")"
		print query
		insertIntoDataDb(query)

if __name__ == "__main__" :


	storeMinuteLevelCandles()
