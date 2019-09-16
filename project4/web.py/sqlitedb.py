import web

db = web.database(dbn='sqlite',
                  db='AuctionBase'  # TODO: add your SQLite database filename
                  )

######################BEGIN HELPER METHODS######################

# Enforce foreign key constraints
# WARNING: DO NOT REMOVE THIS!


def enforceForeignKey():
    db.query('PRAGMA foreign_keys = ON')

# initiates a transaction on the database


def transaction():
    return db.transaction()
# check out http://webpy.org/cookbook/transactions for examples

# returns the current time from your database


def getTime():
    query_string = 'select Time from CurrentTime'

    try:
        results = query(query_string)
    except Exception as e:
        print str(e)
        return None
    return results[0]['Time']


def updateCurrTime(oldTime, inputTime):
    sql = "UPDATE CurrentTime SET Time = '" + \
        inputTime + "' WHERE Time = '" + oldTime + "'"

    t = db.transaction()
    try:
        db.query(sql)
    except Exception as e:
        t.rollback()
        print str(e)
    else:
        t.commit()


# wrapper method around web.py's db.query method
# check out http://webpy.org/cookbook/query for more info


def query(query_string, vars={}):
    return list(db.query(query_string, vars))

#####################END HELPER METHODS#####################

# returns a single item specified by the Item's ID in the database
# Note: if the `result' list is empty (i.e. there are no items for a
# a given ID), this will throw an Exception!


def getItemById(item_id):
    try:
        query_string = 'select * from Items where itemID = $itemID'
        results = query(query_string, {'itemID': item_id})
        return results[0]
    except Exception as e:
        print(str(e))
        return None

def getBidById(item_id):
    try:
        query_string = 'select * from Bids where itemID = $itemID'
        results = query(query_string, {'itemID': item_id})
        return results
    except Exception as e:
        print(str(e))
        return None

def getCategoriesById(item_id):
    try:
        query_string = 'select * from Categories where itemID = $itemID'
        results = query(query_string, {'itemID': item_id})
        return results
    except Exception as e:
        print(str(e))
        return None

def status(item_id):
    currtime = getTime()
    endTime = query("select ends from Items where itemId = $itemID" ,{'itemID': item_id})[0]['Ends']
    buyPrice =query("select Buy_Price from Items where itemId = $itemID", {'itemID': item_id})[0]["Buy_Price"]
    currentPrice = query("select currently from Items where itemId = $itemID", {'itemID': item_id})[0]["Currently"]
    startTime = query('select started from Items where itemId = $itemID', {'itemID': item_id})[0]["Started"]
    if (currtime > endTime or (buyPrice != None and currentPrice >= buyPrice) ):
        return "closed"
    if (currtime < startTime):
        print "The auction for this item hasn't started yet"
        return "not started"
    return "open"

def add_bid(item_id, user_id, price):
    price = float(price)
    currtime = getTime()
    t = db.transaction()
    try:
        if (status(item_id) == "not started"):
            print "aaa"
            return False
        if (status(item_id) == "closed"):
            print status(item_id)
            return False
    
        # Check if the item_id violates the foreign key constraint
        item = getItemById(item_id)['Name']
        if item == None:
            print("Invalid itemID! No such item exists")
            return False
        else:
            print("Item: ", item)

        # Check if the user_id violates the foreign key constraint
        user = getUser(user_id)
        if user == None:
            print("Invalid userID! No such user exists")
            return False
        else:
            print("User Name: ", user)

        # Check if the user input price is higher than current price
        currentPrice = float(getCurrentPrice(item_id))
        first_bid = float(getItemById(item_id)["First_Bid"])
        if  price <= first_bid:
            print("Invalid input on Amount! must be higher than first bid! \n")
            print("Current amount: ", currentPrice)
            return False

        if currentPrice != None and price <= currentPrice:
            print("Invalid input on Amount! must be higher than current amount! \n")
            print("Current amount: ", currentPrice)
            return False

        print("Your bid amount: ", price)
        db.insert("Bids", ItemID=item_id, UserID=user_id, Amount=price, Time=currtime)

    except Exception as e:
        t.rollback()
        print str(e)
        return False
    else:
        t.commit()
        return True


def getCurrentPrice(item_id):
    try:
        query_string = 'select Currently from Items where itemID = $itemID'
        result = query(query_string, {'itemID': item_id})
        return result[0]["Currently"]
    except Exception as e:
        print(str(e))
        return None


def getUser(user_id):
    try:
        query_string = 'select * from Users where UserID = $userID'
        result = query(query_string, {'userID': user_id})
        return result[0]['UserID']
    except Exception as e:
        print(str(e))
        return None


##############################################################


# returns a single item specified by the Item's ID in the database
# Note: if the `result' list is empty (i.e. there are no items for a
# a given ID), this will throw an Exception!
def getByID(item_id):
    if (item_id == ''):
        return None
    query_string = "select Name, ItemID, currently from Items where ItemID = " + item_id
    t = db.transaction()
    try:
        results = query(query_string, {'ItemID': item_id})
    except Exception as e:
        t.rollback()
        print str(e)
    else:
        t.commit()
    return results


def getByUserId(user_id):
    if (user_id == ''):
        return None
    results = []
    query_string = "select Name, ItemID, currently from Items where Seller_UserID = \'" + user_id + "\'"
    t = db.transaction()
    try:
        results = query(query_string, {'UserID': user_id})
    except Exception as e:
        t.rollback()
        print str(e)
    else:
        t.commit()
    return results


def getByMinPrice(min_price):
    if (min_price == ''):
        return None
    query_string = "select Name, ItemID, currently from Items where currently >= " + min_price
    t = db.transaction()
    try:
        results = query(query_string, {'minPrice': min_price})
    except Exception as e:
        t.rollback()
        print str(e)
    else:
        t.commit()

    return results


def getByMaxPrice(max_price):
    if (max_price == ''):
        return None
    query_string = "select Name, ItemID, currently from Items where currently <= " + max_price
    t = db.transaction()
    try:
        results = query(query_string)
    except Exception as e:
        t.rollback()
        print str(e)
    else:
        t.commit()

    return results


def getByStatus(status):
    if status == "open":
        query_string = "select Name, ItemID, currently from currenttime, items where (currenttime.time >= items.started and currenttime.time <= items.ends)"
    elif status == "close":
        query_string = "select Name, ItemID, currently from items, currenttime where (currenttime.time > items.ends or items.currently >= items.buy_price)"
    elif status == "notStarted":
        query_string = "select Name, ItemID, currently from items, currenttime where currenttime.time < items.started"
    else:
        return False

    t = db.transaction()
    try:
        results = query(query_string, {'Status': status})
    except Exception as e:
        t.rollback()
        print str(e)
    else:
        t.commit()
    return results


def getByCategory(category):
    if (category == ''):
        return None
    query_string ="select Name, Items.ItemID, currently from Items, Categories where Categories.ItemID = Items.ItemID AND category LIKE \'%" + category + "%\'"
    t = db.transaction()
    try:
        results = query(query_string, {'category' :category})
    except Exception as e:
        t.rollback()
        print str(e)
    else:
        t.commit()

    return results

def getByDescription(description):
    if (description == ''):
        return None
    # TODO: rewrite this method to catch the Exception in case `result' is empty
    query_string = "select Name, ItemID, currently from Items where description LIKE \'%" + description + "%\'"
    t = db.transaction()
    try:
        results = query(query_string)
    except Exception as e:
        t.rollback()
        print str(e)
    else:
        t.commit()

    return results