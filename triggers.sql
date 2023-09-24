-- MySQL dump 10.13  Distrib 8.0.34, for Linux (x86_64)
--
-- Host: database-1.cluster-cxctvfqbuoy4.ap-southeast-1.rds.amazonaws.com    Database: TL
-- ------------------------------------------------------
-- Server version	8.0.28

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgSetPricesForBattleLeague` BEFORE INSERT ON `battleleague` FOR EACH ROW BEGIN

    DECLARE pendtime datetime;
    DECLARE rlimit INT DEFAULT NEW.botcount;
    DECLARE maxseconds INT DEFAULT 0;

    SET maxseconds = TIMESTAMPDIFF(SECOND,NOW(),NEW.starttime);
    SET pendtime = (SELECT NEW.startTime + INTERVAL (SELECT minutes FROM TL_Ref_duration WHERE name = NEW.duration AND
        markets = (SELECT markets FROM symbolinfo WHERE symbol = NEW.symbol1) ) MINUTE);

    SET NEW.markets = (SELECT markets FROM symbolinfo WHERE symbol = NEW.symbol1),
        NEW.symbol1startprice = (SELECT ltp FROM ltpstore WHERE symbol = NEW.symbol1),
        NEW.symbol1endprice = (SELECT ltp FROM ltpstore WHERE symbol = NEW.symbol1),
        NEW.symbol2startprice = (SELECT ltp FROM ltpstore WHERE symbol = NEW.symbol2),
        NEW.symbol2endprice = (SELECT ltp FROM ltpstore WHERE symbol = NEW.symbol2),
        NEW.endtime = pendtime;

    IF NEW.entryfee = 0 AND NEW.prizepool > 0 THEN
      INSERT INTO ACC.gameaccount (leagueid,amount) VALUES (NEW.leagueid,NEW.prizepool);
      INSERT INTO ACC.gamepromotionaccount(leagueid,amount) VALUES (NEW.leagueid,-NEW.prizepool);
    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trigger_battle_league_game_data_change_notification` AFTER UPDATE ON `battleleague` FOR EACH ROW BEGIN

      DECLARE eventobject JSON;
      DECLARE response JSON;
      IF NEW.starttime > NOW() THEN

        SELECT JSON_OBJECT('room','battle','channel','battleMatchupData','data',JSON_OBJECT("symbol1",symbol1,"symbol2",symbol2,
        "prizepool",CONCAT(CAST(IF(prizepool > 1000,CONCAT(TRIM(ROUND(prizepool/1000,1))+0,' K'),TRIM(prizepool)+0) AS CHAR),' Prize Pool'),
        "totalplayers",CONCAT(CAST(IF(totalplayers > 1000,CONCAT(TRIM(ROUND(totalplayers/1000,1))+0,' K'),TRIM(totalplayers)+0) AS CHAR),' Players')))
        INTO eventobject
        FROM
        (SELECT symbol1,symbol2,markets,SUM(prizepool) AS prizepool,
        SUM(totalplayers) AS totalplayers FROM TL.battleleague
        WHERE starttime > NOW()
        AND symbol1 = NEW.symbol1  AND symbol2 = NEW.symbol2) matchup;

        SELECT lambda_async(
            'arn:aws:lambda:ap-south-1:312171270419:function:notify_league_data_change', eventobject) INTO response;


        SELECT JSON_OBJECT('room','battle','channel','battleGameData','data',JSON_OBJECT("leagueid",leagueid,
        "prizepool",CONCAT(CAST(IF(prizepool > 1000,CONCAT(TRIM(ROUND(prizepool/1000,1))+0,' K'),TRIM(prizepool)+0) AS CHAR),' Prize Pool'),
        "totalplayers",CONCAT(CAST(IF(totalplayers > 1000,CONCAT(TRIM(ROUND(totalplayers/1000,1))+0,' K'),TRIM(totalplayers)+0) AS CHAR),' Players'),
        'symbol1players',symbol1players,'symbol2players',symbol2players,'symbol1earnings',symbol1earnings,'symbol2earnings',symbol2earnings))
        INTO eventobject
        FROM
        (SELECT leagueid,SUM(prizepool) AS prizepool,symbol1players,symbol2players,symbol1earnings,symbol2earnings,
        SUM(totalplayers) AS totalplayers FROM TL.battleleague
        WHERE starttime > NOW() AND leagueid = NEW.leagueid) matchup;

        SELECT lambda_async(
            'arn:aws:lambda:ap-south-1:312171270419:function:notify_league_data_change', eventobject) INTO response;       

      END IF;   
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgcreatebattleleaguebotentrytime` BEFORE INSERT ON `battleleaguebots` FOR EACH ROW BEGIN

    SET NEW.jointime = DATE_ADD(NEW.startTime,INTERVAL NEW.sectoadd SECOND);

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `classic_league_winners_insert_trigger` AFTER INSERT ON `classic_league_winners` FOR EACH ROW BEGIN
    INSERT INTO ATR.transactiontable
    (uid, leagueid, leaguetype, amount, entrytype, transactiontype, transactiontypeid)
    VALUES
    (NEW.uid, NEW.leagueid, 4, NEW.amount, 'CREDIT', 'WINNING', 9);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgUpdateClassicLeagueParamsOnCreation` BEFORE INSERT ON `classicleague` FOR EACH ROW tlabel : BEGIN

    DECLARE pprizepool DECIMAL(10,2);
    DECLARE pwinningamount DECIMAL(10,2);
    DECLARE pendtime DATETIME;

    SET pendtime = (SELECT NEW.startTime + INTERVAL (SELECT minutes FROM TL_Ref_duration WHERE name = NEW.duration AND        markets = (SELECT markets FROM symbolinfo WHERE symbol = NEW.symbol limit 1) ) MINUTE);
    IF NEW.ondemand = 1 THEN
        SET NEW.guaranteed = 0;
    END IF;

    SELECT sum(winnings*usersperbucket),max(winnings) INTO pprizepool,pwinningamount FROM distributiondetails WHERE id = NEW.templateid;
    IF pwinningamount IS NULL THEN
      SET pwinningamount = 0;
    END IF;

    SET NEW.endtime = pendtime;
    SET NEW.markets = (SELECT markets FROM symbolinfo WHERE symbol = NEW.symbol limit 1);
    SET NEW.winningamount = pwinningamount;

    IF NEW.prizepool > 0 THEN
      INSERT INTO ACC.gameaccount (leagueid,amount) VALUES (NEW.leagueid,NEW.prizepool);
      INSERT INTO ACC.gamepromotionaccount(leagueid,amount) VALUES (NEW.leagueid,-NEW.prizepool);
    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `AddUnixTimeStampsToClassicLeague` BEFORE INSERT ON `classicleague` FOR EACH ROW BEGIN

    SET NEW.unixstarttime = unix_timestamp(NEW.starttime),NEW.unixendtime = unix_timestamp(NEW.endtime);

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `CreateClassicLeagueLeaderboardOnRedis` AFTER INSERT ON `classicleague` FOR EACH ROW BEGIN

      DECLARE eventobject JSON;
      SELECT json_object('leagueid',NEW.leagueid,'starttime',UNIX_TIMESTAMP(NEW.starttime),'endtime',UNIX_TIMESTAMP(NEW.endtime),'symbol',NEW.symbol,'quantity',10,'spotsAvailable',NEW.totalplayers,
      'ondemand',NEW.ondemand,'basegame', NEW.basegame)
      INTO eventobject;
      INSERT INTO lambdaop
      SELECT lambda_async(
          'arn:aws:lambda:ap-southeast-2:246668742495:function:CreateClassicLeagueLeaderboardOnRedis', eventobject);

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trigger_classic_league_game_data_change_notification` AFTER UPDATE ON `classicleague` FOR EACH ROW BEGIN

      DECLARE response JSON;
      IF NEW.starttime > NOW() THEN

          SELECT lambda_async('arn:aws:lambda:ap-southeast-2:246668742495:function:notify_league_data_change',
          JSON_OBJECT('room','classic','data',JSON_OBJECT("symbol",NEW.symbol,"leagueid", NEW.leagueid))) INTO response;

      END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgUpdateClassicLeagueParamsOnCreation_test` BEFORE INSERT ON `classicleague_test` FOR EACH ROW tlabel : BEGIN    DECLARE pprizepool DECIMAL(10,2);    DECLARE pwinningamount DECIMAL(10,2);    DECLARE ptemplateid INT;    DECLARE maxseconds INT DEFAULT 0;
    DECLARE rlimit INT DEFAULT NEW.botcount;
    DECLARE pendtime DATETIME;
    
    SET pendtime = (SELECT NEW.startTime + INTERVAL (SELECT minutes FROM TL_Ref_duration WHERE name = NEW.duration AND        markets = (SELECT markets FROM symbolinfo WHERE symbol = NEW.symbol limit 1) ) MINUTE);
    SELECT id into ptemplateid FROM distributiontemplate WHERE spots = NEW.totalplayers AND entryfee = NEW.entryfee AND prizepool = NEW.prizepool;



    IF NEW.ondemand = 1 THEN
        SET NEW.guaranteed = 0;
    END IF;



    SELECT sum(winnings*usersperbucket),max(winnings) INTO pprizepool,pwinningamount FROM distributiondetails WHERE id = ptemplateid;
    IF pwinningamount IS NULL THEN
      SET pwinningamount = 0;
    END IF;
    SET NEW.endtime = pendtime;
    SET NEW.markets = (SELECT markets FROM symbolinfo WHERE symbol = NEW.symbol limit 1);
    SET NEW.winningamount = pwinningamount;
    SET NEW.templateid = ptemplateid;
    SET maxseconds = TIMESTAMPDIFF(SECOND,NOW(),NEW.starttime);

    IF NEW.prizepool > 0 THEN
      INSERT INTO ACC.gameaccount (leagueid,amount) VALUES (NEW.leagueid,NEW.prizepool);
      INSERT INTO ACC.gamepromotionaccount(leagueid,amount) VALUES (NEW.leagueid,-NEW.prizepool);
    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgcreateclassicleaguebotentrytime` BEFORE INSERT ON `classicleaguebots` FOR EACH ROW BEGIN
    DECLARE ptradecount INT DEFAULT NEW.tradecount;

    SET NEW.jointime = DATE_ADD(NEW.publishtime,INTERVAL NEW.sectoadd SECOND);
    
    
    
    

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `classicleaguebottradetime` BEFORE INSERT ON `classicleaguebottrades` FOR EACH ROW BEGIN
    SET NEW.tradetime = DATE_ADD(NEW.startTime,INTERVAL NEW.sectoadd SECOND);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `completedlamdatrigger` AFTER INSERT ON `completedgames` FOR EACH ROW BEGIN
    
      DECLARE eventobject JSON;
      SELECT json_object('channel','processing_state','data',json_object('transition',1,'leagueid',NEW.leagueid))
      INTO eventobject;      
      INSERT INTO lambdaop
      SELECT lambda_async(
          'arn:aws:lambda:ap-south-1:312171270419:function:testRdsEvent', eventobject);
        
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `killQ` BEFORE INSERT ON `killQ` FOR EACH ROW BEGIN

    DECLARE eventobject JSON;

    IF NEW.leaguetype = 4 THEN
        SELECT json_object('leagueId',NEW.leagueId)
        INTO eventobject;
        INSERT INTO lambdaop
        SELECT lambda_async(
            'arn:aws:lambda:ap-southeast-2:246668742495:function:sendkillQToLeagueQOnGameStart', eventobject);
    END IF;

    IF NEW.leaguetype = 3 THEN
        SELECT json_object('leagueid',NEW.leagueid,'killQ',1) INTO eventobject;
        INSERT INTO lambdaop
        SELECT lambda_async(
            'arn:aws:lambda:ap-southeast-2:246668742495:function:CreateSelectionLeagueQue', eventobject);

    END IF;


END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `create_mega_game_record` AFTER INSERT ON `leaguesschedule` FOR EACH ROW BEGIN


    DECLARE pminutes INT;

    IF NEW.addtomega = 1 THEN 

        SELECT minutes INTO pminutes FROM TL.TL_Ref_duration WHERE markets = NEW.markets and name = NEW.duration;

        INSERT INTO TL.mega_league_games (leagueid, leaguetype, starttime, endtime, entryfee, prizepool, bannerimage, referral_credits, deeplink)
        VALUES (NEW.rowid + 60000, NEW.leaguetype, NEW.starttime, DATE_ADD(NEW.starttime, INTERVAL pminutes MINUTE),
                NEW.entryfee, NEW.prizepool, NEW.bannerimage, NEW.referral_credits,'');    

    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `recordUserEntryIntoRedis` AFTER INSERT ON `order_record_classic` FOR EACH ROW BEGIN

      DECLARE eventobject JSON;
      SELECT json_object('leagueId',NEW.leagueid,'userId',NEW.uid)
      INTO eventobject;
      INSERT INTO lambdaop
      SELECT lambda_async(
          'arn:aws:lambda:ap-southeast-2:246668742495:function:addEntryToClassicLeagueLeaderboard', eventobject);

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `after_order_record_classic_insert` AFTER INSERT ON `order_record_classic` FOR EACH ROW BEGIN
    CALL AFFILIATE_PROGRAM.calculate_and_apply_tier_benefits(
        NEW.uid,
        NEW.leagueid,
        NEW.amount,
        NEW.revenue,
        4,
        NEW.oid
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `after_order_record_selection_insert` AFTER INSERT ON `order_record_selection` FOR EACH ROW BEGIN
    CALL AFFILIATE_PROGRAM.calculate_and_apply_tier_benefits(
        NEW.uid,
        NEW.leagueid,
        NEW.amount,
        NEW.revenue,
        3,
        NEW.oid
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `after_order_record_insert` AFTER INSERT ON `order_record_target` FOR EACH ROW BEGIN
    CALL AFFILIATE_PROGRAM.calculate_and_apply_tier_benefits(
        NEW.uid,
        NEW.leagueid,
        NEW.amount,
        NEW.revenue,
        2,
        NEW.oid
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgpublishbattleleague` AFTER INSERT ON `publishbattleleague` FOR EACH ROW BEGIN
    INSERT INTO TL.leagues (leagueid,leaguetype,starttime) VALUES (NEW.leagueid,'Battle',NEW.starttime);
    INSERT INTO TL.battleleague (leagueid,symbol1,symbol2,starttime,duration,entryfee,prizepool,botcount,processed,max_credits_absolute,max_credits_percentage,ondemand)
    VALUES (NEW.leagueid,NEW.symbol1,NEW.symbol2,NEW.starttime,NEW.duration,NEW.entryfee,NEW.prizepool,NEW.botcount,1,NEW.max_credits_absolute,NEW.max_credits_percentage,NEW.ondemand);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgpublishclassicleague` AFTER INSERT ON `publishclassicleague_temp` FOR EACH ROW BEGIN
    INSERT INTO TL.classicleague (leagueid, symbol, starttime, duration, entryfee, prizepool, totalplayers, 
    max_credits_absolute, max_credits_percentage, ondemand, basegame, basegameid, segmentId, templateid)
    VALUES (NEW.leagueid, NEW.symbol, NEW.starttime, NEW.duration, NEW.entryfee, NEW.prizepool, NEW.totalplayers,
    NEW.max_credits_absolute, NEW.max_credits_percentage, NEW.ondemand, NEW.basegame, NEW.basegameid, NEW.segmentId, NEW.templateid);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgpublishclassicleague_temp_test` AFTER INSERT ON `publishclassicleague_temp_test` FOR EACH ROW BEGIN
    DECLARE t_transactionfee DECIMAL(10,2) DEFAULT 0;
    SELECT revenuepercentage INTO t_transactionfee FROM TL.distributiontemplate WHERE
    spots = NEW.totalplayers AND prizepool = NEW.prizepool AND entryfee = NEW.entryfee;
    
    INSERT INTO TL.classicleague_test (leagueid,symbol,starttime,duration,entryfee,prizepool,botcount,totalplayers,processed,max_credits_absolute,max_credits_percentage,ondemand,basegame)
    VALUES (NEW.leagueid,NEW.symbol1,NEW.starttime,NEW.duration,NEW.entryfee,NEW.prizepool,NEW.botcount,NEW.totalplayers,1,NEW.max_credits_absolute,NEW.max_credits_percentage,NEW.ondemand,NEW.basegame);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgpublishclassicleague_test` AFTER INSERT ON `publishclassicleague_test` FOR EACH ROW BEGIN
    DECLARE t_transactionfee DECIMAL(10,2) DEFAULT 0;
    SELECT revenuepercentage INTO t_transactionfee FROM TL.distributiontemplate WHERE
    spots = NEW.totalplayers AND prizepool = NEW.prizepool AND entryfee = NEW.entryfee;
    INSERT INTO TL.leagues_test (leagueid,leaguetype,starttime,transactionfee) VALUES (NEW.leagueid,'Classic',NEW.starttime,t_transactionfee);
    INSERT INTO TL.classicleague_publishing_test (leagueid,symbol,starttime,duration,entryfee,prizepool,botcount,totalplayers,processed,max_credits_absolute,max_credits_percentage,ondemand)
    VALUES (NEW.leagueid,NEW.symbol1,NEW.starttime,NEW.duration,NEW.entryfee,NEW.prizepool,NEW.botcount,NEW.totalplayers,1,NEW.max_credits_absolute,NEW.max_credits_percentage,NEW.ondemand);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgpublishselectionleague` AFTER INSERT ON `publishselectionleague` FOR EACH ROW BEGIN

        INSERT INTO TL.selectionleague (leagueid, universe, markets, starttime, duration, entryfee, prizepool, botcount, totalplayers,
        templateid, max_credits_absolute, max_credits_percentage, ondemand, basegame, basegameid, segmentId, max_portfolios)

        VALUES (NEW.leagueid, NEW.universe, NEW.markets, NEW.starttime, NEW.duration, NEW.entryfee, NEW.prizepool, NEW.botcount, NEW.totalplayers,
        NEW.templateid, NEW.max_credits_absolute, NEW.max_credits_percentage, NEW.ondemand, NEW.basegame, NEW.leagueid, NEW.segmentId, NEW.max_portfolios);

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trigger_create_selection_league_joining_queue` AFTER INSERT ON `publishselectionleague` FOR EACH ROW BEGIN

    DECLARE eventobject JSON;
    IF NEW.basegame = 1 THEN
        INSERT INTO TL.selection_league_symbols (leagueid, symbolid, symbolname)
        SELECT NEW.leagueid, rowid, symbol FROM  TL.symbolinfo WHERE universe = NEW.universe;
        SELECT json_object('leagueid',NEW.leagueid) INTO eventobject;
        INSERT INTO lambdaop
        SELECT lambda_async('arn:aws:lambda:ap-southeast-2:246668742495:function:CreateSelectionLeagueQue', eventobject);
    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgpublishtargetleague` AFTER INSERT ON `publishtargetleague` FOR EACH ROW BEGIN
    INSERT INTO TL.targetleague (leagueid, symbol, starttime, duration, entryfee, prizepool, botcount, processed,
    max_credits_absolute, max_credits_percentage, ondemand, segmentId)
    VALUES (NEW.leagueid, NEW.symbol, NEW.starttime, NEW.duration, NEW.entryfee, NEW.prizepool, NEW.botcount, 1,
    NEW.max_credits_absolute, NEW.max_credits_percentage, NEW.ondemand, NEW.segmentId);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `insert_portfolio_trigger` AFTER INSERT ON `selection_league_json_portfolios` FOR EACH ROW BEGIN
    DECLARE portfolio_index INT DEFAULT 0;
    DECLARE portfolio_count INT DEFAULT JSON_LENGTH(NEW.portfolio);

    WHILE portfolio_index < portfolio_count DO
        INSERT INTO selection_league_portfolios (leagueid, uid, portfolio_id, symbol_id, symbol, multiplier)
        VALUES (NEW.leagueid, NEW.uid, NEW.portfolio_id,
                JSON_UNQUOTE(JSON_EXTRACT(NEW.portfolio, CONCAT('$[', portfolio_index, '].id'))),
                JSON_UNQUOTE(JSON_EXTRACT(NEW.portfolio, CONCAT('$[', portfolio_index, '].symbol'))),
                JSON_UNQUOTE(JSON_EXTRACT(NEW.portfolio, CONCAT('$[', portfolio_index, '].multiplier'))));
        SET portfolio_index = portfolio_index + 1;
    END WHILE;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `update_portfolio_trigger` AFTER UPDATE ON `selection_league_json_portfolios` FOR EACH ROW BEGIN
    DECLARE portfolio_index INT DEFAULT 0;
    DECLARE portfolio_count INT DEFAULT JSON_LENGTH(NEW.portfolio);


    UPDATE selection_league_portfolios SET active = 0 WHERE 
    uid = NEW.uid AND leagueid = NEW.leagueid AND portfolio_id = NEW.portfolio_id;


    WHILE portfolio_index < portfolio_count DO
        INSERT INTO selection_league_portfolios (leagueid, uid, portfolio_id, symbol_id, symbol, multiplier)
        VALUES (NEW.leagueid, NEW.uid, NEW.portfolio_id,
                JSON_UNQUOTE(JSON_EXTRACT(NEW.portfolio, CONCAT('$[', portfolio_index, '].id'))),
                JSON_UNQUOTE(JSON_EXTRACT(NEW.portfolio, CONCAT('$[', portfolio_index, '].symbol'))),
                JSON_UNQUOTE(JSON_EXTRACT(NEW.portfolio, CONCAT('$[', portfolio_index, '].multiplier'))));
        SET portfolio_index = portfolio_index + 1;
    END WHILE;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `selection_league_winners_insert_trigger` AFTER INSERT ON `selection_league_winners` FOR EACH ROW BEGIN
    INSERT INTO ATR.transactiontable
    (uid, leagueid, leaguetype, amount, entrytype, transactiontype, transactiontypeid)
    VALUES
    (NEW.uid, NEW.leagueid, 3, NEW.amount, 'CREDIT', 'WINNING', 9);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgUpdateSelectionLeagueParamsOnCreation` BEFORE INSERT ON `selectionleague` FOR EACH ROW BEGIN
    DECLARE pwinningamount DECIMAL(10,2);
    DECLARE maxseconds INT DEFAULT 0;
    DECLARE rlimit INT DEFAULT NEW.botcount;

    IF NEW.ondemand = 1 THEN
        SET NEW.guaranteed = 0;
    END IF;

    SELECT max(winnings) INTO pwinningamount FROM distributiondetails WHERE id = NEW.templateid;
    IF pwinningamount IS NULL THEN
      SET pwinningamount = 0;
    END IF;

    SET NEW.endtime = (SELECT NEW.startTime + INTERVAL (SELECT minutes FROM TL_Ref_duration WHERE name = NEW.duration AND
        markets = NEW.markets ) MINUTE);
    SET NEW.winningamount = pwinningamount;

    IF NEW.prizepool > 0 THEN
      INSERT INTO ACC.gameaccount (leagueid,amount) VALUES (NEW.leagueid,NEW.prizepool);
      INSERT INTO ACC.gamepromotionaccount(leagueid,amount) VALUES (NEW.leagueid,-NEW.prizepool);
    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `Trigger_StopSpotsFilled_Beforeupdate_Selection` BEFORE UPDATE ON `selectionleague` FOR EACH ROW begin

    if NEW.spotsfilled > NEW.totalplayers
    then

      SIGNAL sqlstate '45001' set message_text = "No way ! You cannot do this !";

    end if ;

end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trigger_selection_league_game_data_change_notification` AFTER UPDATE ON `selectionleague` FOR EACH ROW BEGIN

      DECLARE response JSON;
      IF NEW.starttime > NOW() THEN

          SELECT lambda_async('arn:aws:lambda:ap-southeast-2:246668742495:function:notify_league_data_change',
          JSON_OBJECT('room','selection','data',JSON_OBJECT("symbol",NEW.markets,"leagueid", NEW.leagueid))) INTO response;

      END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgcreateselectionleaguebotentrytime` BEFORE INSERT ON `selectionleaguebots` FOR EACH ROW BEGIN
    

    SET NEW.jointime = DATE_ADD(NEW.startTime,INTERVAL NEW.sectoadd SECOND);

    
    
    


END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgSetPricesForTargetLeague` BEFORE INSERT ON `targetleague` FOR EACH ROW BEGIN


    DECLARE p_endtime DATETIME;
    DECLARE p_precision DECIMAL(20, 10);
    DECLARE p_bandwidth DECIMAL(20, 10);
    DECLARE p_leagueid BIGINT UNSIGNED;
    DECLARE p_ltp DECIMAL(10, 2);
    DECLARE p_winningbracket JSON;
    DECLARE p_brackets JSON;
    DECLARE p_symbol VARCHAR(20);
    DECLARE p_duration VARCHAR(10);

    SET p_symbol = NEW.symbol;
    SET p_duration = NEW.duration;
    SET p_leagueid = NEW.leagueid;

    SELECT NEW.startTime + INTERVAL (SELECT minutes FROM TL_Ref_duration WHERE name = NEW.duration AND
    markets = (SELECT markets FROM symbolinfo WHERE symbol = NEW.symbol) ) MINUTE INTO p_endtime;

    SELECT ltp INTO p_ltp FROM ltpstore WHERE symbol = p_symbol;
    SELECT min_tick INTO p_precision FROM TL.symbolinfo WHERE symbol = p_symbol;

    SELECT bandwidth INTO p_bandwidth FROM TL.target_league_bracket_references WHERE  symbol = p_symbol AND duration = p_duration;
    SELECT ROUND(p_ltp / p_precision) * p_precision INTO p_ltp;

    INSERT INTO targetleaguebands (leagueid,id,lb,ub)
    SELECT p_leagueid, rowid, TRIM(p_ltp+rid*p_bandwidth) + 0, TRIM(p_ltp+rid*p_bandwidth+p_bandwidth)+0 FROM bracketindices;
    SELECT JSON_OBJECT("id",4,"lb",p_ltp,"ub",TRIM(p_ltp+p_bandwidth)+0,"players",0,"earnings",0) INTO p_winningbracket;
    SELECT JSON_OBJECT("RANGE",JSON_ARRAYAGG(JSON_OBJECT("id",rowid,"lb", TRIM(p_ltp+rid*p_bandwidth) + 0,"ub", TRIM(p_ltp+rid*p_bandwidth+p_bandwidth)+0, "players", 0, "earnings", 0)))INTO p_brackets FROM bracketindices;


    SET NEW.markets = (SELECT markets FROM symbolinfo WHERE symbol = NEW.symbol),
        NEW.startprice = p_ltp,
        NEW.endprice = p_ltp,
        NEW.endtime = p_endtime,
        NEW.unix_start_time = UNIX_TIMESTAMP(NEW.startTime),
        NEW.unix_end_time = UNIX_TIMESTAMP(p_endtime),
        NEW.winningbracket = p_winningbracket,
        NEW.brackets = p_brackets;
    INSERT INTO targetleaguewinningbracket (leagueid,ltp,winningbracket) VALUES (p_leagueid,p_ltp,p_winningbracket);


    IF NEW.entryfee = 0 AND NEW.prizepool > 0 THEN
      INSERT INTO ACC.gameaccount (leagueid,amount) VALUES (p_leagueid,NEW.prizepool);
      INSERT INTO ACC.gamepromotionaccount(leagueid,amount) VALUES (p_leagueid,-NEW.prizepool);
    END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trigger_target_league_game_data_change_notification` AFTER UPDATE ON `targetleague` FOR EACH ROW BEGIN

      DECLARE response JSON;
      IF NEW.starttime > NOW() THEN

          SELECT lambda_async('arn:aws:lambda:ap-southeast-2:246668742495:function:notify_league_data_change',
          JSON_OBJECT('room','target','data',JSON_OBJECT("symbol",NEW.symbol,"leagueid", NEW.leagueid))) INTO response;

      END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgSetMinMaxTargetBands` BEFORE INSERT ON `targetleaguebands` FOR EACH ROW BEGIN
    DECLARE plb DECIMAL(50,18) DEFAULT NEW.lb;
    DECLARE pub DECIMAL(50,18) DEFAULT NEW.ub;
    IF NEW.id = 1 THEN
        SET pub = 10000000;
    END IF;
    IF NEW.id = 11 THEN
        SET plb = 0;
    END IF;
    SET NEW.lbcmp = plb,NEW.ubcmp = pub;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `updateTargetLeagueBandEarnings` BEFORE UPDATE ON `targetleaguebands` FOR EACH ROW BEGIN

    SET NEW.earnings = (SELECT prizepool/NEW.players FROM targetleague WHERE leagueid = NEW.leagueid);

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgcreatetargetleaguebotentrytime` BEFORE INSERT ON `targetleaguebots` FOR EACH ROW BEGIN

    SET NEW.jointime = DATE_ADD(NEW.startTime,INTERVAL NEW.sectoadd SECOND);
    
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `updateTargetLeagueWinners` AFTER INSERT ON `targetleagueendgameprices` FOR EACH ROW BEGIN

    DECLARE t_leagueid DECIMAL(10,2) DEFAULT NEW.leagueid;
    DECLARE t_startprice DECIMAL(10,2) DEFAULT NEW.startprice;
    DECLARE t_endprice DECIMAL(10,2) DEFAULT NEW.endprice;
    DECLARE t_wid INT DEFAULT 4;
    DECLARE t_wb JSON ;

    SELECT id,JSON_OBJECT("id",id,"lb",lb,"ub",ub,"players",players,"earnings",earnings)
    INTO t_wid,t_wb FROM targetleaguebands
    WHERE NEW.endprice >= lbcmp AND NEW.endprice < ubcmp AND leagueid = NEW.leagueid;

    UPDATE targetleaguewinningbracket SET ltp = NEW.endprice,winningbracketid = t_wid,winningbracket  = t_wb
    WHERE leagueid = NEW.leagueid;
    
    INSERT INTO winners (leagueid,uid,amount)
    SELECT winners.leagueid,uid,earning FROM
    (SELECT leagueid,uid FROM
    (SELECT leagueid,uid,bdist,
    RANK() OVER(partition by leagueid order by bdist asc) AS standing FROM
    (SELECT selection.leagueid,uid,ABS(wlb-lb) as bdist FROM
    (SELECT selection.leagueid,uid,lb FROM
    (SELECT leagueid,uid,votedbandid FROM userselectiontarget WHERE leagueid = t_leagueid) selection
    LEFT JOIN
    (SELECT leagueid,id,lb FROM targetleaguebands WHERE leagueid = t_leagueid) bands
    ON selection.leagueid = bands.leagueid AND selection.votedbandid = bands.id) selection
    LEFT JOIN
    (SELECT leagueid,JSON_EXTRACT(winningbracket,'$.lb') as wlb FROM
    targetleaguewinningbracket WHERE leagueid = t_leagueid) winners
    ON selection.leagueid = winners.leagueid) league) league
    WHERE standing = 1) winners
    LEFT JOIN
    (SELECT leagueid,TRUNCATE(prizepool/count(*),2) AS earning FROM
    (SELECT leagueid,uid,prizepool,bdist,
    RANK() OVER(partition by leagueid order by bdist asc) AS standing FROM
    (SELECT selection.leagueid,uid,prizepool,ABS(wlb-lb) as bdist FROM
    (SELECT selection.leagueid,uid,lb,prizepool FROM
    (SELECT selection.leagueid,uid,lb FROM
    (SELECT leagueid,uid,votedbandid FROM userselectiontarget WHERE leagueid = t_leagueid) selection
    LEFT JOIN
    (SELECT leagueid,id,lb FROM targetleaguebands WHERE leagueid = t_leagueid) bands
    ON selection.leagueid = bands.leagueid AND selection.votedbandid = bands.id) selection
    LEFT JOIN
    (SELECT leagueid,prizepool FROM targetleague WHERE leagueid = t_leagueid) league
    ON selection.leagueid = league.leagueid) selection
    LEFT JOIN
    (SELECT leagueid,JSON_EXTRACT(winningbracket,'$.lb') as wlb FROM
    targetleaguewinningbracket WHERE leagueid = t_leagueid) winners
    ON selection.leagueid = winners.leagueid) league) league
    WHERE standing = 1
    GROUP BY leagueid) earnings
    ON winners.leagueid = earnings.leagueid;

    UPDATE targetleague SET startprice = t_startprice,endprice = t_endprice,winningbracket = t_wb,transition = 1 WHERE leagueid = t_leagueid;


END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `Trigger_XXX_Beforeupdate` BEFORE UPDATE ON `testexceptionthrow` FOR EACH ROW begin

    if NEW.insertcount > 2
    then

      SIGNAL sqlstate '45001' set message_text = "No way ! You cannot do this !";

    end if ;

end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `log_tier_percentage_changes` BEFORE UPDATE ON `tier_percentage` FOR EACH ROW BEGIN
    INSERT INTO tier_percentage_log VALUES (OLD.affiliate_tier, OLD.tier_id, OLD.affiliate_percentage); 
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgUpdateEntryExitPriceUserSelection` BEFORE INSERT ON `userselectionselect_temp` FOR EACH ROW BEGIN
    SET NEW.entryprice = 0,NEW.exitprice = 0;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`admin`@`%`*/ /*!50003 TRIGGER `trgInsertWinningsIntoWallet` AFTER INSERT ON `winners` FOR EACH ROW BEGIN
    DECLARE ttransactiontypeid INT DEFAULT 0;
    SELECT IF(botflag=0,18,13) INTO ttransactiontypeid FROM ATR.user WHERE uid = NEW.uid;

    INSERT INTO ATR.transactiontable
    (uid,leagueid,amount,entrytype,transactiontype,transactiontypeid,winnertableid) VALUES
    (NEW.uid,NEW.leagueid,NEW.amount,'CREDIT','WINNING',ttransactiontypeid,NEW.rowid);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2023-09-24 13:34:42
