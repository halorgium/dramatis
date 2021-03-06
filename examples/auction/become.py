#!/usr/bin/env python

# cf. Scala by Example, Chapter 3

# Note: requires dramatis > 0.1.1

import time
import random
import inspect
import sys
import os.path

sys.path[0:0] = [ os.path.join( os.path.dirname( inspect.getabsfile( inspect.currentframe() ) ), '..', '..', 'lib' ) ]

import dramatis

class Auction(object):

    def __new__( cls, *args ):
        return Auction.Open( *args )

    class Open( dramatis.Actor ):

        def __init__(self, seller, min_bid, closing):
            self._seller = seller
            self._min_bid = min_bid
            self._closing = closing
            
            self._bid_increment = 10
            self._max_bid = self._min_bid - self._bid_increment
            self._max_bidder = None

            self.actor.refuse( "winner" )
            
            dramatis.release( self.actor.name ).close()

        def close(self):
            self.actor.actor_yield( self._closing - time.time() )

            if self._max_bid > self._min_bid:
                dramatis.release( self._seller ).winner( self._max_bidder )
                dramatis.release( self._max_bidder ).winner( self._seller )
                self.actor.become( Auction.Over( self._max_bidder,
                                                  self._max_bid ) )
            else:
                dramatis.release( self._seller ).failed( self._max_bid )
                self.actor.become( Auction.Over( None, self._max_bid ) )
                
        def inquire(self):
            return [ self._max_bid, self._closing ]

        def offer(self, bid, bidder):
            if bid >= self._max_bid + self._bid_increment:
                if self._max_bid >= self._min_bid:
                    dramatis.release( self._max_bidder ).beaten_offer( bid )
                self._max_bid = bid
                self._max_bidder = bidder
                return [ "best_offer", None ]
            else:
                return [ "beaten_offer", self._max_bid ]

        @property
        def winner(self): pass # this one is subtle ...

    class Over( dramatis.Actor.Behavior ):
        @property
        def winner(self): return self._winner
        @property
        def max_bid(self): return self._max_bid

        def __init__(self, winner, max_bid):
            self._winner = winner
            self._max_bid = max_bid

        def dramatis_bound(self):
            self.actor.accept( "winner" )

        def inquire(self, *args):
            [ self._max_bid, 0 ]

        def offer(self, *args):
            return [ "auction_over", self._max_bid ]

class Seller ( dramatis.Actor ):
    def winner(self, winner): pass
    def failed(self, highest_bid): pass

class Client ( dramatis.Actor ):
    @property
    def name(self): return self._name

    def __init__(self, name, increment, top, auction):
        self._name = name
        self._increment = increment
        self._top = top
        self._auction = auction
        self._current = 0
        self.log( "started" )
        self._max = auction.inquire()[0]
        self.log( "status " + str(self._max) )
        dramatis.release( self.actor.name ).bid()

    def bid(self):
        if self._max >= self._top:
            self.log("too high for me")
        elif ( self._current <= self._max ):
            self._current = self._max + self._increment
            time.sleep( ( 1 + random.randint( 0, 1000 ) )/1000.0 )
            answer, max_bid = self._auction.offer( self._current,
                                                    self.actor.name )
            if answer == "best_offer":
                self.log("best offer: " + str(self._current))
            elif answer == "beaten_offer": self.beaten_offer( max_bid )
            elif answer == "auction_over":
                self.log("auction over, oh well")

    def beaten_offer(self, max_bid):
        self.log("beaten offer: " + str(max_bid))
        self._max = max_bid
        dramatis.release( self.actor.name ).bid()

    def winner(self, seller):
        self.log("I won!")

    def log(self,string):
        print ( "client %s: %s" % ( self._name, string ) )

# somebody gives up

seller = Seller()
auction = Auction( seller, 100, time.time() + 4 )
Client( "1a", 20, 200, auction )
Client( "1a", 10, 300, auction )

print "Notice: client %s won the first auction with a bid of %s" % \
       ( auction.winner.name, auction.max_bid )

# cut off while people still have money

seller = Seller()
auction = Auction( seller, 100, time.time() + 1.5 )
Client( "1b", 20, 200, auction )
Client( "2b", 10, 300, auction )

print "Notice: client %s won the first auction with a bid of %s" % \
       ( auction.winner.name, auction.max_bid )

# too expensive

seller = Seller()
auction = Auction( seller, 400, time.time() + 1.5 )
Client( "1c", 20, 200, auction )
Client( "2c", 10, 300, auction )

if auction.winner != None:
    raise RuntimeError

print "Notice: the third auction failed; the maximum recieved bid was %s" % \
       auction.max_bid

# lots of clients ...

seller = Seller()
auction = Auction( seller, 400, time.time() + 20 )
for i in xrange(20):
    Client( str(i),
            10 + 10*random.randint(0,2), 
            random.randint(0,20000-1), auction )

print "Notice: client %s won the fourth auction with a bid of %s" % \
       ( auction.winner.name, auction.max_bid )
