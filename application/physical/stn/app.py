#!/usr/bin/env python3

# coding: utf-8

import os
import atexit
import json
import sqlite3 as lite
import time
from random import randint
import requests
import feedparser
from pyvirtualdisplay import Display
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


if os.environ["FEEDNAME"] is None:
    feedname = 'example.com'
else:
    feedname = os.environ["FEEDNAME"]
if os.environ["FEEDURL"] is None:
    url = 'example.com'
else:
    url = os.environ["FEEDURL"]


display = Display(visible=0, size=(800, 600), backend='xephyr') # pylint: disable=invalid-name
display.start()
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("--mute-audio")
chrome_options.add_extension("./Adblock-Plus_v1.13.2.crx")
driver = webdriver.Chrome('/opt/chromedriver/chromedriver', chrome_options=chrome_options) # pylint: disable=invalid-name
feedparser.RESOLVE_RELATIVE_URIS = 0
feed = feedparser.parse(url)
con = lite.connect('feedparser.db', isolation_level=None) # pylint: disable=invalid-name
cur = con.cursor()


def exit_handler():
    if con:
        con.close()
    if driver:
        driver.quit()
    if display:
        display.stop()

atexit.register(exit_handler)


for post in feed.entries:
    print(post.title)
    resp = requests.get(post.link)
    #driver.get(post.link)
    cur.execute("SELECT COUNT(*) FROM feedscraper WHERE link = ? ", (post.link,))
    (number_of_rows,)=cur.fetchone()
    try:
        if number_of_rows is 0:
            print('entry did not exist yet')
            cur.execute("INSERT INTO feedscraper ( \
                feedname, feedentry, guid, link, title, unixtime, published_epoch ) \
                VALUES (?, ?, ?, ?, ?, ?, ?)", \
                (feedname, json.dumps(post), post.id, post.link, post.title, \
                int(time.time()), time.mktime(post.published_parsed)))
            #resp = requests.get(post.link)
            driver.get(post.link + '#Comments')
            try:
                print('starting to wait')
                comments = WebDriverWait(driver, 16).until( \
                    EC.presence_of_element_located((By.XPATH, \
                    '//*[@id="Comments"]/div[2]/section/div/div[1]/div/div/div[3]/div[1]')) \
                    )
                driver.execute_script("window.scrollTo('0',{y});".format( \
                    y=str(comments.location['y']- 100)) \
                    )
            except:
                print('TimeoutException')
            finally:
                print('not waiting any longer for main page')

            try:
                print('finding more more links')
                while True:
                    more = WebDriverWait(driver, 4).until(EC.presence_of_element_located(( \
                        By.XPATH, '//span[contains(text(), "MEHR KOMMENTARE ANZEIGEN")]')) \
                        )
                    driver.execute_script("window.scrollTo('0',{y});".format( \
                        y=str(more.location['y']- 100)) \
                        )
                    more.click()
            #except NoSuchElementException as e:
            except:
                print('no more more')

            try:
                print('trying to unfold replies')
                driver.execute_script("window.scrollTo(0,0);")
                replies = driver.find_elements_by_partial_link_text(' EINBLENDEN')
            except:
                print('no more replies to unfold')
            finally:
                for l in replies:
                    driver.execute_script("window.scrollTo('0',{y});".format( \
                        y=str(l.location['y']- 100)) \
                        )
                    l.click()

            print('finalizing/updating entry')
            cur.execute("UPDATE feedscraper SET \
                feedentry = ?, html = ?, html_0d = ?, title = ? WHERE link = ?", \
                (json.dumps(post), resp.content, driver.page_source, \
                post.title, post.link) \
                )
        else:
            print('do nothing, link existing')

        print('sleeping')
        time.sleep(randint(2, 4))

    except lite.Error as exp:
        print("Error %s:" % exp.args[0])
