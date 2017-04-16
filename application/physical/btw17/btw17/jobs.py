# -*- coding: utf-8 -*-
import json
import time
import sqlite3 as lite
import logging



from pyvirtualdisplay import Display
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC




def getHtmlBySelenium(url):

    #http://stackoverflow.com/a/41229928
    with Display(visible=0, size=(800, 600), backend='xvfb'):
        chrome_options = webdriver.ChromeOptions()
        chrome_options.add_argument("--mute-audio")
        chrome_options.add_extension("./Adblock-Plus_v1.13.2.crx")
        driver = webdriver.Chrome('/opt/chromedriver/chromedriver', chrome_options=chrome_options)

        driver.get(url + '#Comments')
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
        except:
            print('no more more')

        try:
            print('trying to unfold replies')
            driver.execute_script("window.scrollTo(0,0);")
            replies = driver.find_elements_by_partial_link_text(' EINBLENDEN')
        except:
            print('no more replies to unfold')
        finally:
            for link in replies:
                driver.execute_script("window.scrollTo('0',{y});".format( \
                    y=str(link.location['y']- 100)) \
                    )
                link.click()
        retval = driver.page_source
        driver.quit()
        return retval

def persist_article_selenium(feedentry_id, feedname, entry, column='html0d'):
    '''
    Takes some metadata and a target column to update with to-be-scraped HTML.
    Calls the scraping function.
    '''
    with open('hello2.log', 'a') as f:
        f.write('This is a test:  %s \n' % (entry.id))

    sqlite_connection = lite.connect('../../../data/feedparser_2017-04-07-19-30.db', isolation_level=None) # pylint: disable=invalid-name
    sqlite_cursor = sqlite_connection.cursor()

    if feedname == 'welt.de':
        entry.id = entry.id.replace('https://www.welt.de/feeds/', "")

    html = getHtmlBySelenium(entry.link)

    try:
        #https://speakerdeck.com/pycon2016/dave-sawyer-sqlite-gotchas-and-gimmes
        with sqlite_connection:
            sqlite_cursor.execute("UPDATE article SET \
                "+column+" = ? \
                WHERE feedentry_id = ?", \
                (html, feedentry_id \
            ))
        print("inserted !")
        #print("inserted " + sqlite_cursor.lastrowid + "!")
    except lite.Error as exp:
        #return False
        print("insert failed %s:" % exp.args[0])
    #     #return "Error %s:" % exp.args[0]

