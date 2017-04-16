
from pyvirtualdisplay import Display
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def gethtml(link, driver):
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
    return driver.page_source