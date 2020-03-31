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
import binanceSpotAPIImplementation as binance
from decimal import Decimal

def num_after_point(x):  
    count = 0  
    residue = x -int(x)  
    if residue != 0:  
        multiplier = 1  
        while not (x*multiplier).is_integer():  
            count += 1  
            multiplier = 10 * multiplier  
        return count


def fetchBinanceSpotSymbols():
	exchangeInformation = binance.exchangeInfo()
	for key in exchangeInformation:			
		if key == 'symbols':
			for symbols in exchangeInformation[key]:
				if symbols['quoteAsset'] == 'USDT':				
					pricePrecision = num_after_point(float(symbols['filters'][0]['tickSize']))
					quantityPrecision = num_after_point(float(symbols['filters'][2]['stepSize']))
					if pricePrecision is None:
						pricePrecision = 0
					if quantityPrecision is None:
						quantityPrecision = 0
					coinSymbol = symbols['symbol']
					baseAsset =  symbols['baseAsset']
					quoteAsset = symbols['quoteAsset']
					query = "insert into binanceSpotSymbols values('"+coinSymbol+"','"+baseAsset+"','"+quoteAsset+"',"+str(pricePrecision)+","+str(quantityPrecision)+",'"+str(symbols['status'])+"')"
					insertIntoDataDb(query)				

def getSpotSymbolList():
	dataDbConnection = MySQLdb.connect(config.dataIp,config.dbUserName,config.dbPassword,config.dataDb)			
	dataCursor = dataDbConnection.cursor()
	
	query = "select symbol from binanceSpotSymbols where status = 'TRADING' order by symbol asc"
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
	symbolList = getSpotSymbolList()
	for symbol in symbolList:
		data = binance.kline(symbol,'1m',2)
		data = data[0]
		if data is None:
			continue
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


		query = "insert into binanceSpot1MinuteCandles values ('"+symbol+"','"+openDateStamp+"','"+openTimeStamp+"',"+open+","+high+","+low+","+close+","+volume+")"				     
		insertIntoDataDb(query)

if __name__ == "__main__" :
	#fetchBinanceSpotSymbols()
	storeMinuteLevelCandles()
