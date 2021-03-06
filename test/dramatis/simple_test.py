#!/bin/env python

import inspect
import sys
import os.path
import threading

from logging import warning

sys.path[0:0] = [ os.path.join( os.path.dirname( inspect.getabsfile( inspect.currentframe() ) ), '..' ) ]
sys.path[0:0] = [ os.path.join( os.path.dirname( inspect.getabsfile( inspect.currentframe() ) ), '..', '..', 'lib' ) ]

from inspect import currentframe
from inspect import getframeinfo

from traceback import format_list
from traceback import extract_tb
from traceback import print_exc

from sys import exc_info

import dramatis
import dramatis.error
from dramatis import interface
Actor = dramatis.Actor

from test_helper import DramatisTestHelper

class Simple_Test ( DramatisTestHelper ):

    def teardown(self):
        self.runtime_check()

    def test_creatable_wo_req(self):
        class f ( dramatis.Actor ): pass
        name = f()
        assert type(name) is not f
    
