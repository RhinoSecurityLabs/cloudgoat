# This is a test file used to determine if the test suite is working.
# A 'test' test if you will.

# Run test with: 
#   pytest -v test_test.py
#
# An example of the excepted output: 
#   ============================================================================================================== test session starts ===============================================================================================================
#   platform win32 -- Python 3.10.7, pytest-7.2.0, pluggy-1.0.0 -- C:\Users\John\AppData\Local\Programs\Python\Python310\python.exe
#   cachedir: .pytest_cache
#   rootdir: C:\Users\Users\cloudgoat\core\python\tests
#   collected 1 item
#   
#   test_test.py::test_test PASSED                                                                                                                                                                                                              [100%] 
#   
#   =============================================================================================================== 1 p

# Import the python test suite, pytest.
import pytest

# This test should always pass.
def test_test():
    assert True == True