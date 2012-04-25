#! ../share/python_lib/stable/bin/python 
import unittest
import sys
sys.path.append("../share/python_lib/testcases/")
from instancetest import InstanceBasics
if __name__ == "__main__":
    result = unittest.TextTestRunner(verbosity=2).run(InstanceBasics("MetaData"))
    if result.wasSuccessful():
       exit(0)
    else:
       exit(1)
