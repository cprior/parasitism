
from rq import Queue
import os
import feedparser
import json
import sqlite3 as lite
import time
import logging

from prometheus_client import Summary, Counter, start_http_server
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

from btw17.delay import DelayedJob
from redis import Redis
import btw17.jobs as jobs
import btw17.scrape as scrape

#work in progress
registry = CollectorRegistry()
g = Gauge('job_last_success_unixtime', 'Last time a batch job successfully finished', registry=registry)
FEEDENTRIES_SCRAPE_DURATION = Summary('stn_feedentriesscrapes_seconds', 'Description of summary', ['feedname'], registry=registry)
FEED_SCRAPE = Counter('stn_feedscrapes_total', 'RSS feed scrapes', ['feedname'], registry=registry)
FEEDENTRIES_SCRAPE_COUNT = Counter('stn_feedentriesscrapes_total', 'RSS feed scrapes', ['feedname'], registry=registry)


redis_connection = Redis()
delayed_jobs = DelayedJob(redis_connection)

q = Queue(connection=redis_connection)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
# create a file handler
handler = logging.FileHandler('hello.log')
handler.setLevel(logging.INFO)
# create a logging format
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
# add the handlers to the logger
logger.addHandler(handler)
logger.info('init logger')

feedparser.RESOLVE_RELATIVE_URIS = 0
sqlite_connection = lite.connect('../../../data/feedparser_2017-04-07-19-30.db', isolation_level=None) # pylint: disable=invalid-name
#sqlite_connection.row_factory = lite.Row
sqlite_cursor = sqlite_connection.cursor()


#feedname = os.getenv('FEEDNAME', 'welt.de')
#url = os.getenv('FEEDURL', 'https://www.welt.de/feeds/latest.rss')
feeds = sqlite_cursor.execute("SELECT url, name FROM feed WHERE active = 1").fetchall()


def persist_feedentry(feedname, entry):
    '''
    Writes a singe entry into the database table,
    and schedules for several scraping visits.
    '''
    sqlite_cursor.execute("SELECT COUNT(*) FROM feedentry \
        WHERE feed_name = ? AND entry_link = ? ", (feedname, entry.link,))
    (number_of_rows,) = sqlite_cursor.fetchone()
    if number_of_rows is 0:
        try:
            print('entry did not exist yet')
            sqlite_cursor.execute("INSERT INTO feedentry ( \
                feed_name, entry_json, entry_guid, entry_link, entry_title, entry_published_at, created_at ) \
                VALUES (?, ?, ?, ?, ?, ?, ?)", \
                (feedname, json.dumps(entry), entry.id, entry.link, entry.title, \
                time.mktime(entry.published_parsed), int(time.time())))

            sqlite_cursor.execute("INSERT INTO article ( \
                feed_name, feedentry_id, feedentry_json, feedentry_guid, created_at ) \
                VALUES (?, ?, ?, ?, ?)", \
                (feedname, sqlite_cursor.lastrowid, json.dumps(entry), entry.id, int(time.time()) \
                ))
            delayed_jobs.minutes('default', 1, jobs.persist_article_selenium, \
                sqlite_cursor.lastrowid, feedname, entry, column='html0d')
            delayed_jobs.hours('default', 24, jobs.persist_article_selenium, \
                sqlite_cursor.lastrowid, feedname, entry, column='html1d')
            delayed_jobs.days('default', 7, jobs.persist_article_selenium, \
                sqlite_cursor.lastrowid, feedname, entry, column='html7d')
            delayed_jobs.days('default', 30, jobs.persist_article_selenium, \
                sqlite_cursor.lastrowid, feedname, entry, column='html30d')
        except lite.Error as exp:
            print("Error %s:" % exp.args[0])
    else:
        print('do nothing, link existing')

def get_feed_entries(feeds):
    '''
    Loops over a feedparser object and its entries,
    modifies entries if necessary and call the persistance function.
    '''
    for feed in feeds:
        feedname = feed[1]
        url = feed[0]
        FEED_SCRAPE.labels(feedname).inc()
        current_feed = feedparser.parse(url)

        for entry in current_feed.entries:
            if feedname == 'welt.de':
                entry.id = entry.id.replace('https://www.welt.de/feeds/', "")
            FEEDENTRIES_SCRAPE_COUNT.labels(feedname).inc()
            print(entry.title)
            with FEEDENTRIES_SCRAPE_DURATION.labels(feedname).time():
                persist_feedentry(feedname, entry)
            push_to_gateway('localhost:9091', job='batchA', registry=registry)


def main(feeds):
    get_feed_entries(feeds)

if __name__ == '__main__':
    start_http_server(19761)
    main(feeds)
    g.set_to_current_time()
    push_to_gateway('localhost:9091', job='batchA', registry=registry)


