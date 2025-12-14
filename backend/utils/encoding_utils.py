"""Utility functions for handling encoding issues on Windows"""
import sys
import io
import traceback

def safe_str(obj):
    """Safely convert object to string, handling encoding errors"""
    try:
        return str(obj)
    except UnicodeEncodeError:
        try:
            return obj.encode('utf-8', errors='replace').decode('utf-8')
        except:
            return repr(obj).encode('ascii', errors='replace').decode('ascii')

def safe_print(message):
    """Safely print messages, handling encoding errors"""
    try:
        print(message)
    except UnicodeEncodeError:
        # Fallback: encode to ASCII with error handling
        try:
            safe_message = message.encode('utf-8', errors='replace').decode('utf-8')
            print(safe_message)
        except:
            safe_message = message.encode('ascii', errors='replace').decode('ascii')
            print(safe_message)

def safe_print_exc():
    """Safely print exception traceback, handling encoding errors"""
    try:
        traceback.print_exc()
    except UnicodeEncodeError:
        # Get traceback as string and print safely
        try:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            tb_str = ''.join(traceback.format_exception(exc_type, exc_value, exc_traceback))
            safe_print(tb_str)
        except:
            safe_print("Error occurred (unable to print traceback due to encoding issue)")

