import MySQLdb
import datetime
import pytz
from pytz import timezone
import sys

apiKey = "tx6bOffUXfvFUdHyWr1Ov9XxQYpjKuzPuMqNhbgjus8S36xPCC93YrAsk57DjRLs"
apiSecret = "fBjFKj5Yw1pnLXwVkD7XQQX6IAsvbhqkSL0CxB9WHC2MKfCcBh1UaB7jztkJ1uT1"


# DB Connection Settings

dbUserName = 'root'
dbPassword = '!n#v#rW@NT2g3T|-|@(|<3|)'

dataIp = 'localhost'
dataDb = 'cryptoDataStore'

strategyIp = 'localhost'
strategyDb = '	'

# Time zone settings
tradingTimezone = pytz.utc.zone
serverTimezone = 'Asia/Kolkata'

# Fetch the expiry date, symbol to be traded and symbol specifications
currentDate = datetime.datetime.now(timezone(tradingTimezone)).strftime('%Y-%m-%d')


