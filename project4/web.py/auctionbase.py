#!/usr/bin/env python

from datetime import datetime
from jinja2 import Environment, FileSystemLoader
import sqlitedb
import web
import os                             # of the imports to work!
import sys
sys.path.insert(0, 'lib')  # this line is necessary for the rest


###########################################################################################
##########################DO NOT CHANGE ANYTHING ABOVE THIS LINE!##########################
###########################################################################################

######################BEGIN HELPER METHODS######################

# helper method to convert times from database (which will return a string)
# into datetime objects. This will allow you to compare times correctly (using
# ==, !=, <, >, etc.) instead of lexicographically as strings.

# Sample use:
# current_time = string_to_time(sqlitedb.getTime())


def string_to_time(date_str):
    return datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')

# helper method to render a template in the templates/ directory
#
# `template_name': name of template file to render
#
# `**context': a dictionary of variable names mapped to values
# that is passed to Jinja2's templating engine
#
# See curr_time's `GET' method for sample usage
#
# WARNING: DO NOT CHANGE THIS METHOD


def render_template(template_name, **context):
    extensions = context.pop('extensions', [])
    globals = context.pop('globals', {})

    jinja_env = Environment(autoescape=True,
                            loader=FileSystemLoader(os.path.join(
                                os.path.dirname(__file__), 'templates')),
                            extensions=extensions,
                            )
    jinja_env.globals.update(globals)

    web.header('Content-Type', 'text/html; charset=utf-8', unique=True)

    return jinja_env.get_template(template_name).render(context)

#####################END HELPER METHODS#####################


urls = ('/currtime', 'curr_time',
        '/selecttime', 'select_time',
        '/search', 'search',
        '/add_bid', 'add_bid',
        '/', 'index',
        '/iteminfo', 'item_info'
        # TODO: add additional URLs here
        # first parameter => URL, second parameter => class name
        )


class index:
    def GET(self):
        return render_template('app_base.html')


class add_bid:
    def GET(self):
        msg = "Please enter the item ID, your user ID, and your price."
        return render_template('add_bid.html', message=msg)

    def POST(self):
        post_params = web.input()
        item_id = post_params['itemID']
        user_id = post_params['userID']
        price = post_params['price']
        msg = "Please enter the item ID, your user ID, and your price."
        add_result = sqlitedb.add_bid(item_id, user_id, price)
        return render_template('add_bid.html', add_result=add_result, message=msg)


class item_info:
    def GET(self):
        params = web.input()
        item_id = params['item_id']
        item = sqlitedb.getItemById(item_id)
        title = item["Name"]
        seller = item["Seller_UserID"]
        desc = item["Description"]
        start_time = item["Started"]
        end_time = item["Ends"]
        currently = item["Currently"]
        num_bids = item["Number_of_Bids"]
        first_bid = item["First_Bid"]
        bid_result = sqlitedb.getBidById(item_id)
        status = sqlitedb.status(item_id)
        closed = False
        category = sqlitedb.getCategoriesById(item_id)
        if status == "closed":
            closed = True
        
        winner = "No winner"
        print winner
        if bid_result != None:
            if len(bid_result) != 0:
                winner = bid_result[len(bid_result) - 1]["UserID"]
        return render_template('item_info.html', title=title, desc=desc, seller=seller, start_time=start_time, end_time=end_time, currently=currently, bid_result=bid_result, status=status, closed=closed, category=category, num_bids=num_bids, first_bid=first_bid, winner=winner)


class curr_time:
    # A simple GET request, to '/currtime'
    #
    # Notice that we pass in `current_time' to our `render_template' call
    # in order to have its value displayed on the web page
    def GET(self):
        current_time = sqlitedb.getTime()
        return render_template('curr_time.html', time=current_time)


class select_time:
    # Aanother GET request, this time to the URL '/selecttime'
    def GET(self):
        return render_template('select_time.html')

    # A POST request
    #
    # You can fetch the parameters passed to the URL
    # by calling `web.input()' for **both** POST requests
    # and GET requests
    def POST(self):
        post_params = web.input()
        MM = post_params['MM']
        dd = post_params['dd']
        yyyy = post_params['yyyy']
        HH = post_params['HH']
        mm = post_params['mm']
        ss = post_params['ss']
        enter_name = post_params['entername']

        currTime = sqlitedb.getTime()

        selected_time = '%s-%s-%s %s:%s:%s' % (yyyy, MM, dd, HH, mm, ss)
        update_message = '(Hello, %s. Previously selected time was: %s.)' % (
            enter_name, selected_time)
        sqlitedb.updateCurrTime(currTime, selected_time)
        # Here, we assign `update_message' to `message', which means we'll refer to it in our template as `message'
        return render_template('select_time.html', message=update_message)


def intersection(lst1, lst2):
    lst3 = [value for value in lst1 if value in lst2]
    return lst3


class search:

    # Another GET request, this time to the URL '/search'
    def GET(self):
        return render_template('search.html')

    def POST(self):
        post_params = web.input()
        itemID = post_params['itemID']
        userID = post_params['userID']
        minPrice = post_params['minPrice']
        maxPrice = post_params['maxPrice']
        status = post_params['status']
        category = post_params['category']
        description = post_params['description']
        searchByItemID = sqlitedb.getByID(itemID)
        searchByUserID = sqlitedb.getByUserId(userID)
        searchByMinPrice = sqlitedb.getByMinPrice(minPrice)
        searchByMaxPrice = sqlitedb.getByMaxPrice(maxPrice)
        searchByStatus = sqlitedb.getByStatus(status)
        searchByCategory = sqlitedb.getByCategory(category)
        seachByDescription = sqlitedb.getByDescription(description)

        # set up default final result
        if (itemID != ''):
            final_result = searchByItemID
        elif (userID != ''):
            final_result = searchByUserID
        elif(maxPrice != ''):
            final_result = searchByMaxPrice
        elif (minPrice != ''):
            final_result = searchByMinPrice
        elif (category != ''):
            final_result = searchByCategory
        elif(description != ''):
            final_result = seachByDescription
        else:
            final_result =[]
        # compose mulitple filters
        if (userID != ''):
            final_result = intersection(final_result, searchByUserID)
        if (maxPrice != ''):
            final_result = intersection(final_result, searchByMaxPrice)
        if (minPrice != ''):
            final_result = intersection(final_result,searchByMinPrice)
        if (searchByStatus != False):
            final_result = intersection(final_result, searchByStatus)
        if (category != ''):
            final_result = intersection(final_result, searchByCategory)
        if (description != ''):
            final_result = intersection(final_result, seachByDescription)

        # selected_info = '%s-%s %s:%s' % (itemID, userID, minPrice, maxPrice)
        # update_message = '(selected information is: %s.)' % (selected_info)
        return render_template('search.html', search_result=final_result)

###########################################################################################
##########################DO NOT CHANGE ANYTHING BELOW THIS LINE!##########################
###########################################################################################


if __name__ == '__main__':
    web.internalerror = web.debugerror
    app = web.application(urls, globals())
    app.add_processor(web.loadhook(sqlitedb.enforceForeignKey))
    app.run()