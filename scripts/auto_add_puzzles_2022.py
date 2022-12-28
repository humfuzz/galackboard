"""
Script to automatically adds puzzles to Galackboard. Requires Selenium.

Steps to setup:
- Set the login credentials (usernames, URLs, passwords) to appropriate values
- Fill in the method `get_available_puzzles`
- Install Selenium: `pip install selenium`
- Get the webdriver for your browser and put it in the same directory as this script:
	The script currently uses Chrome, but you can change it to use any browser with Selenium webdriver support.
	Check your Chrome version, then get that chromedriver from https://chromedriver.chromium.org/downloads

Based off https://github.com/Galactic-Infrastructure/galackboard/blob/master/scripts/auto_add_puzzles.py

Adding rounds automatically relies on new Galackboard API endpoints added in 2022.
See https://github.com/humfuzz/galackboard/commit/f6e284883d833ccbc32b2dca0d5a51213541482a

"""

from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from urllib.parse import quote
from re import compile
from time import sleep
import json
import re
import sys


GALACKBOARD_BASE_URL = None
GALACKBOARD_PASSWORD = None
HUNT_LOGIN_PAGE = None
HUNT_LOGIN_USERNAME = None
HUNT_LOGIN_PASSWORD = None
HUNT_PUZZLES_PAGE = None

# If true, the script won't actually add new puzzles to Galackboard
DRY_RUN = False

# https://www.selenium.dev/documentation/webdriver/elements/information/
def get_available_puzzles(driver):
	"""
	Provide code to fetch the list of available puzzles.
	This code will vary by hunt year and depends on how the website is
	structured.

	The return value should be a list of tuples. Each tuple should have the
	form (puzzle title, puzzle URL).
	"""

	rs = []
	driver.get(HUNT_PUZZLES_PAGE)
	sleep(3)
	# round
	content = driver.find_element(By.CSS_SELECTOR, '#main-content')
	ps = []

	# puzzle
	for k in content.find_elements(By.CSS_SELECTOR, 'a'):
		if ('/round/') in  k.get_attribute('href'):
			if len(ps) > 0:
				rs.append( (round_title, round_href, ps) )
				ps = []

			round_title = k.text
			round_href = k.get_attribute('href')

			continue

		# print(k.get_attribute('href'))
		if ('/puzzle/') in k.get_attribute('href'):
			ps.append( (k.text, k.get_attribute('href')) )

	if len(ps) > 0:
		rs.append( (round_title, round_href, ps) )

	return rs

##################################################################
# You probably shouldn't need to edit anything below this point! #
##################################################################

if not GALACKBOARD_BASE_URL:
	print('You need to set GALACKBOARD_BASE_URL! Exiting.')
	sys.exit()

# these API endpoints were added to Galackbored (humfuzz's version) in 2022
# see https://github.com/humfuzz/galackboard/commit/f6e284883d833ccbc32b2dca0d5a51213541482a
NEW_ROUND_URL = GALACKBOARD_BASE_URL + "/newRound/{}/{}"
NEW_PUZZLE_URL = GALACKBOARD_BASE_URL + "/newPuzzle/{}/{}"
NEW_PUZZLE_IN_ROUND_URL = GALACKBOARD_BASE_URL + "/newPuzzleInRound/{}/{}/{}"

driver = webdriver.Chrome()

driver.get(GALACKBOARD_BASE_URL)
driver.find_element(By.ID, 'passwordInput').send_keys(GALACKBOARD_PASSWORD)
driver.find_element(By.ID, 'nickInput').send_keys('puzzleAdderBot')
driver.find_element(By.ID, 'nickInput').submit()
sleep(3)

# login
driver.get(HUNT_LOGIN_PAGE)
driver.find_elements(By.NAME, 'password') [0].send_keys(HUNT_LOGIN_PASSWORD)
driver.find_element(By.NAME, 'username').send_keys(HUNT_LOGIN_USERNAME)
driver.find_element(By.NAME, 'username').submit()
sleep(3)

def url_to_slug(url):
	match = re.search(r'\/([^\/]+)\/?$', url)
	if match:
		return match[1]

# remember what's been added, and
#   let the scraper keep track
driver.get(GALACKBOARD_BASE_URL)
sleep(3)
existing_puzzle_slugs = [
	url_to_slug(k.get_attribute('href'))
	for k in driver.find_elements(By.CLASS_NAME, 'pull-right')
	if k.get_attribute('title') == 'Link to hunt site'
]

# TODO: write this shit to a file and never trust first load


while True:
	print(f'reloading puzzle page ({datetime.now().strftime("%H:%M:%S")})')
	new_puzzles = get_available_puzzles(driver)

	driver.get(GALACKBOARD_BASE_URL)
	sleep(3)
	galackboard_slugs = [
		url_to_slug(k.get_attribute('href'))
		for k in driver.find_elements(By.CLASS_NAME, 'pull-right')
		if k.get_attribute('title') == 'Link to hunt site'
	]

	for slug in galackboard_slugs:
		if slug not in existing_puzzle_slugs:
			existing_puzzle_slugs.append(slug)

	for (round_title, round_href, round_puzzles) in new_puzzles:
		# print(round_title, round_href)
		# for (title, href) in round_puzzles:
		# 	print("    ", title, href)
		# continue

		round_slug = url_to_slug(round_href)
		if round_slug not in existing_puzzle_slugs:
			new_round_url = NEW_ROUND_URL.format(quote(round_title, safe=''), quote(round_href, safe=''))
			print(f'Adding round {round_slug}')
			existing_puzzle_slugs.append(round_slug)

		# print(f'Adding round {round_title}: {round_href}')
			if not DRY_RUN:
				driver.get(new_round_url)
			sleep(3)

		for (title, href) in round_puzzles:
			slug = url_to_slug(href)
			if slug in existing_puzzle_slugs:
				continue

			# add puzzle in round
			new_puzzle_url = NEW_PUZZLE_IN_ROUND_URL.format(
				quote(round_title, safe=''), 
				quote(title, safe=''), 
				quote(href, safe=''))

			print(f'Adding puzzle {slug} in {round_title}')
			existing_puzzle_slugs.append(slug)

			# print(f'Adding puzzle {slug}: {new_puzzle_url}')
			if not DRY_RUN:
				driver.get(new_puzzle_url)
			sleep(3)

			# # roundless
			# new_puzzle_url = NEW_PUZZLE_URL.format(quote(title, safe=''), quote(href, safe=''))
			# print(f'Adding puzzle {slug}: {new_puzzle_url}')
			# if not DRY_RUN:
			# 	driver.get(new_puzzle_url)
			# sleep(3)
	
	sleep(20)